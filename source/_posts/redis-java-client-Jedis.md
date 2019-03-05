---
title: Redis 开发与运维 3：Redis 的Java 客户端 Jedis
date: 2018-08-12 12:51:57
categories:
- Redis
tags:
- Redis
- Jedis
- jedisPool
- Pipelining
---

## 一、概述
Jedis 是 Redis 官方推荐的 Java 连接开发工具。Jedis 是一个非常小但又功能健全的 java 客户端。Jedis 是开源的，目前最新版本是 2.9.0 , 兼容 redis 2.8.x 和 3.x.x.版本，Github 地址： [https://github.com/xetorthio/jedis](https://github.com/xetorthio/jedis)

**Jedis 提供了哪些支持？**
- 排序
- 连接操作
- 支持 redis 所有 value 操作相关的命令
- 支持 redis 提供的五种数据结构及相关命令
- 事物 (Transactions)
- Pipelining
- 发布/订阅 Publish/Subscribe
- 连接池 (Connection pooling)
- 分片 (Sharding )
- Lua 脚本
- 集群 (Redis Cluster)
- Persistence control commands
- Remote server control commands


## 二、获取 Jedis 

通过 maven 配置依赖

{% codeblock lang:xml%}
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>2.9.0</version>
    <type>jar</type>
    <scope>compile</scope>
</dependency>
{% endcodeblock%}

## 三、Jedis 直连 Redis

直连方式每次都会新建 TCP 连接，使用后再断开连接，对于频繁访问 Redis 的场景显然不是高效的使用方式。生产环境不推荐使用这种方式。

![](/images/2018081301.png)


代码示例：

{% codeblock lang:java%}
Jedis jedis = null;
try { 
    //生成一个Jedis对象，这个对象负责和指定Redis实例进行通信
    jedis = new Jedis("127.0.0.1",6379);
    
    //然后通过 jedis 对象就可以调用 redis 支持的命令了，比如
    jedis.set("hello","world");
    String value = jedis.get("hello");
    
} catch (Exception e){ 
    logger.error(e.getMessage(), e);
} finally { 
    if (jedis != null) { 
       //使用完之后关闭连接
       jedis.close(); 
    } 
}
{% endcodeblock%}

在实际项目推荐使用 try catch finally 的形式来进行代码的书写：一方面可以在 Jedis 出现异常的时候（本身是网络操作），将异常进行捕获或者抛出；另一个方面无论执行成功或者失败，将 Jedis 连接关闭掉。



创建 Jedis 时，还可以调用以下构造函数，指定 客户端连接超时时间、客户端读写超时时间：

{% codeblock lang:java%}
Jedis jedis = new Jedis(final String host, final int port, final int connectionTimeout, final int soTimeout);
{% endcodeblock%}

## 四、Jedis 连接池方式

所有Jedis对象预先放在池子中（JedisPool），每次要连接 Redis，只需要在池子中借，用完了在归还给连接池。生产环境一般都使用这种方式。

![](/images/2018081302.png)


Jedis提供了 JedisPool 这个类作为对 Jedis 的连接，同时使用了 Apache 的通用对象池工具 common-pool2 作为资源的管理工具。

代码示例：

{% codeblock lang:java%}
	//1.common-pool2 连接池配置
	GenericObjectPoolConfig poolConfig = new GenericObjectPoolConfig();
	//可以根据需要设置相关属性
	poolConfig.setMaxTotal(200);
	poolConfig.setMaxIdle(50);
	poolConfig.setMinIdle(10);

	//2.初始化Jedis连接池
	JedisPool jedisPool = new JedisPool(poolConfig, "127.0.0.1", 6379);
{% endcodeblock%}



此时，获取 Jedis 对象不再是直接生成一个 Jedis 对象进行直连，而是从连接池直接获取：
{% codeblock lang:java%}
 Jedis jedis = null;
try { 
    //从连接池借用 jedis 对象
    jedis = jedisPool.getResource();
    
    //执行操作
    jedis.set("hello","world");
    String value = jedis.get("hello");
    
} catch (Exception e){ 
    logger.error(e.getMessage(), e);
} finally { 
    if (jedis != null) { 
       //使用完后归还连接池
       jedis.close(); 
    } 
}
{% endcodeblock%}


**注意：**以上代码有点需要注意的是：使用 JedisPool 的时候，jedis.close() 不是关闭连接，而是表示归还连接池。

看下 Jedis 对 close方法的实现就很清楚了：

{% codeblock lang:java%}
  public void close() {
    if (dataSource != null) {
      if (client.isBroken()) {
        this.dataSource.returnBrokenResource(this);
      } else {
        this.dataSource.returnResource(this);
      }
    } else {
      client.close();
    }
  }
{% endcodeblock%}

可以看到 Jedis 对于 close 的实现，会先通过 dataSource 是否为 null 判断是否是使用连接池，若是，则调用归还资源函数，否则才真正执行关闭连接的操作。


**GenericObjectPoolConfig 的重要属性如下图所示：**
![](/images/2018081303.jpg)

## 五、Jedis直连方式和连接池方式对比


>You shouldn't use the same instance from different threads because you'll have strange errors. And sometimes creating lots of Jedis instances is not good enough because it means lots of sockets and connections, which leads to strange errors as well. A single Jedis instance is not threadsafe! To avoid these problems, you should use JedisPool, which is a threadsafe pool of network connections. You can use the pool to reliably create several Jedis instances, given you return the Jedis instance to the pool when done. This way you can overcome those strange errors and achieve great performance.

单个Jedis对象是线程不安全的，我们不应该在多个线程中使用共用同一个Jedis对象，然而，如果通过直连方式创建多个Jedis对象，又意味着会创建大量的socket以及TCP连接，带来大量的开销。为了避免这个问题，Jedis 为我们提供了一个线程安全的线程池JedisPool，通过连接池的方式，可以预先可靠地创建好多个Jedis连接对象，然后每次需要的时候就从Jedis连接池借用，使用完之后归还即可。这种方式提供了更大的安全性以及灵活性，所以，生产环境推荐使用连接池方式。


|| 优点 | 缺点 |
|:------:|:------:|:------:|
| 直连 | 简单方便，适用于少量长期连接的场景|1）存在每次新建/关闭 TCP 连接开销<br/> 2）资源无法控制，可能会出现连接泄露  <br/> 3）Jedis对象线程不安全|
| 连接池|1）无需每次连接都生成Jedis对象，降低开销<br/>2）使用连接池的方式控制和保护资源的使用 | 相对于直连，使用相对麻烦，尤其在资源的管理上需要很多参数来保证，一旦规则不合理也会出现问题 |

## 六、Pipelining

>Sometimes you need to send a bunch of different commands. A very cool way to do that, and have better performance than doing it the naive way, is to use pipelining. This way you send commands without waiting for response, and you actually read the responses at the end, which is faster.

Redis 支持 Pipelining 特性，Pipeline在某些场景下非常有用，比如有时想批量提交多个命令，而且他们对相应结果没有互相依赖，而且对结果响应也无需立即获得，那么久可以利用 Pipelining 实现这种批量处理，一次性发送多条命令并在执行完后一次性将结果返回。pipeline通过减少客户端与redis的通信次数来实现降低往返延时时间。过程大致如下：

![](/images/2018081304.jpg)

**通过Jedis使用 Pipelining 的示例如下：**

{% codeblock lang:java%}
	Pipeline p = jedis.pipelined();
	p.set("fool", "bar"); 
	p.zadd("foo", 1, "barowitch");  
	p.zadd("foo", 0, "barinsky");
	p.zadd("foo", 0, "barikoviev");
	Response<String> pipeString = p.get("fool");
	Response<Set<String>> sose = p.zrange("foo", 0, -1);
	p.sync(); 
	int soseSize = sose.get().size();
	Set<String> setBack = sose.get();
{% endcodeblock%}


## 七、发布/订阅（Publish/Subscribe）

Redis 通过 PUBLISH、SUBSCRIBE 等命令实现了订阅与发布模式，Redis 的 SUBSCRIBE 命令可以让客户端订阅任意数量的频道，每当有新信息 发布到被订阅的频道时， 信息就会被发送给所有订阅指定频道的客户端。

整个模型过程如下图所示：

![](/images/2018081305.png)

上图展示了频道 channel1 ，以及订阅这个频道的三个客户端 —— client2 、 client5 和 client1 之间的关系，当有新消息通过 PUBLISH 命令发送给频道 channel1 时， 这个消息就会被发送给订阅它的三个客户端。


**使用场景：**

Publish/Subscribe 是目前广泛使用的通信模型，有很多的使用场景，比如内容订阅的的场；
；比如分布式架构中实现读写分离的场景，在写入的过程中，就可以使用redis发布订阅，使得写入值及时发布到各个读的程序中，保证数据的完整一致性。场景还有很多，有待挖掘。


**在 Jedis 使用 Publish/Subscribe 的示例，可以参考：**[java实现 redis的发布订阅（简单易懂）](https://www.cnblogs.com/xinde123/p/8489054.html)


## 八、参考文献

[1] 《Redis 开发与运维》付磊; 张益军著
[2] [Jedis WiKi](https://github.com/xetorthio/jedis/wiki/Getting-started)
[3] [Jedis API](https://xetorthio.github.io/jedis/)
[4] [Jedis 源码](https://github.com/xetorthio/jedis)
[5] [订阅与发布](https://redisbook.readthedocs.io/en/latest/feature/pubsub.html#id2)
