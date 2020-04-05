---
title: 慢谈 Redis 实现分布式锁 以及 Redisson 源码解析
tags:
  - Redis
  - Redisson
  - RedissonLock
  - RedissonRedLock
date: 2019-08-24 11:51:21
---

## [](#产生背景 "# 产生背景")# 产生背景
> Distributed locks are a very useful primitive in many environments where different processes must operate with shared resources in a mutually exclusive way.

在某些场景中，多个进程必须以互斥的方式独占共享资源，这时用分布式锁是最直接有效的。

随着互联网技术快速发展，数据规模增大，分布式系统越来越普及，一个应用往往会部署在多台机器上（多节点），在有些场景中，为了保证数据不重复，要求在同一时刻，同一任务只在一个节点上运行，即保证某一方法同一时刻只能被一个线程执行。在单机环境中，应用是在同一进程下的，只需要保证单进程多线程环境中的线程安全性，通过 JAVA 提供的 volatile、ReentrantLock、synchronized 以及 concurrent 并发包下一些线程安全的类等就可以做到。而在多机部署环境中，不同机器不同进程，就需要在多进程下保证线程的安全性了。因此，分布式锁应运而生。
<!--more-->

## [](#实现分布式锁的三种选择 "# 实现分布式锁的三种选择")# 实现分布式锁的三种选择

*   基于数据库实现分布式锁*   基于zookeeper实现分布式锁
*   基于Redis缓存实现分布式锁

以上三种方式都可以实现分布式锁，其中，从健壮性考虑， 用 zookeeper 会比用 Redis 实现更好，但从性能角度考虑，基于 Redis 实现性能会更好，如何选择，还是取决于业务需求。

## [](#基于-Redis-实现分布式锁的三种方案 "# 基于 Redis 实现分布式锁的三种方案")# 基于 Redis 实现分布式锁的三种方案

*   用 Redis 实现分布式锁的正确姿势（实现一）
*   用 Redisson 实现分布式可重入锁（RedissonLock）（实现二）
*   用 Redisson 实现分布式锁(红锁 RedissonRedLock)（实现三）

**本文主要探讨基于 Redis 实现分布式锁的方案，主要分析并对比了以上三种方案，并大致分析了 Redisson 的 RedissonLock 、 RedissonRedLock 源码。**

## [](#分布式锁需满足四个条件 "# 分布式锁需满足四个条件")# 分布式锁需满足四个条件

首先，为了确保分布式锁可用，我们至少要确保锁的实现同时满足以下四个条件：

1.  互斥性。在任意时刻，只有一个客户端能持有锁。
2.  不会发生死锁。即使有一个客户端在持有锁的期间崩溃而没有主动解锁，也能保证后续其他客户端能加锁。
3.  解铃还须系铃人。加锁和解锁必须是同一个客户端，客户端自己不能把别人加的锁给解了，即不能误解锁。
4.  具有容错性。只要大多数Redis节点正常运行，客户端就能够获取和释放锁。

## [](#用-Redis-实现分布式锁的正确姿势（实现一） "# 用 Redis 实现分布式锁的正确姿势（实现一）")# 用 Redis 实现分布式锁的正确姿势（实现一）

### [](#主要思路 "主要思路")主要思路

通过 set key value px milliseconds nx 命令实现加锁， 通过Lua脚本实现解锁。核心实现命令如下：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
</pre></td><td class="code"><pre><span class="line"><span class="comment">//获取锁（unique_value可以是UUID等）</span></span>
<span class="line">SET resource_name unique_value NX PX  <span class="number">30000</span></span>
<span class="line"></span>
<span class="line"><span class="comment">//释放锁（lua脚本中，一定要比较value，防止误解锁）</span></span>
<span class="line"><span class="keyword">if</span> redis.call(<span class="string">"get"</span>,KEYS[<span class="number">1</span>]) == ARGV[<span class="number">1</span>] then</span>
<span class="line">    <span class="keyword">return</span> redis.call(<span class="string">"del"</span>,KEYS[<span class="number">1</span>])</span>
<span class="line"><span class="keyword">else</span></span>
<span class="line">    <span class="keyword">return</span> <span class="number">0</span></span>
<span class="line">end</span>
</pre></td></tr></table></figure>

这种实现方式主要有以下几个要点：

*   set 命令要用 set key value px milliseconds nx，替代 setnx + expire 需要分两次执行命令的方式，保证了原子性，

*   value 要具有唯一性，可以使用UUID.randomUUID().toString()方法生成，用来标识这把锁是属于哪个请求加的，在解锁的时候就可以有依据；

*   释放锁时要验证 value 值，防止误解锁；

*   通过 Lua 脚本来避免 Check And Set 模型的并发问题，因为在释放锁的时候因为涉及到多个Redis操作 （利用了eval命令执行Lua脚本的原子性）；

### [](#完整代码实现如下： "完整代码实现如下：")完整代码实现如下：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
<span class="line">33</span>
<span class="line">34</span>
<span class="line">35</span>
<span class="line">36</span>
<span class="line">37</span>
<span class="line">38</span>
<span class="line">39</span>
<span class="line">40</span>
<span class="line">41</span>
<span class="line">42</span>
<span class="line">43</span>
<span class="line">44</span>
<span class="line">45</span>
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">RedisTool</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">private</span> <span class="keyword">static</span> <span class="keyword">final</span> String LOCK_SUCCESS = <span class="string">"OK"</span>;</span>
<span class="line">    <span class="keyword">private</span> <span class="keyword">static</span> <span class="keyword">final</span> String SET_IF_NOT_EXIST = <span class="string">"NX"</span>;</span>
<span class="line">    <span class="keyword">private</span> <span class="keyword">static</span> <span class="keyword">final</span> String SET_WITH_EXPIRE_TIME = <span class="string">"PX"</span>;</span>
<span class="line">    <span class="keyword">private</span> <span class="keyword">static</span> <span class="keyword">final</span> Long RELEASE_SUCCESS = <span class="number">1L</span>;</span>
<span class="line"></span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 获取分布式锁(加锁代码)</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> jedis Redis客户端</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> lockKey 锁</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> requestId 请求标识</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> expireTime 超期时间</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@return</span> 是否获取成功</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">boolean</span> <span class="title">getDistributedLock</span><span class="params">(Jedis jedis, String lockKey, String requestId, <span class="keyword">int</span> expireTime)</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">        String result = jedis.set(lockKey, requestId, SET_IF_NOT_EXIST, SET_WITH_EXPIRE_TIME, expireTime);</span>
<span class="line"></span>
<span class="line">        <span class="keyword">if</span> (LOCK_SUCCESS.equals(result)) &#123;</span>
<span class="line">            <span class="keyword">return</span> <span class="keyword">true</span>;</span>
<span class="line">        &#125;</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 释放分布式锁(解锁代码)</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> jedis Redis客户端</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> lockKey 锁</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> requestId 请求标识</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@return</span> 是否释放成功</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">boolean</span> <span class="title">releaseDistributedLock</span><span class="params">(Jedis jedis, String lockKey, String requestId)</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">        String script = <span class="string">"if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else               return 0 end"</span>;</span>
<span class="line">        </span>
<span class="line">        Object result = jedis.eval(script, Collections.singletonList(lockKey), C                                                   ollections.singletonList(requestId));</span>
<span class="line"></span>
<span class="line">        <span class="keyword">if</span> (RELEASE_SUCCESS.equals(result)) &#123;</span>
<span class="line">            <span class="keyword">return</span> <span class="keyword">true</span>;</span>
<span class="line">        &#125;</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line"></span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

### [](#加锁代码分析 "加锁代码分析")加锁代码分析

首先，set()加入了NX参数，可以保证如果已有key存在，则函数不会调用成功，也就是只有一个客户端能持有锁，满足互斥性。其次，由于我们对锁设置了过期时间，即使锁的持有者后续发生崩溃而没有解锁，锁也会因为到了过期时间而自动解锁（即key被删除），不会发生死锁。最后，因为我们将value赋值为requestId，用来标识这把锁是属于哪个请求加的，那么在客户端在解锁的时候就可以进行校验是否是同一个客户端。

### [](#解锁代码分析 "解锁代码分析")解锁代码分析

将Lua代码传到jedis.eval()方法里，并使参数KEYS[1]赋值为lockKey，ARGV[1]赋值为requestId。在执行的时候，首先会获取锁对应的value值，检查是否与requestId相等，如果相等则解锁（删除key）。

### [](#这种方式仍存在单点风险 "这种方式仍存在单点风险")这种方式仍存在单点风险

**以上实现在 Redis 正常运行情况下是没问题的，但如果存储锁对应key的那个节点挂了的话，就可能存在丢失锁的风险，导致出现多个客户端持有锁的情况，这样就不能实现资源的独享了。**

1.  客户端A从master获取到锁
2.  在master将锁同步到slave之前，master宕掉了（Redis的主从同步通常是异步的）。
3.  主从切换，slave节点被晋级为master节点
4.  客户端B取得了同一个资源被客户端A已经获取到的另外一个锁。导致存在同一时刻存不止一个线程获取到锁的情况。

**所以在这种实现之下，不论Redis的部署架构是单机模式、主从模式、哨兵模式还是集群模式，都存在这种风险。因为Redis的主从同步是异步的。 运行的是，Redis 之父 antirez 提出了 redlock算法 可以解决这个问题。**

## [](#Redisson-实现分布式可重入锁及源码分析-（RedissonLock）（实现二） "# Redisson 实现分布式可重入锁及源码分析 （RedissonLock）（实现二）")# Redisson 实现分布式可重入锁及源码分析 （RedissonLock）（实现二）

### [](#什么是-Redisson "什么是 Redisson")什么是 Redisson

Redisson是一个在Redis的基础上实现的Java驻内存数据网格（In-Memory Data Grid）。它不仅提供了一系列的分布式的Java常用对象，还实现了可重入锁（Reentrant Lock）、公平锁（Fair Lock、联锁（MultiLock）、 红锁（RedLock）、 读写锁（ReadWriteLock）等，还提供了许多分布式服务。Redisson提供了使用Redis的最简单和最便捷的方法。Redisson的宗旨是促进使用者对Redis的关注分离（Separation of Concern），从而让使用者能够将精力更集中地放在处理业务逻辑上。

### [](#Redisson-分布式重入锁用法 "Redisson 分布式重入锁用法")Redisson 分布式重入锁用法

Redisson 支持单点模式、主从模式、哨兵模式、集群模式，这里以单点模式为例：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
</pre></td><td class="code"><pre><span class="line"><span class="comment">// 1.构造redisson实现分布式锁必要的Config</span></span>
<span class="line">Config config = <span class="keyword">new</span> Config();</span>
<span class="line">config.useSingleServer().setAddress(<span class="string">"redis://127.0.0.1:5379"</span>).setPassword(<span class="string">"123456"</span>).setDatabase(<span class="number">0</span>);</span>
<span class="line"><span class="comment">// 2.构造RedissonClient</span></span>
<span class="line">RedissonClient redissonClient = Redisson.create(config);</span>
<span class="line"><span class="comment">// 3.获取锁对象实例（无法保证是按线程的顺序获取到）</span></span>
<span class="line">RLock rLock = redissonClient.getLock(lockKey);</span>
<span class="line"><span class="keyword">try</span> &#123;</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 4.尝试获取锁</span></span>
<span class="line"><span class="comment">     * waitTimeout 尝试获取锁的最大等待时间，超过这个值，则认为获取锁失败</span></span>
<span class="line"><span class="comment">     * leaseTime   锁的持有时间,超过这个时间锁会自动失效（值应设置为大于业务处理的时间，确保在锁有效期内业务能处理完）</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">boolean</span> res = rLock.tryLock((<span class="keyword">long</span>)waitTimeout, (<span class="keyword">long</span>)leaseTime, TimeUnit.SECONDS);</span>
<span class="line">    <span class="keyword">if</span> (res) &#123;</span>
<span class="line">        <span class="comment">//成功获得锁，在这里处理业务</span></span>
<span class="line">    &#125;</span>
<span class="line">&#125; <span class="keyword">catch</span> (Exception e) &#123;</span>
<span class="line">    <span class="keyword">throw</span> <span class="keyword">new</span> RuntimeException(<span class="string">"aquire lock fail"</span>);</span>
<span class="line">&#125;<span class="keyword">finally</span>&#123;</span>
<span class="line">    <span class="comment">//无论如何, 最后都要解锁</span></span>
<span class="line">    rLock.unlock();</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

### [](#加锁源码分析 "加锁源码分析")加锁源码分析

**1.通过 getLock 方法获取对象**

**org.redisson.Redisson#getLock()**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Override</span></span>
<span class="line"><span class="function"><span class="keyword">public</span> RLock <span class="title">getLock</span><span class="params">(String name)</span> </span>&#123;</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     *  构造并返回一个 RedissonLock 对象 </span></span>
<span class="line"><span class="comment">     * commandExecutor: 与 Redis 节点通信并发送指令的真正实现。需要说明一下，CommandExecutor 实现是通过 eval 命令来执行 Lua 脚本</span></span>
<span class="line"><span class="comment">     * name: 锁的全局名称</span></span>
<span class="line"><span class="comment">     * id: Redisson 客户端唯一标识，实际上就是一个 UUID.randomUUID()</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">return</span> <span class="keyword">new</span> RedissonLock(commandExecutor, name, id);</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

**2.通过tryLock方法尝试获取锁**

tryLock方法里的调用关系大致如下：

![](/images/2019041501.png)

**org.redisson.RedissonLock#tryLock**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
<span class="line">33</span>
<span class="line">34</span>
<span class="line">35</span>
<span class="line">36</span>
<span class="line">37</span>
<span class="line">38</span>
<span class="line">39</span>
<span class="line">40</span>
<span class="line">41</span>
<span class="line">42</span>
<span class="line">43</span>
<span class="line">44</span>
<span class="line">45</span>
<span class="line">46</span>
<span class="line">47</span>
<span class="line">48</span>
<span class="line">49</span>
<span class="line">50</span>
<span class="line">51</span>
<span class="line">52</span>
<span class="line">53</span>
<span class="line">54</span>
<span class="line">55</span>
<span class="line">56</span>
<span class="line">57</span>
<span class="line">58</span>
<span class="line">59</span>
<span class="line">60</span>
<span class="line">61</span>
<span class="line">62</span>
<span class="line">63</span>
<span class="line">64</span>
<span class="line">65</span>
<span class="line">66</span>
<span class="line">67</span>
<span class="line">68</span>
<span class="line">69</span>
<span class="line">70</span>
<span class="line">71</span>
<span class="line">72</span>
<span class="line">73</span>
<span class="line">74</span>
<span class="line">75</span>
<span class="line">76</span>
<span class="line">77</span>
<span class="line">78</span>
<span class="line">79</span>
<span class="line">80</span>
<span class="line">81</span>
<span class="line">82</span>
<span class="line">83</span>
<span class="line">84</span>
<span class="line">85</span>
<span class="line">86</span>
<span class="line">87</span>
<span class="line">88</span>
<span class="line">89</span>
<span class="line">90</span>
<span class="line">91</span>
<span class="line">92</span>
<span class="line">93</span>
<span class="line">94</span>
<span class="line">95</span>
<span class="line">96</span>
<span class="line">97</span>
<span class="line">98</span>
<span class="line">99</span>
<span class="line">100</span>
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Override</span></span>
<span class="line"><span class="function"><span class="keyword">public</span> <span class="keyword">boolean</span> <span class="title">tryLock</span><span class="params">(<span class="keyword">long</span> waitTime, <span class="keyword">long</span> leaseTime, TimeUnit unit)</span> <span class="keyword">throws</span> InterruptedException </span>&#123;</span>
<span class="line">    <span class="comment">//取得最大等待时间</span></span>
<span class="line">    <span class="keyword">long</span> time = unit.toMillis(waitTime);</span>
<span class="line">    <span class="comment">//记录下当前时间</span></span>
<span class="line">    <span class="keyword">long</span> current = System.currentTimeMillis();</span>
<span class="line">    <span class="comment">//取得当前线程id（判断是否可重入锁的关键）</span></span>
<span class="line">    <span class="keyword">long</span> threadId = Thread.currentThread().getId();</span>
<span class="line">    <span class="comment">//1.尝试申请锁，返回还剩余的锁过期时间</span></span>
<span class="line">    Long ttl = tryAcquire(leaseTime, unit, threadId);</span>
<span class="line">    <span class="comment">//2.如果为空，表示申请锁成功</span></span>
<span class="line">    <span class="keyword">if</span> (ttl == <span class="keyword">null</span>) &#123;</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">true</span>;</span>
<span class="line">    &#125;</span>
<span class="line">    <span class="comment">//3.申请锁的耗时如果大于等于最大等待时间，则申请锁失败</span></span>
<span class="line">    time -= System.currentTimeMillis() - current;</span>
<span class="line">    <span class="keyword">if</span> (time &lt;= <span class="number">0</span>) &#123;</span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         * 通过 promise.trySuccess 设置异步执行的结果为null</span></span>
<span class="line"><span class="comment">         * Promise从Uncompleted--&gt;Completed ,通知 Future 异步执行已完成</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        acquireFailed(threadId);</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">    &#125;</span>
<span class="line">    </span>
<span class="line">    current = System.currentTimeMillis();</span>
<span class="line"></span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 4.订阅锁释放事件，并通过await方法阻塞等待锁释放，有效的解决了无效的锁申请浪费资源的问题：</span></span>
<span class="line"><span class="comment">     * 基于信息量，当锁被其它资源占用时，当前线程通过 Redis 的 channel 订阅锁的释放事件，一旦锁释放会发消息通知待等待的线程进行竞争</span></span>
<span class="line"><span class="comment">     * 当 this.await返回false，说明等待时间已经超出获取锁最大等待时间，取消订阅并返回获取锁失败</span></span>
<span class="line"><span class="comment">     * 当 this.await返回true，进入循环尝试获取锁</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    RFuture&lt;RedissonLockEntry&gt; subscribeFuture = subscribe(threadId);</span>
<span class="line">    <span class="comment">//await 方法内部是用CountDownLatch来实现阻塞，获取subscribe异步执行的结果（应用了Netty 的 Future）</span></span>
<span class="line">    <span class="keyword">if</span> (!await(subscribeFuture, time, TimeUnit.MILLISECONDS)) &#123;</span>
<span class="line">        <span class="keyword">if</span> (!subscribeFuture.cancel(<span class="keyword">false</span>)) &#123;</span>
<span class="line">            subscribeFuture.onComplete((res, e) -&gt; &#123;</span>
<span class="line">                <span class="keyword">if</span> (e == <span class="keyword">null</span>) &#123;</span>
<span class="line">                    unsubscribe(subscribeFuture, threadId);</span>
<span class="line">                &#125;</span>
<span class="line">            &#125;);</span>
<span class="line">        &#125;</span>
<span class="line">        acquireFailed(threadId);</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">try</span> &#123;</span>
<span class="line">        <span class="comment">//计算获取锁的总耗时，如果大于等于最大等待时间，则获取锁失败</span></span>
<span class="line">        time -= System.currentTimeMillis() - current;</span>
<span class="line">        <span class="keyword">if</span> (time &lt;= <span class="number">0</span>) &#123;</span>
<span class="line">            acquireFailed(threadId);</span>
<span class="line">            <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">        &#125;</span>
<span class="line"></span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         * 5.收到锁释放的信号后，在最大等待时间之内，循环一次接着一次的尝试获取锁</span></span>
<span class="line"><span class="comment">         * 获取锁成功，则立马返回true，</span></span>
<span class="line"><span class="comment">         * 若在最大等待时间之内还没获取到锁，则认为获取锁失败，返回false结束循环</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        <span class="keyword">while</span> (<span class="keyword">true</span>) &#123;</span>
<span class="line">            <span class="keyword">long</span> currentTime = System.currentTimeMillis();</span>
<span class="line">            <span class="comment">// 再次尝试申请锁</span></span>
<span class="line">            ttl = tryAcquire(leaseTime, unit, threadId);</span>
<span class="line">            <span class="comment">// 成功获取锁则直接返回true结束循环</span></span>
<span class="line">            <span class="keyword">if</span> (ttl == <span class="keyword">null</span>) &#123;</span>
<span class="line">                <span class="keyword">return</span> <span class="keyword">true</span>;</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            <span class="comment">//超过最大等待时间则返回false结束循环，获取锁失败</span></span>
<span class="line">            time -= System.currentTimeMillis() - currentTime;</span>
<span class="line">            <span class="keyword">if</span> (time &lt;= <span class="number">0</span>) &#123;</span>
<span class="line">                acquireFailed(threadId);</span>
<span class="line">                <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            <span class="comment">/**</span></span>
<span class="line"><span class="comment">             * 6.阻塞等待锁（通过信号量(共享锁)阻塞,等待解锁消息）：</span></span>
<span class="line"><span class="comment">             */</span></span>
<span class="line">            currentTime = System.currentTimeMillis();</span>
<span class="line">            <span class="keyword">if</span> (ttl &gt;= <span class="number">0</span> &amp;&amp; ttl &lt; time) &#123;</span>
<span class="line">                <span class="comment">//如果剩余时间(ttl)小于wait time ,就在 ttl 时间内，从Entry的信号量获取一个许可(除非被中断或者一直没有可用的许可)。</span></span>
<span class="line">                getEntry(threadId).getLatch().tryAcquire(ttl, TimeUnit.MILLISECONDS);</span>
<span class="line">            &#125; <span class="keyword">else</span> &#123;</span>
<span class="line">                <span class="comment">//则就在wait time 时间范围内等待可以通过信号量</span></span>
<span class="line">                getEntry(threadId).getLatch().tryAcquire(time, TimeUnit.MILLISECONDS);</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            <span class="comment">//7.更新剩余的等待时间(最大等待时间-已经消耗的阻塞时间)</span></span>
<span class="line">            time -= System.currentTimeMillis() - currentTime;</span>
<span class="line">            <span class="keyword">if</span> (time &lt;= <span class="number">0</span>) &#123;</span>
<span class="line">                acquireFailed(threadId);</span>
<span class="line">                <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">            &#125;</span>
<span class="line">        &#125;</span>
<span class="line">    &#125; <span class="keyword">finally</span> &#123;</span>
<span class="line">        <span class="comment">//7.无论是否获得锁,都要取消订阅解锁消息</span></span>
<span class="line">        unsubscribe(subscribeFuture, threadId);</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

其中 tryAcquire 内部通过调用 tryLockInnerAsync 实现申请锁的逻辑。申请锁并返回锁有效期还剩余的时间，如果为空说明锁未被其它线程申请则直接获取并返回，如果获取到时间，则进入等待竞争逻辑。

**org.redisson.RedissonLock#tryLockInnerAsync**

**加锁流程图：**
![](/images/2019041502.png)

**实现源码：**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
</pre></td><td class="code"><pre><span class="line">&lt;T&gt; <span class="function">RFuture&lt;T&gt; <span class="title">tryLockInnerAsync</span><span class="params">(<span class="keyword">long</span> leaseTime, TimeUnit unit, <span class="keyword">long</span> threadId, RedisStrictCommand&lt;T&gt; command)</span> </span>&#123;</span>
<span class="line">    internalLockLeaseTime = unit.toMillis(leaseTime);</span>
<span class="line"></span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 通过 EVAL 命令执行 Lua 脚本获取锁，保证了原子性</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">return</span> commandExecutor.evalWriteAsync(getName(), LongCodec.INSTANCE, command,</span>
<span class="line">              <span class="comment">// 1.如果缓存中的key不存在，则执行 hset 命令(hset key UUID+threadId 1),然后通过 pexpire 命令设置锁的过期时间(即锁的租约时间)</span></span>
<span class="line">              <span class="comment">// 返回空值 nil ，表示获取锁成功</span></span>
<span class="line">              <span class="string">"if (redis.call('exists', KEYS[1]) == 0) then "</span> +</span>
<span class="line">                  <span class="string">"redis.call('hset', KEYS[1], ARGV[2], 1); "</span> +</span>
<span class="line">                  <span class="string">"redis.call('pexpire', KEYS[1], ARGV[1]); "</span> +</span>
<span class="line">                  <span class="string">"return nil; "</span> +</span>
<span class="line">              <span class="string">"end; "</span> +</span>
<span class="line">               <span class="comment">// 如果key已经存在，并且value也匹配，表示是当前线程持有的锁，则执行 hincrby 命令，重入次数加1，并且设置失效时间</span></span>
<span class="line">              <span class="string">"if (redis.call('hexists', KEYS[1], ARGV[2]) == 1) then "</span> +</span>
<span class="line">                  <span class="string">"redis.call('hincrby', KEYS[1], ARGV[2], 1); "</span> +</span>
<span class="line">                  <span class="string">"redis.call('pexpire', KEYS[1], ARGV[1]); "</span> +</span>
<span class="line">                  <span class="string">"return nil; "</span> +</span>
<span class="line">              <span class="string">"end; "</span> +</span>
<span class="line">               <span class="comment">//如果key已经存在，但是value不匹配，说明锁已经被其他线程持有，通过 pttl 命令获取锁的剩余存活时间并返回，至此获取锁失败</span></span>
<span class="line">              <span class="string">"return redis.call('pttl', KEYS[1]);"</span>,</span>
<span class="line">               <span class="comment">//这三个参数分别对应KEYS[1]，ARGV[1]和ARGV[2]</span></span>
<span class="line">               Collections.&lt;Object&gt;singletonList(getName()), internalLockLeaseTime, getLockName(threadId));</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

**参数说明：**

*   KEYS[1]就是Collections.singletonList(getName())，表示分布式锁的key；

*   ARGV[1]就是internalLockLeaseTime，即锁的租约时间（持有锁的有效时间），默认30s；

*   ARGV[2]就是getLockName(threadId)，是获取锁时set的唯一值 value，即UUID+threadId。

### [](#解锁源码分析 "解锁源码分析")解锁源码分析

unlock 内部通过 get(unlockAsync(Thread.currentThread().getId()))  调用 unlockInnerAsync 解锁。

**org.redisson.RedissonLock#unlock**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Override</span></span>
<span class="line"><span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">unlock</span><span class="params">()</span> </span>&#123;</span>
<span class="line">    <span class="keyword">try</span> &#123;</span>
<span class="line">        get(unlockAsync(Thread.currentThread().getId()));</span>
<span class="line">    &#125; <span class="keyword">catch</span> (RedisException e) &#123;</span>
<span class="line">        <span class="keyword">if</span> (e.getCause() <span class="keyword">instanceof</span> IllegalMonitorStateException) &#123;</span>
<span class="line">            <span class="keyword">throw</span> (IllegalMonitorStateException) e.getCause();</span>
<span class="line">        &#125; <span class="keyword">else</span> &#123;</span>
<span class="line">            <span class="keyword">throw</span> e;</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

get方法利用是 CountDownLatch 在异步调用结果返回前将当前线程阻塞，然后通过 Netty 的 FutureListener 在异步调用完成后解除阻塞，并返回调用结果。

**org.redisson.command.CommandAsyncService#get**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Override</span></span>
<span class="line"><span class="keyword">public</span> &lt;V&gt; <span class="function">V <span class="title">get</span><span class="params">(RFuture&lt;V&gt; future)</span> </span>&#123;</span>
<span class="line">    <span class="keyword">if</span> (!future.isDone()) &#123;   <span class="comment">//任务还没完成</span></span>
<span class="line">        <span class="comment">// 设置一个单线程的同步控制器</span></span>
<span class="line">        CountDownLatch l = <span class="keyword">new</span> CountDownLatch(<span class="number">1</span>);</span>
<span class="line">        future.onComplete((res, e) -&gt; &#123;</span>
<span class="line">            <span class="comment">//操作完成时，唤醒在await()方法中等待的线程</span></span>
<span class="line">            l.countDown();</span>
<span class="line">        &#125;);</span>
<span class="line"></span>
<span class="line">        <span class="keyword">boolean</span> interrupted = <span class="keyword">false</span>;</span>
<span class="line">        <span class="keyword">while</span> (!future.isDone()) &#123;</span>
<span class="line">            <span class="keyword">try</span> &#123;</span>
<span class="line">                <span class="comment">//阻塞等待</span></span>
<span class="line">                l.await();</span>
<span class="line">            &#125; <span class="keyword">catch</span> (InterruptedException e) &#123;</span>
<span class="line">                interrupted = <span class="keyword">true</span>;</span>
<span class="line">                <span class="keyword">break</span>;</span>
<span class="line">            &#125;</span>
<span class="line">        &#125;</span>
<span class="line"></span>
<span class="line">        <span class="keyword">if</span> (interrupted) &#123;</span>
<span class="line">            Thread.currentThread().interrupt();</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line">    </span>
<span class="line">    <span class="keyword">if</span> (future.isSuccess()) &#123;</span>
<span class="line">        <span class="keyword">return</span> future.getNow();</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">throw</span> convertException(future);</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

**org.redisson.RedissonLock#unlockInnerAsync**

**解锁流程图：**
![](/images/2019041503.png)

**实现源码：**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
</pre></td><td class="code"><pre><span class="line"><span class="function"><span class="keyword">protected</span> RFuture&lt;Boolean&gt; <span class="title">unlockInnerAsync</span><span class="params">(<span class="keyword">long</span> threadId)</span> </span>&#123;</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 通过 EVAL 命令执行 Lua 脚本获取锁，保证了原子性</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">return</span> commandExecutor.evalWriteAsync(getName(), LongCodec.INSTANCE, RedisCommands.EVAL_BOOLEAN,</span>
<span class="line">            <span class="comment">//如果分布式锁存在，但是value不匹配，表示锁已经被其他线程占用，无权释放锁，那么直接返回空值（解铃还须系铃人）</span></span>
<span class="line">            <span class="string">"if (redis.call('hexists', KEYS[1], ARGV[3]) == 0) then "</span> +</span>
<span class="line">                <span class="string">"return nil;"</span> +</span>
<span class="line">            <span class="string">"end; "</span> +</span>
<span class="line">             <span class="comment">//如果value匹配，则就是当前线程占有分布式锁，那么将重入次数减1</span></span>
<span class="line">            <span class="string">"local counter = redis.call('hincrby', KEYS[1], ARGV[3], -1); "</span> +</span>
<span class="line">             <span class="comment">//重入次数减1后的值如果大于0，表示分布式锁有重入过，那么只能更新失效时间，还不能删除</span></span>
<span class="line">            <span class="string">"if (counter &gt; 0) then "</span> +</span>
<span class="line">                <span class="string">"redis.call('pexpire', KEYS[1], ARGV[2]); "</span> +</span>
<span class="line">                <span class="string">"return 0; "</span> +</span>
<span class="line">            <span class="string">"else "</span> +</span>
<span class="line">             <span class="comment">//重入次数减1后的值如果为0，这时就可以删除这个KEY，并发布解锁消息，返回1</span></span>
<span class="line">                <span class="string">"redis.call('del', KEYS[1]); "</span> +</span>
<span class="line">                <span class="string">"redis.call('publish', KEYS[2], ARGV[1]); "</span> +</span>
<span class="line">                <span class="string">"return 1; "</span>+</span>
<span class="line">            <span class="string">"end; "</span> +</span>
<span class="line">            <span class="string">"return nil;"</span>,</span>
<span class="line">            <span class="comment">//这5个参数分别对应KEYS[1]，KEYS[2]，ARGV[1]，ARGV[2]和ARGV[3]</span></span>
<span class="line">            Arrays.&lt;Object&gt;asList(getName(), getChannelName()), LockPubSub.UNLOCK_MESSAGE, internalLockLeaseTime, getLockName(threadId));</span>
<span class="line"></span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

### [](#解锁消息处理 "解锁消息处理")解锁消息处理

**org.redisson.pubsub#onMessage**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
<span class="line">33</span>
<span class="line">34</span>
<span class="line">35</span>
<span class="line">36</span>
<span class="line">37</span>
<span class="line">38</span>
<span class="line">39</span>
<span class="line">40</span>
<span class="line">41</span>
<span class="line">42</span>
<span class="line">43</span>
<span class="line">44</span>
<span class="line">45</span>
<span class="line">46</span>
<span class="line">47</span>
<span class="line">48</span>
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">LockPubSub</span> <span class="keyword">extends</span> <span class="title">PublishSubscribe</span>&lt;<span class="title">RedissonLockEntry</span>&gt; </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">final</span> Long UNLOCK_MESSAGE = <span class="number">0L</span>;</span>
<span class="line">    <span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">final</span> Long READ_UNLOCK_MESSAGE = <span class="number">1L</span>;</span>
<span class="line"></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="title">LockPubSub</span><span class="params">(PublishSubscribeService service)</span> </span>&#123;</span>
<span class="line">        <span class="keyword">super</span>(service);</span>
<span class="line">    &#125;</span>
<span class="line">    </span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">protected</span> RedissonLockEntry <span class="title">createEntry</span><span class="params">(RPromise&lt;RedissonLockEntry&gt; newPromise)</span> </span>&#123;</span>
<span class="line">        <span class="keyword">return</span> <span class="keyword">new</span> RedissonLockEntry(newPromise);</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">protected</span> <span class="keyword">void</span> <span class="title">onMessage</span><span class="params">(RedissonLockEntry value, Long message)</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         * 判断是否是解锁消息</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        <span class="keyword">if</span> (message.equals(UNLOCK_MESSAGE)) &#123;</span>
<span class="line">            Runnable runnableToExecute = value.getListeners().poll();</span>
<span class="line">            <span class="keyword">if</span> (runnableToExecute != <span class="keyword">null</span>) &#123;</span>
<span class="line">                runnableToExecute.run();</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            <span class="comment">/**</span></span>
<span class="line"><span class="comment">             * 释放一个信号量，唤醒等待的entry.getLatch().tryAcquire去再次尝试申请锁</span></span>
<span class="line"><span class="comment">             */</span></span>
<span class="line">            value.getLatch().release();</span>
<span class="line">        &#125; <span class="keyword">else</span> <span class="keyword">if</span> (message.equals(READ_UNLOCK_MESSAGE)) &#123;</span>
<span class="line">            <span class="keyword">while</span> (<span class="keyword">true</span>) &#123;</span>
<span class="line">                <span class="comment">/**</span></span>
<span class="line"><span class="comment">                 * 如果还有其他Listeners回调，则也唤醒执行</span></span>
<span class="line"><span class="comment">                 */</span></span>
<span class="line">                Runnable runnableToExecute = value.getListeners().poll();</span>
<span class="line">                <span class="keyword">if</span> (runnableToExecute == <span class="keyword">null</span>) &#123;</span>
<span class="line">                    <span class="keyword">break</span>;</span>
<span class="line">                &#125;</span>
<span class="line">                runnableToExecute.run();</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            value.getLatch().release(value.getLatch().getQueueLength());</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">&#125;</span>
<span class="line"></span>
</pre></td></tr></table></figure>

### [](#总结对比 "总结对比")总结对比

通过 Redisson 实现分布式可重入锁（实现二），比纯自己通过set key value px milliseconds nx +lua 实现（实现一）的效果更好些，虽然基本原理都一样，因为通过分析源码可知，RedissonLock
是可重入的，并且考虑了失败重试，可以设置锁的最大等待时间， 在实现上也做了一些优化，减少了无效的锁申请，提升了资源的利用率。   

**需要特别注意的是，RedissonLock 同样没有解决 节点挂掉的时候，存在丢失锁的风险的问题。而现实情况是有一些场景无法容忍的，所以 Redisson 提供了实现了redlock算法的 RedissonRedLock，RedissonRedLock 真正解决了单点失败的问题，代价是需要额外的为 RedissonRedLock 搭建Redis环境。**

**所以，如果业务场景可以容忍这种小概率的错误，则推荐使用 RedissonLock， 如果无法容忍，则推荐使用 RedissonRedLock。**

## [](#redlock算法 "# redlock算法")# redlock算法

Redis 官网对 redLock 算法的介绍大致如下：
> [The Redlock algorithm](https://redis.io/topics/distlock)

在分布式版本的算法里我们假设我们有N个Redis master节点，这些节点都是完全独立的，我们不用任何复制或者其他隐含的分布式协调机制。之前我们已经描述了在Redis单实例下怎么安全地获取和释放锁。我们确保将在每（N)个实例上使用此方法获取和释放锁。在我们的例子里面我们把N设成5，这是一个比较合理的设置，所以我们需要在5台机器上面或者5台虚拟机上面运行这些实例，这样保证他们不会同时都宕掉。为了取到锁，客户端应该执行以下操作:

1.  获取当前Unix时间，以毫秒为单位。

2.  依次尝试从5个实例，使用相同的key和具有唯一性的value（例如UUID）获取锁。当向Redis请求获取锁时，客户端应该设置一个尝试从某个Reids实例获取锁的最大等待时间（超过这个时间，则立马询问下一个实例），这个超时时间应该小于锁的失效时间。例如你的锁自动失效时间为10秒，则超时时间应该在5-50毫秒之间。这样可以避免服务器端Redis已经挂掉的情况下，客户端还在死死地等待响应结果。如果服务器端没有在规定时间内响应，客户端应该尽快尝试去另外一个Redis实例请求获取锁。

3.  客户端使用当前时间减去开始获取锁时间（步骤1记录的时间）就得到获取锁消耗的时间。当且仅当从大多数（N/2+1，这里是3个节点）的Redis节点都取到锁，并且使用的总耗时小于锁失效时间时，锁才算获取成功。

4.  如果取到了锁，key的真正有效时间 = 有效时间（获取锁时设置的key的自动超时时间） - 获取锁的总耗时（询问各个Redis实例的总耗时之和）（步骤3计算的结果）。

5.  如果因为某些原因，最终获取锁失败（即没有在至少 “N/2+1 ”个Redis实例取到锁或者“获取锁的总耗时”超过了“有效时间”），客户端应该在所有的Redis实例上进行解锁（即便某些Redis实例根本就没有加锁成功，这样可以防止某些节点获取到锁但是客户端没有得到响应而导致接下来的一段时间不能被重新获取锁）。

## [](#用-Redisson-实现分布式锁-红锁-RedissonRedLock-及源码分析（实现三） "# 用 Redisson 实现分布式锁(红锁 RedissonRedLock)及源码分析（实现三）")# 用 Redisson 实现分布式锁(红锁 RedissonRedLock)及源码分析（实现三）

这里以三个单机模式为例，需要特别注意的是他们完全互相独立，不存在主从复制或者其他集群协调机制。
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
<span class="line">33</span>
<span class="line">34</span>
<span class="line">35</span>
<span class="line">36</span>
<span class="line">37</span>
<span class="line">38</span>
<span class="line">39</span>
<span class="line">40</span>
</pre></td><td class="code"><pre><span class="line">Config config1 = <span class="keyword">new</span> Config();</span>
<span class="line">config1.useSingleServer().setAddress(<span class="string">"redis://172.0.0.1:5378"</span>).setPassword(<span class="string">"a123456"</span>).setDatabase(<span class="number">0</span>);</span>
<span class="line">RedissonClient redissonClient1 = Redisson.create(config1);</span>
<span class="line"></span>
<span class="line">Config config2 = <span class="keyword">new</span> Config();</span>
<span class="line">config2.useSingleServer().setAddress(<span class="string">"redis://172.0.0.1:5379"</span>).setPassword(<span class="string">"a123456"</span>).setDatabase(<span class="number">0</span>);</span>
<span class="line">RedissonClient redissonClient2 = Redisson.create(config2);</span>
<span class="line"></span>
<span class="line">Config config3 = <span class="keyword">new</span> Config();</span>
<span class="line">config3.useSingleServer().setAddress(<span class="string">"redis://172.0.0.1:5380"</span>).setPassword(<span class="string">"a123456"</span>).setDatabase(<span class="number">0</span>);</span>
<span class="line">RedissonClient redissonClient3 = Redisson.create(config3);</span>
<span class="line"></span>
<span class="line"><span class="comment">/**</span></span>
<span class="line"><span class="comment"> * 获取多个 RLock 对象</span></span>
<span class="line"><span class="comment"> */</span></span>
<span class="line">RLock lock1 = redissonClient1.getLock(lockKey);</span>
<span class="line">RLock lock2 = redissonClient2.getLock(lockKey);</span>
<span class="line">RLock lock3 = redissonClient3.getLock(lockKey);</span>
<span class="line"></span>
<span class="line"><span class="comment">/**</span></span>
<span class="line"><span class="comment"> * 根据多个 RLock 对象构建 RedissonRedLock （最核心的差别就在这里）</span></span>
<span class="line"><span class="comment"> */</span></span>
<span class="line">RedissonRedLock redLock = <span class="keyword">new</span> RedissonRedLock(lock1, lock2, lock3);</span>
<span class="line"></span>
<span class="line"><span class="keyword">try</span> &#123;</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 4.尝试获取锁</span></span>
<span class="line"><span class="comment">     * waitTimeout 尝试获取锁的最大等待时间，超过这个值，则认为获取锁失败</span></span>
<span class="line"><span class="comment">     * leaseTime   锁的持有时间,超过这个时间锁会自动失效（值应设置为大于业务处理的时间，确保在锁有效期内业务能处理完）</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">boolean</span> res = redLock.tryLock((<span class="keyword">long</span>)waitTimeout, (<span class="keyword">long</span>)leaseTime, TimeUnit.SECONDS);</span>
<span class="line">    <span class="keyword">if</span> (res) &#123;</span>
<span class="line">        <span class="comment">//成功获得锁，在这里处理业务</span></span>
<span class="line">    &#125;</span>
<span class="line">&#125; <span class="keyword">catch</span> (Exception e) &#123;</span>
<span class="line">    <span class="keyword">throw</span> <span class="keyword">new</span> RuntimeException(<span class="string">"aquire lock fail"</span>);</span>
<span class="line">&#125;<span class="keyword">finally</span>&#123;</span>
<span class="line">    <span class="comment">//无论如何, 最后都要解锁</span></span>
<span class="line">    redLock.unlock();</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

**最核心的变化就是需要构建多个 RLock ,然后根据多个 RLock 构建成一个 RedissonRedLock，因为 redLock 算法是建立在多个互相独立的 Redis 环境之上的（为了区分可以叫为 Redission node），Redission node 节点既可以是单机模式(single)，也可以是主从模式(master/salve)，哨兵模式(sentinal)，或者集群模式(cluster)。这就意味着，不能跟以往这样只搭建 1个 cluster、或 1个 sentinel 集群，或是1套主从架构就了事了，需要为 RedissonRedLock 额外搭建多几套独立的 Redission 节点。 比如可以搭建3个 或者5个 Redission节点，具体可看视资源及业务情况而定。**

**下图是一个利用多个 Redission node 最终 组成 RedLock分布式锁的例子，需要特别注意的是每个  Redission node 是互相独立的，不存在任何复制或者其他隐含的分布式协调机制。**

![](/images/2019041504.png)
![](/images/2019041505.png)

## [](#Redisson-实现redlock算法源码分析（RedLock） "# Redisson 实现redlock算法源码分析（RedLock）")# Redisson 实现redlock算法源码分析（RedLock）

**加锁核心代码**

 **org.redisson.RedissonMultiLock#tryLock**
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
<span class="line">10</span>
<span class="line">11</span>
<span class="line">12</span>
<span class="line">13</span>
<span class="line">14</span>
<span class="line">15</span>
<span class="line">16</span>
<span class="line">17</span>
<span class="line">18</span>
<span class="line">19</span>
<span class="line">20</span>
<span class="line">21</span>
<span class="line">22</span>
<span class="line">23</span>
<span class="line">24</span>
<span class="line">25</span>
<span class="line">26</span>
<span class="line">27</span>
<span class="line">28</span>
<span class="line">29</span>
<span class="line">30</span>
<span class="line">31</span>
<span class="line">32</span>
<span class="line">33</span>
<span class="line">34</span>
<span class="line">35</span>
<span class="line">36</span>
<span class="line">37</span>
<span class="line">38</span>
<span class="line">39</span>
<span class="line">40</span>
<span class="line">41</span>
<span class="line">42</span>
<span class="line">43</span>
<span class="line">44</span>
<span class="line">45</span>
<span class="line">46</span>
<span class="line">47</span>
<span class="line">48</span>
<span class="line">49</span>
<span class="line">50</span>
<span class="line">51</span>
<span class="line">52</span>
<span class="line">53</span>
<span class="line">54</span>
<span class="line">55</span>
<span class="line">56</span>
<span class="line">57</span>
<span class="line">58</span>
<span class="line">59</span>
<span class="line">60</span>
<span class="line">61</span>
<span class="line">62</span>
<span class="line">63</span>
<span class="line">64</span>
<span class="line">65</span>
<span class="line">66</span>
<span class="line">67</span>
<span class="line">68</span>
<span class="line">69</span>
<span class="line">70</span>
<span class="line">71</span>
<span class="line">72</span>
<span class="line">73</span>
<span class="line">74</span>
<span class="line">75</span>
<span class="line">76</span>
<span class="line">77</span>
<span class="line">78</span>
<span class="line">79</span>
<span class="line">80</span>
<span class="line">81</span>
<span class="line">82</span>
<span class="line">83</span>
<span class="line">84</span>
<span class="line">85</span>
<span class="line">86</span>
<span class="line">87</span>
<span class="line">88</span>
<span class="line">89</span>
<span class="line">90</span>
<span class="line">91</span>
<span class="line">92</span>
<span class="line">93</span>
<span class="line">94</span>
<span class="line">95</span>
<span class="line">96</span>
<span class="line">97</span>
<span class="line">98</span>
<span class="line">99</span>
<span class="line">100</span>
<span class="line">101</span>
<span class="line">102</span>
<span class="line">103</span>
</pre></td><td class="code"><pre><span class="line"><span class="function"><span class="keyword">public</span> <span class="keyword">boolean</span> <span class="title">tryLock</span><span class="params">(<span class="keyword">long</span> waitTime, <span class="keyword">long</span> leaseTime, TimeUnit unit)</span> <span class="keyword">throws</span> InterruptedException </span>&#123;</span>
<span class="line">    <span class="keyword">long</span> newLeaseTime = -<span class="number">1</span>;</span>
<span class="line">    <span class="keyword">if</span> (leaseTime != -<span class="number">1</span>) &#123;</span>
<span class="line">        newLeaseTime = unit.toMillis(waitTime)*<span class="number">2</span>;</span>
<span class="line">    &#125;</span>
<span class="line">    </span>
<span class="line">    <span class="keyword">long</span> time = System.currentTimeMillis();</span>
<span class="line">    <span class="keyword">long</span> remainTime = -<span class="number">1</span>;</span>
<span class="line">    <span class="keyword">if</span> (waitTime != -<span class="number">1</span>) &#123;</span>
<span class="line">        remainTime = unit.toMillis(waitTime);</span>
<span class="line">    &#125;</span>
<span class="line">    <span class="keyword">long</span> lockWaitTime = calcLockWaitTime(remainTime);</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 1\. 允许加锁失败节点个数限制（N-(N/2+1)）</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">int</span> failedLocksLimit = failedLocksLimit();</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 2\. 遍历所有节点通过EVAL命令执行lua加锁</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    List&lt;RLock&gt; acquiredLocks = <span class="keyword">new</span> ArrayList&lt;&gt;(locks.size());</span>
<span class="line">    <span class="keyword">for</span> (ListIterator&lt;RLock&gt; iterator = locks.listIterator(); iterator.hasNext();) &#123;</span>
<span class="line">        RLock lock = iterator.next();</span>
<span class="line">        <span class="keyword">boolean</span> lockAcquired;</span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         *  3.对节点尝试加锁</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        <span class="keyword">try</span> &#123;</span>
<span class="line">            <span class="keyword">if</span> (waitTime == -<span class="number">1</span> &amp;&amp; leaseTime == -<span class="number">1</span>) &#123;</span>
<span class="line">                lockAcquired = lock.tryLock();</span>
<span class="line">            &#125; <span class="keyword">else</span> &#123;</span>
<span class="line">                <span class="keyword">long</span> awaitTime = Math.min(lockWaitTime, remainTime);</span>
<span class="line">                lockAcquired = lock.tryLock(awaitTime, newLeaseTime, TimeUnit.MILLISECONDS);</span>
<span class="line">            &#125;</span>
<span class="line">        &#125; <span class="keyword">catch</span> (RedisResponseTimeoutException e) &#123;</span>
<span class="line">            <span class="comment">// 如果抛出这类异常，为了防止加锁成功，但是响应失败，需要解锁所有节点</span></span>
<span class="line">            unlockInner(Arrays.asList(lock));</span>
<span class="line">            lockAcquired = <span class="keyword">false</span>;</span>
<span class="line">        &#125; <span class="keyword">catch</span> (Exception e) &#123;</span>
<span class="line">            <span class="comment">// 抛出异常表示获取锁失败</span></span>
<span class="line">            lockAcquired = <span class="keyword">false</span>;</span>
<span class="line">        &#125;</span>
<span class="line">        </span>
<span class="line">        <span class="keyword">if</span> (lockAcquired) &#123;</span>
<span class="line">            <span class="comment">/**</span></span>
<span class="line"><span class="comment">             *4\. 如果获取到锁则添加到已获取锁集合中</span></span>
<span class="line"><span class="comment">             */</span></span>
<span class="line">            acquiredLocks.add(lock);</span>
<span class="line">        &#125; <span class="keyword">else</span> &#123;</span>
<span class="line">            <span class="comment">/**</span></span>
<span class="line"><span class="comment">             * 5\. 计算已经申请锁失败的节点是否已经到达 允许加锁失败节点个数限制 （N-(N/2+1)）</span></span>
<span class="line"><span class="comment">             * 如果已经到达， 就认定最终申请锁失败，则没有必要继续从后面的节点申请了</span></span>
<span class="line"><span class="comment">             * 因为 Redlock 算法要求至少N/2+1 个节点都加锁成功，才算最终的锁申请成功</span></span>
<span class="line"><span class="comment">             */</span></span>
<span class="line">            <span class="keyword">if</span> (locks.size() - acquiredLocks.size() == failedLocksLimit()) &#123;</span>
<span class="line">                <span class="keyword">break</span>;</span>
<span class="line">            &#125;</span>
<span class="line"></span>
<span class="line">            <span class="keyword">if</span> (failedLocksLimit == <span class="number">0</span>) &#123;</span>
<span class="line">                unlockInner(acquiredLocks);</span>
<span class="line">                <span class="keyword">if</span> (waitTime == -<span class="number">1</span> &amp;&amp; leaseTime == -<span class="number">1</span>) &#123;</span>
<span class="line">                    <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">                &#125;</span>
<span class="line">                failedLocksLimit = failedLocksLimit();</span>
<span class="line">                acquiredLocks.clear();</span>
<span class="line">                <span class="comment">// reset iterator</span></span>
<span class="line">                <span class="keyword">while</span> (iterator.hasPrevious()) &#123;</span>
<span class="line">                    iterator.previous();</span>
<span class="line">                &#125;</span>
<span class="line">            &#125; <span class="keyword">else</span> &#123;</span>
<span class="line">                failedLocksLimit--;</span>
<span class="line">            &#125;</span>
<span class="line">        &#125;</span>
<span class="line"></span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         * 6.计算 目前从各个节点获取锁已经消耗的总时间，如果已经等于最大等待时间，则认定最终申请锁失败，返回false</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        <span class="keyword">if</span> (remainTime != -<span class="number">1</span>) &#123;</span>
<span class="line">            remainTime -= System.currentTimeMillis() - time;</span>
<span class="line">            time = System.currentTimeMillis();</span>
<span class="line">            <span class="keyword">if</span> (remainTime &lt;= <span class="number">0</span>) &#123;</span>
<span class="line">                unlockInner(acquiredLocks);</span>
<span class="line">                <span class="keyword">return</span> <span class="keyword">false</span>;</span>
<span class="line">            &#125;</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">if</span> (leaseTime != -<span class="number">1</span>) &#123;</span>
<span class="line">        List&lt;RFuture&lt;Boolean&gt;&gt; futures = <span class="keyword">new</span> ArrayList&lt;&gt;(acquiredLocks.size());</span>
<span class="line">        <span class="keyword">for</span> (RLock rLock : acquiredLocks) &#123;</span>
<span class="line">            RFuture&lt;Boolean&gt; future = ((RedissonLock) rLock).expireAsync(unit.toMillis(leaseTime), TimeUnit.MILLISECONDS);</span>
<span class="line">            futures.add(future);</span>
<span class="line">        &#125;</span>
<span class="line">        </span>
<span class="line">        <span class="keyword">for</span> (RFuture&lt;Boolean&gt; rFuture : futures) &#123;</span>
<span class="line">            rFuture.syncUninterruptibly();</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line"></span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 7.如果逻辑正常执行完则认为最终申请锁成功，返回true</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="keyword">return</span> <span class="keyword">true</span>;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

## [](#参考文献 "# 参考文献")# 参考文献

[1][Distributed locks with Redis](https://redis.io/topics/distlock)

[2][Distributed locks with Redis 中文版](http://redis.cn/topics/distlock.html)

[3][SET - Redis](https://redis.io/commands/set)

[4][EVAL command](https://redis.io/commands/eval)

[5] [Redisson](https://github.com/redisson/redisson)

[6][Redis分布式锁的正确实现方式](https://wudashan.cn/2017/10/23/Redis-Distributed-Lock-Implement/#%E7%BB%84%E4%BB%B6%E4%BE%9D%E8%B5%96)

[7][Redlock实现分布式锁](https://mp.weixin.qq.com/s/JLEzNqQsx-Lec03eAsXFOQ)

[8][Redisson实现Redis分布式锁](https://mp.weixin.qq.com/s/iaZcc7QGbGHkZkfLeYp1yg)