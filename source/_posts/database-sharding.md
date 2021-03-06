---
title: 数据存储 3：分库与分表
date: 2018-07-29 21:14:31
categories:
- RDBMS
tags:
- 分库分表
- 垂直分库
- 水平分表
- 垂直拆分
- RDBMS
---

## 一、分库与分表是为了解决什么问题（目的）

随着业务的增长，表数据的增加，查询一次所消耗的时间会变得越来越长，甚至会造成数据库的单点压力。当数据库已经成为系统性能的瓶颈，这时，通过分库分表，可以减小数据库的单库单表负担，提高查询性能，缩短查询时间，从而提升系统的响应速度。
<!--more-->


## 二、分库分表方案应该尽量避免的两个问题
1. 数据迁移
2. 热点数据

## 三、垂直拆分

### 垂直分库
垂直分库在“微服务”盛行的今天已经非常普及了。基本的思路就是按照业务模块以及表的相关性来划分出不同的数据库，而不是像早期一样将所有的数据表都放到同一个数据库中。

比如以一个订单系统吧为例：一个数据库里面既存在用户数据，又存在订单数据，那么垂直拆分可以把用户数据放到用户库、把订单数据放到订单库。如下图：

![](/images/2018073001.png)


**小结：**

数据库的 CPU、内存、磁盘 IO 、连接资源、网络带宽都是有限的，所以单个物理机上容易出现资源竞争和性能瓶颈。通过垂直分库，一方面，可以解决数据库单点压力过大的问题，在高并发场景下，垂直分库一定程度上能够突破IO、连接数及单机硬件资源的瓶颈。另一方面，数据库层面的拆分们也有利于我们针对不同业务类型的数据进行“分级”管理、维护、监控、扩展等。因此，垂直分库是大型分布式系统中优化数据库架构的重要手段。


### 垂直分表

垂直分表在日常开发和设计中比较常见。垂直拆分，其实就是“大表拆小表”，把表的列字段进行拆分，即一张字段比较多的表拆分为多张表，这样使得行数据变小。一方面，可以减少客户端程序和数据库之间的网络传输的字节数，因为生产环境共享同一个网络带宽，随着并发查询的增多，有可能造成带宽瓶颈从而造成阻塞。另一方面，一个数据块能存放更多的数据，在查询时就会减少 I/O 次数。

通常就是建立“扩展表”，将不经常使用或者长度较大的字段拆分出去放到“扩展表”中，如下图所示：

![](/images/2018073002.png)


**拆分策略：**

1. 将不常用的字段单独拆分到另外一张扩展表，例如前面讲解到的用户家庭地址，这个字段是可选字段，在数据库操作的时候除了个人信息外，并不需要经常读取或是更改这个字段的值。

2. 将大文本的字段单独拆分到另外一张扩展表，例如 BLOB 和 TEXT 字符串类型的字段，以及 TINYBLOB、 MEDIUMBLOB、 LONGBLOB、 TINYTEXT、 MEDIUMTEXT、 LONGTEXT字符串类型。这样可以减少客户端程序和数据库之间的网络传输的字节数。

3. 将不经常修改的字段放在同一张表中，将经常改变的字段放在另一张表中。举个例子，假设用户表的设计中，还存在“最后登录时间”字段，每次用户登录时会被更新。这张用户表会存在频繁的更新操作，此外，每次更新时会导致该表的查询缓存被清空。所以，可以把这个字段放到另一个表中，这样查询缓存会增加很多性能。对于需要经常关联查询的字段，建议放在同一张表中。不然在联合查询的情况下，会带来数据库额外压力。

**小结：**

拆分字段的操作应该在数据库表设计阶段就做好。尽量避免在发展过程中做垂直分表，因为做字段拆分后，需要改以前的映射实体以及查询语句，会额外带来一定的成本和风险。


## 四、水平拆分

垂直拆分只是解决了单库压力的问题。依然可能存在单表数据量过大影响查询性能的问题。若确实存在，则这时就应该考虑水平拆分。

水平分表也称为横向分表，是一种把单表按某个规则把数据分散到多个表的拆分方式，以此来降低单表数据量，优化查询性能。最常见的方式就是通过主键或者时间等字段进行Hash和取模后拆分。


如下图所示：比如：把单表1亿数据按某个规则拆分，分别存储到10个相同结果的表，每个表的数据是1千万，拆分出来的表，可以综合实际情况考虑是放在同一个库中，还是分别放至到不同数据库中，即同时进行水平拆库操作，如下图所示：

![](/images/2018073003.png)


**水平分表策略**

常见的水平分表策略归纳起来，可以总结为随机分表和连续分表两种情况。例如，取模切分、Hash切分就属于随机分表，而按时间维度切分、ID 范围切分则属于连续分表。

### 连续切分（范围切分）
连续分表可以快速定位到表进行高效查询，大多数情况下，可以有效避免跨表查询。如果想扩展，只需要添加额外的分表就可以了，无需对其他分表的数据进行数据迁移。但是，连续分表有可能存在数据热点的问题，有些表可能会被频繁地查询从而造成较大压力，热数据的表就成为了整个库的瓶颈，而有些表可能存的是历史数据，很少需要被查询到。

比如按照时间区间或ID区间来切分：

![](/images/2018073004.png)


优点：单表大小可控，天然水平扩展。
缺点：无法解决集中写入瓶颈的问题，可能存在热点数据问题。


### 随机切分（Hash切分、取模切分）
随机分表是遵循规则策略进行写入与读取，而不是真正意义上的随机。通常，采用取模分表或者自定义 Hash 分表的方式进行水平拆分。随机分表的数据相对比较均匀，不容易出现热点和并发访问的瓶颈。但是，分表扩展需要迁移旧的数据。此外，随机分表比较容易面临跨表查询的复杂问题。

比如以下取模切分：

![](/images/2018073005.png)


后面这里需要再结合案例展开详细写。


优点：不存在热点数据问题，不存在几种写入瓶颈问题。
缺点：再次扩展难度增大，需要迁移旧数据。


**小结：**

水平分表，能够降低单表的数据量，一定程度上可以缓解查询性能瓶颈。但本质上这些表还保存在同一个库中，所以库级别还是会有IO瓶颈。所以，通常做法是把拆分后的表放到不同的库中。但这也涉及一个成本问题，需要综合考虑实际的访问量、并发数、未来可预见的一段时间的业务增长量、以及成本。

水平拆分可以降低单表数据量，让每个单表的数据量保持在一定范围内，从而提升单表读写性能。但水平拆分后，同一业务数据分布在不同的表或库中，可能需要把单表事务改成跨表事务，需要转变数据统计方式等。


## 五、垂直水平拆分混合

垂直水平拆分，是综合了垂直和水平拆分方式的一种混合方式。首先，按业务及表的相关性垂直分库（垂直切分），划分出不同的库，然后再挑选出数据量大、增长迅猛的表进行水平分表（水平切分）。

比如针对一个订单系统的垂直水平拆分如下：

![](/images/2018073006.png)


**小结：**

需要注意的是，水平拆分的表需要放到不同的数据库才能减少数据库的但点压力，但是考虑到成本和后期的管理维护问题，现实情况，往往不会弄单库单表的情况（除非真的必要）。

为了提示机器的利用率，在水平切分完成后可再进行一次“反向的Merge”,即：将业务上相近，并且具有相近数据增长速率（主表数据量在同一数量级上）的两个或多个分片放到同一个数据库上，在逻辑上它们依然是独立的分片，有各自的主表，并且提升了数据库服务器的利用率。

整个过程可以参考下图：

![](/images/2018073007.png)


## 六、分库分表实践案例

下面是唯品会以及美团点评对订单系统的分库分表，个人觉得比较有参考意义。具体详情可参考原文。

### 唯品会的订单分库分表实践总结以及关键步骤
原文地址：[唯品会的订单分库分表实践总结以及关键步骤](https://mp.weixin.qq.com/s?__biz=MzIwMzg1ODcwMw==&mid=2247486487&idx=1&sn=066c5c3366fe232776442f95024c4a1d&chksm=96c9ba77a1be3361cd42ca0bd1e0e55e63f95160c1517855470fffe8e3d8b2ade1e7323aaf3f&scene=27#wechat_redirect)

### 大众点评订单系统分库分表实践
原文地址：[大众点评订单系统分库分表实践](https://tech.meituan.com/dianping_order_db_sharding.html)

### 阿里一种可以避免数据迁移的分库分表scale-out扩容方式
文章地址：[一种可以避免数据迁移的分库分表scale-out扩容方式](https://blog.csdn.net/clypm/article/details/51722209)

<br/>
## 七、分库分表带来的问题以及对应的解决办法

### 1. 表关联问题（跨库 Join）

在单库单表的情况下，联合查询是非常容易的。但是，随着分库与分表的演变，联合查询就遇到跨库关联和跨表关系问题。数据库可能是分布式在不同实例和不同的主机上，join将变得非常麻烦。

基于架构规范，性能，安全性等方面考虑，一般是禁止跨库join的。所以，在设计及拆分阶段应尽量避免出现跨库Join（将那些存在关联关系的表记录存放在同一个分片上）。若开发过程中还是出现了需要跨库查询的场景，则可以通过在程序中进行拼装解决（二次查询或者通过RPC调用来得到关联的数据,然后再进行拼装）。


**下面，提供几种跨库J oin的解决思路：**


**ER分片**
在关系型数据库中，表之间往往存在一些关联的关系。如果我们可以先确定好关联关系，在设计或拆分阶将那些存在关联关系的表记录存放在同一个分片上，那么就能很好的避免跨分片 join 问题。

**通过全局表进行规避**

比如“数据字典表”，这种系统中的所有模块都可能会用到的表，这类数据通常也很少发生修改（甚至几乎不会），也不用太担心“一致性”问题。所以可以将这类表在每个数据库中均保存一份，以此来了避免跨库join查询。这种表，可以称之为全局表。


**通过反范式化设计进行规避**

可以通过个别字段的冗余来避免跨库join查询，这是一种典型的反范式设计。

举个电商业务中很简单的场景：

“订单表”中保存 “卖家Id” 的同时，将卖家的“Name”字段也冗余，这样查询订单详情的时候就不需要再去查询“卖家用户表”。单这也存在一个问题，比如卖家修改了Name之后，是否需要在订单信息中同步更新呢？

字段冗余能带来便利，是一种“空间换时间”的体现。但其适用场景也比较有限，比较适合依赖字段较少的情况。另一方面，这种方式存在数据一致性问题，如果业务对数据一致性强要求，那就需要通过额外的手段来保证（比如可以借助数据库中的触发器或者在业务代码层面去保证）。


**通过在系统层二次查询组装解决**

可以在程序中通过或者通过RPC调用来得到关联的数据，从而避免跨库join查询。需要特别注意的是，这里的二次查询或者通过RPC调用最好不要放在循环中去执行，否则效率会很低，甚至会严重影响系统的性能。

通常的做法是把循环调用改成一次调用，一次取出所有关联的数据，然后再进行组装。伪代码如下：
{% codeblock lang:java%}
	public QuestionResponse GetOrderList(HttpServletRequest request){
		
		QuestionResponse response = new QuestionResponse();
		
		/**
		 * 获取基本结构集
		 */
		List<Order> result =  orderServer.getOrderList();
		
		
		List<Long> productIds = new ArrayList<Long>();
		for (Order order : result) {			
			productIds.add(order.getProductId());			
		}
		
		/**
		 * 传入关联数据的ID集合，一次查询出所有关联数据
		 */
		List<Product> productList =  productServer.getOrderList(productIds);
		for (Order order : result) {			
			/**
			 * 匹配数据，并赋值		
			 */
		}
		
		response.setResult(result);
		
		return response;
		
	}
{% endcodeblock %}

**小结：**

简单字段组装的情况下，我们只需要先获取“主表”数据，然后再根据关联关系，调用其他模块的组件或服务来获取依赖的其他字段（如例中依赖的用户信息），最后将数据进行组装。

通常，我们都会通过缓存来避免频繁RPC通信和数据库查询的开销。

### 2. 分页与排序问题（limit、order by）

一般情况下，列表分页时需要按照指定字段进行排序。在单库单表的情况下，分页和排序也是非常容易的。但是，随着分库与分表的演变，也会遇到跨库排序和跨表排序问题。为了最终结果的准确性，需要在不同的分表中将数据进行排序并返回，并将不同分表返回的结果集进行汇总和再次排序，最后再返回给用户。

如下图所示取第一页数：

![](/images/2018073008.png)


上图中所描述的只是最简单的一种情况（取第一页数据），看起来对性能的影响并不大。但是，如果想取出第10页数据，情况又将变得复杂很多，如下图所示：

![](/images/2018073009.png)


那为什么不能像获取第一页数据那样简单处理（排序取出前10条再合并、排序）。其实并不难理解，因为各分片节点中的数据可能是随机的，为了排序的准确性，必须把所有分片节点的前N页数据都排序好后做合并，最后再进行整体的排序。很显然，这样的操作是比较消耗资源的，用户越往后翻页，系统性能将会越差（典型的大分页问题，比如搜索引擎结果页中，越往后翻响应越慢）。

### 3. 跨分片的函数处理(Count、Max、Min、Sum)

在使用Max、Min、Sum、Count之类的函数进行统计和计算的时候，需要先在每个分片数据源上执行相应的函数处理，然后再将各个结果集进行二次处理，最终再将处理结果返回。如下图所示：

![](/images/2018073010.png)

### 4. 分布式事务问题
按业务拆分数据库之后，不可避免的就是“分布式事务”的问题。以往在代码中通过spring注解简单配置就能实现事务，现在则需要花很大的成本去保证一致性。后面会单独写一篇文章展开讲。


### 5. 分布式全局唯一ID
[分布式系统全局唯一ID生成方案](https://crazyfzw.github.io/2018/07/21/%E6%95%B0%E6%8D%AE%E5%AD%98%E5%82%A8-2%EF%BC%9A%E5%88%86%E5%B8%83%E5%BC%8F%E7%B3%BB%E7%BB%9F%E5%85%A8%E5%B1%80%E5%94%AF%E4%B8%80ID%E7%94%9F%E6%88%90%E6%96%B9%E6%A1%88/#more)
   
## 八、如何考虑是否需要分库分表（我们的系统真的需要分库分表吗）

分库与分表主要用于应对当前互联网常见的两个场景：海量数据和高并发。但是分库分表同时也提高了系统的复杂度以及维护成本。分库与分表是一把双刃剑，因此，在项目一开始不采用分库与分表设计，而是随着业务的增长，在无法继续优化的情况下，再考虑通过分库与分表提高系统的性能。


一般表数据在1000W以内都不需要考虑分表。分库分表时应考虑尽可能考虑可预见的几年内业务的增长，对数据库服务器的QPS、连接数、容量等做合理评估和规划。

  
## 九、分库分表后如何迁移数据

对于数据迁移的问题，一般做法是通过程序先读出数据，然后按照指定的分表策略再将数据写入到各个分表中。

## 十、参考文献
[1] [大众点评订单系统分库分表实践](https://tech.meituan.com/dianping_order_db_sharding.html)

[2] [唯品会的订单分库分表实践总结以及关键步骤](https://mp.weixin.qq.com/s?__biz=MzIwMzg1ODcwMw==&mid=2247486487&idx=1&sn=066c5c3366fe232776442f95024c4a1d&chksm=96c9ba77a1be3361cd42ca0bd1e0e55e63f95160c1517855470fffe8e3d8b2ade1e7323aaf3f&scene=27#wechat_redirect)

[3] [分库分表的几种常见形式以及可能遇到的难题](https://mp.weixin.qq.com/s?__biz=MzIwMzg1ODcwMw==&mid=2247486426&idx=1&sn=20e965a30c59613b5b11e42e004d2445&chksm=96c9bdbaa1be34ac8d25637272287da249fe2cb804315e2fc73f87d770dd7a41fdb286fa114e&scene=27#wechat_redirect)

[4] [水平分库分表的关键步骤以及可能遇到的问题](https://mp.weixin.qq.com/s?__biz=MzIwMzg1ODcwMw==&mid=2247486422&idx=1&sn=f6dd2a02c96bc3467de83bb34c87fe64&chksm=96c9bdb6a1be34a0e5c218d4143a05d04404d1515a972b642c447967847c3dac58eb59f4742f&scene=27#wechat_redirect)

[5] [一种可以避免数据迁移的分库分表scale-out扩容方式](https://blog.csdn.net/clypm/article/details/51722209)

[6] [阿里巴巴分布式数据库服务DRDS研发历程](http://jm.taobao.org/%2F2017%2F01%2F19%2F20170119%2F)

[7] [阿里的分布式数据库DRDS](https://help.aliyun.com/product/29657.html?spm=a2c4g.11186623.6.540.43ee6b20kxutaK)

[8] [贝聊通过DRDS实现亿级数据库分库分表实践](https://juejin.im/post/5992b2f8f265da3e185eb75d)

[9] [分库与分表设计](http://blog.720ui.com/2017/mysql_core_08_multi_db_table/)
