---
title: 数据存储 2：分布式系统全局唯一ID生成方案
date: 2018-07-21 00:32:50
categories:
- RDBMS
tags:
- 唯一ID
- 分布式系统ID生成器
- snowflake
- Leaf-segment
- Leaf-snowflake
- seqsvr
- RDBMS
---


## 一、背景
最近在 ifeve.com 看到这么一个面试题 “[京东面试题 – 有一个生成唯一串的需求，并发请求量非常大，该如何实现？](http://ifeve.com/question/%E4%BA%AC%E4%B8%9C%E9%9D%A2%E8%AF%95%E9%A2%98-%E6%9C%89%E4%B8%80%E4%B8%AA%E7%94%9F%E6%88%90%E5%94%AF%E4%B8%80%E4%B8%B2%E7%9A%84%E9%9C%80%E6%B1%82%EF%BC%8C%E5%B9%B6%E5%8F%91%E8%AF%B7%E6%B1%82/)”。在现实开发中，这也是必须要考虑到的一个点。比如分库分表后主键采用什么策略生成？在分布式系统中如何生成唯一ID标识？

从业务上来说，常见的如订单号，支付单号等，都需要唯一 ID 做标识，简单的数据库递增是不能满足的，因为这样既会显得不专业，也会不安全，比如你的竞争对手可以今天中午12点下个单记录下订单号，明天中午12点再下个单，通过对比2个订单号大概计算出你们的订单量，这是非常可怕的事情。

**那么，业务系统对ID号有哪些要求呢？**

1. 全局唯一性：不能出现重复的ID号，既然是唯一标识，这是最基本的要求。

2. 趋势递增：在MySQL InnoDB引擎中使用的是聚集索引，是用B+tree的数据结构来存储索引数据，在主键的选择上面我们应该尽量使用有序的主键保证写入性能。针对这点，后面根据索引原理展开讲一下。

3. 单调递增：保证下一个ID一定大于上一个ID，例如事务版本号、IM增量消息、排序等特殊需求。

4. 信息安全：如果ID是连续的，恶意用户的扒取工作就非常容易做了，直接按照顺序下载指定URL即可；如果是订单号就更危险了，竞对可以直接知道我们一天的单量。所以在一些应用场景下，会需要ID无规则、不规则。



**这里结合索引原理展开讲下为什么ID需要趋势递增**
InnoDB使用聚集索引，数据记录本身被存于主索引（一颗B+Tree）的叶子节点上。这就要求同一个叶子节点内（大小为一个内存页或磁盘页）的各条数据记录按主键顺序存放，因此每当有一条新的记录插入时，MySQL会根据其主键将其插入适当的节点和位置，如果页面达到装载因子（InnoDB默认为15/16），则开辟一个新的页（节点）。

如果表使用选用趋势递增的ID作为主键，那么每次插入新的记录，记录就会顺序添加到当前索引节点的后续位置，当一页写满，就会自动开辟一个新的页。这样就会形成一个紧凑的索引结构，近似顺序填满。如下图所示：

![](/images/2018072401.png)

由于每次插入时也不需要移动已有数据，因此效率很高，也不会增加很多开销在维护索引上。否则，如使用身份证号或学号等无序的数作为主键，则每次插入主键的值近似于随机，因此每次新纪录都要被插到现有索引页得中间某个位置。此时MySQL不得不为了将新记录插到合适位置而移动大量数据，从而降低写入数据的性能。如下图所示：

![](/images/2018072402.png)

## 二、Twitter的snowflake方案
snowflake 是 Twitter 开源的分布式ID生成算法，是一种划分命名空间来生成ID的一种算法，结果是一个long型的ID。其核心思想是：把64-bit分别划分成多段。如下图所示：
![](/images/2018072301.png)

其中，41-bit的时间可以表示（1L<<41）/(1000L*3600*24*365)=69年的时间，10-bit机器可以分别表示1024台机器。如果我们对IDC划分有需求，还可以将10-bit分5-bit给数据中心(IDC)，分5-bit给工作机器。这样就可以表示32个IDC，每个IDC下可以有32台机器，可以根据自身需求定义。12个自增序列号可以表示2^12个ID，理论上snowflake方案的QPS约为409.6w/s，这种分配方式可以保证在任何一个IDC的任何一台机器在任意毫秒内生成的ID都是不同的。

这种方式的优缺点是：

**优点：**

- 毫秒数在高位，自增序列在低位，整个ID都是趋势递增的。
- 不依赖数据库等第三方系统，以服务的方式部署，稳定性更高，生成ID的性能也是非常高的。
- 可以根据自身业务特性分配bit位，非常灵活。

**缺点：**

强依赖机器时钟，如果机器上时钟回拨，会导致发号重复或者服务会处于不可用状态。


具体实现的代码可以参看：[https://github.com/twitter/snowflake](https://github.com/twitter/snowflake)，遗憾的是 snowflake 已经不再维护，但是还是可以下载  snowflake-2010 tag , 下载的版本是用 scala 实现的。我们可以根据思想，自己用java语言实现。

{% codeblock lang:java%}

public class IdFactory {
    // ==============================Fields===========================================
    /** 开始时间截 (2010/11/4 9:42:54) */
    private final long twepoch = 1288834974657L;

    /** 机器id所占的位数 */
    private final long workerIdBits = 5L;

    /** 数据标识id所占的位数 */
    private final long datacenterIdBits = 5L;

    /** 支持的最大机器id，结果是31 (这个移位算法可以很快的计算出几位二进制数所能表示的最大十进制数) */
    private final long maxWorkerId = -1L ^ (-1L << workerIdBits);

    /** 支持的最大数据标识id，结果是31 */
    private final long maxDatacenterId = -1L ^ (-1L << datacenterIdBits);

    /** 序列在id中占的位数 */
    private final long sequenceBits = 12L;

    /** 机器ID向左移12位 */
    private final long workerIdShift = sequenceBits;

    /** 数据标识id向左移17位(12+5) */
    private final long datacenterIdShift = sequenceBits + workerIdBits;

    /** 时间截向左移22位(5+5+12) */
    private final long timestampLeftShift = sequenceBits + workerIdBits + datacenterIdBits;

    /** 生成序列的掩码，这里为4095 (0b111111111111=0xfff=4095) */
    private final long sequenceMask = -1L ^ (-1L << sequenceBits);

    /** 工作机器ID(0~31) */
    private long workerId;

    /** 数据中心ID(0~31) */
    private long datacenterId;

    /** 毫秒内序列(0~4095) */
    private long sequence = 0L;

    /** 上次生成ID的时间截 */
    private long lastTimestamp = -1L;

    //==============================Constructors=====================================
    /**
     * 构造函数
     * @param workerId 工作ID (0~31)
     * @param datacenterId 数据中心ID (0~31)
     */
    public IdFactory(long workerId, long datacenterId) {
        if (workerId > maxWorkerId || workerId < 0) {
            throw new IllegalArgumentException(String.format("worker Id can't be greater than %d or less than 0", maxWorkerId));
        }
        if (datacenterId > maxDatacenterId || datacenterId < 0) {
            throw new IllegalArgumentException(String.format("datacenter Id can't be greater than %d or less than 0", maxDatacenterId));
        }
        this.workerId = workerId;
        this.datacenterId = datacenterId;
    }

    // ==============================Methods==========================================
    /**
     * 获得下一个ID (该方法是线程安全的)
     * @return SnowflakeId
     */
    public synchronized long nextId() {
        long timestamp = timeGen();

        //如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
        if (timestamp < lastTimestamp) {
            throw new RuntimeException(
                    String.format("Clock moved backwards.  Refusing to generate id for %d milliseconds", lastTimestamp - timestamp));
        }

        //如果是同一时间生成的，则进行毫秒内序列
        if (lastTimestamp == timestamp) {
            sequence = (sequence + 1) & sequenceMask;
            //毫秒内序列溢出
            if (sequence == 0) {
                //阻塞到下一个毫秒,获得新的时间戳
                timestamp = tilNextMillis(lastTimestamp);
            }
        }
        //时间戳改变，毫秒内序列重置
        else {
            sequence = 0L;
        }

        //上次生成ID的时间截
        lastTimestamp = timestamp;

        //移位并通过或运算拼到一起组成64位的ID
        return ((timestamp - twepoch) << timestampLeftShift) //
                | (datacenterId << datacenterIdShift) //
                | (workerId << workerIdShift) //
                | sequence;
    }

    /**
     * 阻塞到下一个毫秒，直到获得新的时间戳
     * @param lastTimestamp 上次生成ID的时间截
     * @return 当前时间戳
     */
    protected long tilNextMillis(long lastTimestamp) {
        long timestamp = timeGen();
        while (timestamp <= lastTimestamp) {
            timestamp = timeGen();
        }
        return timestamp;
    }

    /**
     * 返回以毫秒为单位的当前时间
     * @return 当前时间(毫秒)
     */
    protected long timeGen() {
        return System.currentTimeMillis();
    }

    //==============================Test=============================================
    /** 测试 */
    public static void main(String[] args) {
    	IdFactory idFactory = new IdFactory(0, 0); //传入工作ID (0~31),数据中心ID (0~31)
        for (int i = 0; i < 10; i++) {
            long id = idFactory.nextId();
            System.out.println(id);
        }
    }
}

{% endcodeblock%}


## 三、Flicker 团队的数据库生成方案

在分布式系统中，为了解决单点故障问题、单点IO性能问题，在分布式系统中，我们的数据库服务器往往也不只一台，那么在多台数据库服务器的情况下如何生成符合要求的ID呢？Flickr团队在2010年撰文介绍的一种主键生成策略([Ticket Servers: Distributed Unique Primary Keys on the Cheap ](http://code.flickr.net/2010/02/08/ticket-servers-distributed-unique-primary-keys-on-the-cheap/))。这种方案的思想是给不同的机器设置不同的初始值，相同的步长。

比如有两台机器。设置步长step为2，TicketServer1的初始值为1（1，3，5，7，9，11...）、TicketServer2的初始值为2（2，4，6，8，10...）如下所示，为了实现上述方案分别设置两台机器对应的参数，TicketServer1从1开始发号，TicketServer2从2开始发号，两台机器每次发号之后都递增2。

```
TicketServer1:
auto-increment-increment = 2
auto-increment-offset = 1

TicketServer2:
auto-increment-increment = 2
auto-increment-offset = 2
```

假设我们要部署N台机器，步长需设置为N，每台的初始值依次为0,1,2...N-1那么整个架构就变成了如下图所示：

![](/images/2018072302.png)

这种架构貌似能够满足性能的需求，但有以下几个缺点：

- 系统水平扩展比较困难，比如定义好了步长和机器台数之后，如果要添加机器该怎么做？假设现在只有一台机器发号是1,2,3,4,5（步长是1），这个时候需要扩容机器一台。可以这样做：把第二台机器的初始值设置得比第一台超过很多，比如14（假设在扩容时间之内第一台不可能发到14），同时设置步长为2，那么这台机器下发的号码都是14以后的偶数。然后摘掉第一台，把ID值保留为奇数，比如7，然后修改第一台的步长为2。让它符合我们定义的号段标准，对于这个例子来说就是让第一台以后只能产生奇数。机器多的时候要扩容十分复杂。
- ID没有了单调递增的特性，只能趋势递增，这个缺点对于一般业务需求不是很重要，可以容忍。
- 数据库压力还是很大，每次获取ID都得读写一次数据库，只能靠堆机器来提高性能。


## 四、美团的Leaf-segment数据库方案

Leaf-segment 在使用数据库的方案上做了优化，利用proxy server批量获取，每次获取一段IDs(step决定大小)，然后把这段IDs作为id池缓存起来使用。用完之后再去数据库获取新的号段，从而大大的减轻数据库的压力。解决了原方案每次获取ID都得读写一次数据库，造成数据库压力大的问题。Leaf-segment的总体架构如下：

![](/images/2018072303.png)


这种模式有以下优缺点：

**优点：**

- Leaf服务可以很方便的线性扩展，性能完全能够支撑大多数业务场景。
- ID号码是趋势递增的8byte的64位数字，满足上述数据库存储的主键要求。
- 容灾性高：Leaf服务内部有号段缓存，即使DB宕机，短时间内Leaf仍能正常对外提供服务。
- 可以自定义max_id的大小，非常方便业务从原有的ID方式上迁移过来。

**缺点：**

- ID号码不够随机，能够泄露发号数量的信息，不太安全。
- TP999数据波动大，当号段使用完之后还是会hang在更新数据库的I/O上，tg999数据会出现偶尔的尖刺。
- DB宕机会造成整个系统不可用。

Leaf-segment 后2点缺点，Leaf-segment做了双buffer优化，以及“一主两从”的高可用容灾。

## 五、美团的Leaf-snowflake方案

Leaf-segment方案可以生成趋势递增的ID，同时ID号是可计算的，不适用于订单ID等生成场景，比如竞对在两天中午12点分别下单，通过订单id号相减就能大致计算出公司一天的订单量，这个是非常可怕的。针对这一问题，美团点评提供了 Leaf-snowflake 方案，用于满足对这种安全性有要求的场景。

![](/images/2018072304.png)

Leaf-snowflake方案完全沿用snowflake方案的bit位设计，即是“1+41+10+12”的方式组装ID号。相比 snowflake，Leaf-snowflake做了以下2点优化：

1. 使用Zookeeper持久顺序节点的特性自动对snowflake节点配置wokerID，一定程度的提高系统的伸缩性和容错性。
2. 解决时钟回拨会可能导致生成重复的ID号的问题。

Leaf-snowflake 的架构图如下：

![](/images/2018072305.png)


**Leaf-snowflake是按照下面几个步骤启动的：**

1. 启动Leaf-snowflake服务，连接Zookeeper，在leaf_forever父节点下检查自己是否已经注册过（是否有该顺序子节点）。
2. 如果有注册过直接取回自己的workerID（zk顺序节点生成的int类型ID号），启动服务。
3. 如果没有注册过，就在该父节点下面创建一个持久顺序节点，创建成功后取回顺序号当做自己的workerID号，启动服务。



## 六、微信的序列号生成器seqsvr

seqsvr 是微信的一个高可用、高可靠的序列号生成器，利用生成的序列号，实现终端与后台的数据增量同步机制。这套同步机制仍然在消息收发、朋友圈通知、好友数据更新等需要数据同步的地方发挥着核心的作用。seqsvr的架构可以分为两层，即StoreSvr和AllocSvr（存储层和缓存中间层）。


架构图如下：

![](/images/2018072306.png)


seqsvr 的设计考虑有其殊性，比如按用户id进行切分。但是其实现还有一些容灾设计事非常值得参考的。

具体细节及演进过程可看 [http://www.infoq.com/cn/articles/wechat-serial-number-generator-architecture/](http://www.infoq.com/cn/articles/wechat-serial-number-generator-architecture/)


## 七、参考文献

[1] [Twitter snowflake](https://github.com/twitter/snowflake)

[2] [Leaf——美团点评分布式ID生成系统](https://tech.meituan.com/MT_Leaf.html)

[3] [微信序列号生成器架构设计及演变](http://www.infoq.com/cn/articles/wechat-serial-number-generator-architecture/)