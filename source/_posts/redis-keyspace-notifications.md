---
title: 订阅 Redis 的 key 过期事件实现动态定时任务
tags:
  - Redis
  - Pub/Sub
  - Redis Keyspace Notifications
date: 2019-04-09 23:27:52
---

### [](#一、需求 "一、需求")一、需求

1.  设置了生存时间的Key，在过期时能不能有所提示？
2.  如果能对过期Key有个监听，如何对过期Key进行一个回调处理？
3.  如何使用 Redis 来实现定时任务？

比如：

*   处理订单过期自动取消，12306 购票系统超过30分钟没有成功支付的订单会被回收处理;
*   购买商品15天后默认好评；
*   外卖系统的送餐超时提醒；
*   客服与顾客聊天，客服超过多长时间没回复，系统给客服发一个提醒消息；
…

<!--more-->

这里的定时任务并不是  Crontab 这种如 `0 0 23 * * ?` (每日23点执行) 定死多长时间执行一次的， 而是某种特定动作触发创建的一个多长时间后执行的任务。比如有100个 用户触发了这个动作，那么就会创建100个定时任务，并且这100个任务由于触发创建的时间不同，执行的时间也很可能不在同一时间。

### [](#二、思路 "二、思路")二、思路

在 Redis 的 2.8.0 版本之后，其推出了一个新的特性——键空间消息（Redis Keyspace Notifications），它配合 2.0.0 版本之后的 SUBSCRIBE 就能完成这个定时任务的操作了。

**Redis 的键空间通知支持  订阅指定 Key 的所有事件  与 订阅指定事件  两种方式。**
> Keyspace notifications are implemented sending two distinct type of events for every operation affecting the Redis data space. For instance a DEL operation targeting the key named mykey in database 0 will trigger the delivering of two messages, exactly equivalent to the following two PUBLISH commands:<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
</pre></td><td class="code"><pre><span class="line">PUBLISH __keyspace@0__:mykey del</span>
<span class="line">PUBLISH __keyevent@0__:del mykey</span>
</pre></td></tr></table></figure>

**通过 Redis 的键空间通知（keyspace notification）可以做到：下单时将订单 id 写入 redis，设置过期时间30分钟，利用 redis 键过期回调提醒，30分钟后可以在回调函数里检查订单状态，如果未支付，则进行处理。**

### [](#三、实现 "三、实现")三、实现

#### [](#1-修改-redis-conf-开启redis-key过期提醒 "1\. 修改 redis.conf 开启redis key过期提醒")1\. 修改 redis.conf 开启redis key过期提醒
> By default keyspace events notifications are disabled because while not very sensible the feature uses some CPU power. Notifications are enabled using the notify-keyspace-events of redis.conf or via the CONFIG SET.

由于键空间通知比较耗CPU, 所以 Redis默认是关闭键空间事件通知的， 需要手动开启 notify-keyspace-events 后才启作用。
<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
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
</pre></td><td class="code"><pre><span class="line">K：keyspace事件，事件以__keyspace@&lt;db&gt;__为前缀进行发布；        </span>
<span class="line">E：keyevent事件，事件以__keyevent@&lt;db&gt;__为前缀进行发布；        </span>
<span class="line">g：一般性的，非特定类型的命令，比如del，expire，rename等；       </span>
<span class="line">$：String 特定命令；        </span>
<span class="line">l：List 特定命令；        </span>
<span class="line">s：Set 特定命令；        </span>
<span class="line">h：Hash 特定命令；        </span>
<span class="line">z：Sorted 特定命令；        </span>
<span class="line">x：过期事件，当某个键过期并删除时会产生该事件；        </span>
<span class="line">e：驱逐事件，当某个键因maxmemore策略而被删除时，产生该事件；        </span>
<span class="line">A：g$lshzxe的别名，因此”AKE”意味着所有事件。</span>
</pre></td></tr></table></figure>

**`notify-keyspace-events Ex` 表示开启键过期事件提醒**

#### [](#2-继承-JedisPubSub-实现一个消息监听器类 "2\. 继承 JedisPubSub 实现一个消息监听器类")2\. 继承 JedisPubSub 实现一个消息监听器类
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
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Component</span></span>
<span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">RedisKeyExpiredListener</span> <span class="keyword">extends</span> <span class="title">JedisPubSub</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">private</span> Logger logger = LoggerFactory.getLogger(RedisKeyExpiredListener.class);</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">onMessage</span><span class="params">(String channel, String message)</span> </span>&#123;</span>
<span class="line">    </span>
<span class="line">       <span class="comment">//message.toString()可以获取失效的key</span></span>
<span class="line">      String expiredKey = message.toString();</span>
<span class="line">      <span class="keyword">if</span>(expiredKey.startsWith(<span class="string">"key:prefix"</span>))&#123;</span>
<span class="line">            <span class="comment">/**</span></span>
<span class="line"><span class="comment">             * TODO</span></span>
<span class="line"><span class="comment">             * 如果是自己想要监控的KEY, 则可以在这里处理业务</span></span>
<span class="line"><span class="comment">             */</span></span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

**由于每个key过期都会回调 onPMessage 方法， 所以不建议在 onPMessage  回调方法中直接处理业务， 这里可以通过 MQ 来做缓冲，在 onPMessage 中 把消息直接扔到 MQ 里， 然后再去监听队列消费消息处理具体的业务。**

改进版如下：
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
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Component</span></span>
<span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">RedisKeyExpiredListener</span> <span class="keyword">extends</span> <span class="title">JedisPubSub</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">private</span> Logger logger = LoggerFactory.getLogger(RedisKeyExpiredListener.class);</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Resource</span></span>
<span class="line">    <span class="keyword">private</span> ICommonsMqService commonsMqService;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">onMessage</span><span class="params">(String channel, String message)</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">        <span class="keyword">try</span> &#123;</span>
<span class="line">            commonsMqService.sendSingleMessageAsync(<span class="string">"REDIS_TIMEOUT_KEY_QUEUE"</span>, message);</span>
<span class="line">            logger.info(<span class="string">"发送支付超时MQ消息成功：&#123;&#125;"</span>,message);</span>
<span class="line">        &#125;<span class="keyword">catch</span> (Exception e)&#123;</span>
<span class="line">            logger.error(<span class="string">"发送支付超时MQ消息失败：&#123;&#125;"</span>,e.toString());</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
<span class="line"></span>
</pre></td></tr></table></figure>

#### [](#3-订阅指定-db-的过期事件 "3\. 订阅指定 db 的过期事件")3\. 订阅指定 db 的过期事件
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
</pre></td><td class="code"><pre><span class="line"><span class="meta">@Component</span></span>
<span class="line"><span class="meta">@Order</span>(value = <span class="number">4</span>)</span>
<span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">SubscriberRedisKeyTimeout</span> <span class="keyword">implements</span> <span class="title">CommandLineRunner</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="keyword">private</span> Logger logger = LoggerFactory.getLogger(SubscriberRedisKeyTimeout.class);</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Resource</span></span>
<span class="line">    RedisKeyExpiredListener redisKeyExpiredListener;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">run</span><span class="params">(String... args)</span> <span class="keyword">throws</span> Exception </span>&#123;</span>
<span class="line"></span>
<span class="line">        JedisPool pool = <span class="keyword">new</span> JedisPool(<span class="keyword">new</span> JedisPoolConfig(), <span class="string">"127.0.0.1"</span>, <span class="number">8005</span>);</span>
<span class="line">        Jedis jedis = pool.getResource();</span>
<span class="line"></span>
<span class="line">        <span class="comment">/**</span></span>
<span class="line"><span class="comment">         * 订阅线程：接收消息</span></span>
<span class="line"><span class="comment">         * 由于订阅者（subscriber）在进入订阅状态后会阻塞线程，</span></span>
<span class="line"><span class="comment">         * 因此新起一个线程（new Thread()）作为订阅线程</span></span>
<span class="line"><span class="comment">         */</span></span>
<span class="line">        <span class="keyword">new</span> Thread(<span class="keyword">new</span> Runnable() &#123;</span>
<span class="line">            <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">run</span><span class="params">()</span> </span>&#123;</span>
<span class="line">                <span class="keyword">try</span> &#123;</span>
<span class="line">                    logger.info(<span class="string">"Subscribing. This thread will be blocked."</span>);</span>
<span class="line">                    <span class="comment">//使用subscriber订阅 db0上的key过期事件消息，这一句之后，线程进入订阅模式，阻塞。</span></span>
<span class="line">                     jedis.subscribe(redisKeyExpiredListener, <span class="string">"__keyevent@0__:expired"</span>);</span>
<span class="line">     </span>
<span class="line">                    <span class="comment">//当unsubscribe()方法被调用时，才执行以下代码</span></span>
<span class="line">                    logger.info(<span class="string">"Subscription ended."</span>);</span>
<span class="line">                &#125; <span class="keyword">catch</span> (Exception e) &#123;</span>
<span class="line">                    logger.error(<span class="string">"Subscribing failed."</span>, e);</span>
<span class="line">                &#125;</span>
<span class="line">            &#125;</span>
<span class="line">        &#125;).start();</span>
<span class="line"></span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

#### [](#4-测试 "4\. 测试")4\. 测试
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
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">TestJedisExpipreNotice</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">void</span> <span class="title">main</span><span class="params">(String[] args)</span> </span>&#123;</span>
<span class="line">        JedisPool pool = <span class="keyword">new</span> JedisPool(<span class="keyword">new</span> JedisPoolConfig(), <span class="string">"127.0.0.1"</span>, <span class="number">8005</span>);</span>
<span class="line">        Jedis jedis = pool.getResource();</span>
<span class="line"></span>
<span class="line">        jedis.setex(<span class="string">"REDIS:EXPIPRE:NOTICE:TEST"</span>,<span class="number">5</span>, <span class="string">"测试键过期事件回调"</span>);</span>
<span class="line"></span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
<span class="line"></span>
</pre></td></tr></table></figure>

5秒后控制台打印如下：
<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
</pre></td><td class="code"><pre><span class="line">2019-03-26 17:35:44.248  INFO 20464 --- [ Thread-127] c.p.c.r.b.r.RedisKeyExpiredListener  : 发送聊天会话超时MQ消息成功：REDIS:EXPIPRE:NOTICE:TEST</span>
</pre></td></tr></table></figure>

### [](#四、-subscribe-psubscibe-的区别 "四、 subscribe/psubscibe 的区别")四、 subscribe/psubscibe 的区别

Redis 提供了 publish 和  subscribe/psubscibe 指令来实现发布/订阅模型，发布和订阅的目标称为通道(channel)。 subscribe/psubscribe 了一个或多个通道的客户端，可以收到其他客户端向这个通道publish的消息。subscribe和psubscribe的区别是，前者指定具体的通道名称，而后者可以指定一个正则表达式，匹配这个表达式的通道都被订阅。

![](/images/20190327.svg)

上图展示了一个带有频道和模式的例子， 其中 `tweet.shop.*`  模式匹配了 `tweet.shop.kindle` 频道和 `tweet.shop.ipad` 频道， 并且有不同的客户端分别用 psubscibe 订阅它们三个：当有信息发送到 `tweet.shop.kindle` 频道时， 信息除了发送给 clientX 和 clientY 之外， 还会发送给订阅 `tweet.shop.*`  模式的 client123 和 client256。

### [](#五、参考文献 "五、参考文献")五、参考文献

[1][Redis Pub/Sub](https://redis.io/topics/pubsub)

[2][Redis Keyspace Notifications](https://redis.io/topics/notifications)

[3][Redis的Pub/Sub模式](https://my.oschina.net/itblog/blog/601284?p=1)

[4][Redis设计与实现第一版-订阅与发布](https://redisbook.readthedocs.io/en/latest/feature/pubsub.html)

[5][Redis实践操作之—— keyspace notification（键空间通知](https://www.cnblogs.com/tinywan/p/5903988.html)