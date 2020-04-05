---
title: Dubbo篇之(一)：实现原理及架构详解
date: 2018-06-10 12:10:14
categories:
- Dubbo
tags:
- Dubbo
- Dubbo实现原理
- Dubbo架构
- Microkernel + Plugin
---


## 一、Dubbo 的由来及解决的问题

随着互联网的发展，市场需求快速变更，业务持续高速增长，网站早已从单一应用架构演变为分布式服务架构及流动计算架构。

![](/images/2018061001.png)
<!--more-->


业界出现了一些比较流行的 RPC 框架，如 Apache Thrift、Hessian、gRPC 等。但是随着 RPC 框架的推广和使用的日益深入，服务越来越多,当服务越来越多，容量的评估，小服务资源的浪费等问题逐渐显现，此时衍生出一些新的需求：

**1. 依赖管理：**当服务越来越多时，服务URL配置管理变得非常困难，F5 硬件负载均衡器的单点压力也越来越大，此时需要一个服务注册中心来管理服务的依赖关系，并通过在消费方获取服务提供方地址列表，实现软负载均衡和 Failover，降低对 F5 硬件负载均衡器的依赖，也能减少部分成本。

**2. 透明路由：**通过订阅发布机制，消费只需要关系服务本身，并不需要配置具体的服务提供地址，实现服务的自动发现。动态的注册和发现服务，使服务的位置透明。

**3. 服务治理：** 业务失败之后的放通处理，超时时间控制、流程等常用的因为功能，希望能够独立出一个服务治理中心，统一对集群各节点的服务做在线治理，提升治理效率.

**为了解决以上问题，Dubbo 应运而上，Dubbo 除了 RPC 功能,还提供了丰富的服务治理功能。**

**1. 透明化的远程方法调用，**底层封装了 Java NIO 通信框架 Netty、序列化及反序列化框架、以及应用层提供线程池和消息调度，使业务可以快速的实现跨进程的远程通信，就像调用本地服务那样去调用远程服务，而不需要关系底层的通信细节，例如链路的闪断、失败重试等，极大的提高了应用的开发效率。

**2. 软负载均衡及容错机制，**可以在内网替代 F5 等硬件负载均衡器，降低成本，减少单点。

**3. 服务自动注册与发现，**基于服务注册中心的订阅发布机制，不再需要写死服务提供方地址，注册中心基于接口名查询服务提供者的ip地址，并且能够平滑添加或删除服务提供者。 

**4. 服务治理，**包括服务注册、服务降级、访问控制、动态配置路由规则、权重调节、负载均衡。

**5. Spring 框架无缝集成、**配置化发布服务。



## 二、Dubbo 的工作原理


![](/images/2018061002.png)


### 1) 节点说明：

Provider：暴露服务的服务提供方
Consumer：调用远程服务的服务消费方
Registry：服务注册与发现的注册中心
Monitor： 统计服务的调用次数和调用时间的监控中心
Container：服务运行容器


### 2) 调用过程及工作原理：

**0.** 服务容器负责启动，加载，运行服务提供者，通过 main 函数初始化 Spring 上下文，根据服务提供者配置的XML文件将服务按照指定的协议发布，完成服务化的初始化工作。。

**1.** 服务提供者在启动时，根据配置的服务注册中心地址连接服务注册中心，将服务提供者信息发布到注册中心，向注册中心注册自己提供的服务。


**2.** 服务消费者在启动时，消费者根据服务消费者XML配置文件的服务引用信息，连接到注册中心，向注册中心订阅自己所需的服务。

**3.** 服务注册中心根据服务订阅的关系，返回服务提供者地址列表给消费者，如果有变更，注册中心将基于长连接推送最新的服务地址信息给消费者。

**4.** 服务消费者调用远程服务时，根据路由策略，从本地缓存的服务提供者地址列表中选择选一台提供者进行，然后根据协议类型建立链路，跨进程调用服务提供者，如果调用失败，再选另一台调用。

**5.** 服务消费者和提供者，在内存中累计调用次数和调用时间，定时每分钟发送一次统计数据到监控中心。


## 三、Dubbo 的实现原理(基本设计原则)

**1.** 为了保持极强的扩展性，Dubbo 一开始就使用 Microkernel + Plugin （微核心+插件）的设计模式，Microkernel 只负责组装 Plugin，Dubbo 通过利用并改进JDK 标准的 SPI (Service Provider Interface) 扩展点发现机制实现自身的大部分功能(除 Service 和 Config 层为API)。采用 URL 作为配置信息的统一格式，所有扩展点都通过传递 URL 携带配置信息，基于扩展点自适应机制，根据URL中的配置信息，在链的最后一节调用真实的引用，所以Dubbo天生就具有极强的灵活的拓展性。

**2.** 从服务模型的角度来看，Dubbo 采用的是一种非常简单的模型，要么是提供方提供服务，要么是消费方消费服务，所以基于这一点可以抽象出服务提供方（Provider）和服务消费方（Consumer）两个角色。


## 四、Dubbo 的架构与设计

Dubbo 最大的特点是按照分层的方式来架构，将整个框架分为10层，使用这种方式可以使各个层之间解耦合（或者最大限度地松耦合）。

整体分层设计：

![](/images/2018061003.png)

Dubbo框架设计一共划分了10个层，各层均为单向依赖，右边的黑色箭头代表层之间的依赖关系，每一层都可以剥离上层被复用，其中，Service 和 Config 层为 API，其它各层均为 SPI；最上面的 Service 层是留给实际想要使用 Dubbo 开发分布式服务的开发者实现业务逻辑的接口层；图中左边淡蓝背景的为服务消费方使用的接口，右边淡绿色背景的为服务提供方使用的接口， 位于中轴线上的为双方都用到的接口。

  1. 服务接口层（Service）：该层是与实际业务逻辑相关的，根据服务提供方和服务消费方的业务设计对应的接口和实现。

  2. 配置层（Config）：对外配置接口，以 ServiceConfig 和 ReferenceConfig 为中心，可以直接 new 配置类，也可以通过 spring 解析配置生成配置类。

  3. 服务代理层（Proxy）：服务接口透明代理，生成服务的客户端 Stub 和服务器端 Skeleton，以 ServiceProxy 为中心，扩展接口为 ProxyFactory。

  4. 服务注册层（Registry）：封装服务地址的注册与发现，以服务URL为中心，扩展接口为 RegistryFactory、Registry 和 RegistryService。可能没有服务注册中心，此时服务提供方直接暴露服务。

  5. 集群层（Cluster）：封装多个提供者的路由及负载均衡，并桥接注册中心，以Invoker为中心，扩展接口为 Cluster、Directory、Router 和 LoadBalance。将多个服务提供方组合为一个服务提供方，实现对服务消费方来透明，只需要与一个服务提供方进行交互。

  6. 监控层（Monitor）：RPC 调用次数和调用时间监控，以 Statistics 为中心，扩展接口为 MonitorFactory、Monitor 和 MonitorService。

  7. 远程调用层（Protocol）：封将 RPC 调用，以 Invocation 和 Result 为中心，扩展接口为 Protocol、Invoker 和 Exporter。Protocol 是服务域，它是 Invoker 暴露和引用的主功能入口，它负责 Invoker  的生命周期管理。Invoker 是实体域，它是 Dubbo 的核心模型，其它模型都向它靠扰，或转换成它，它代表一个可执行体，可向它发起 invoke 调用，它有可能是一个本地的实现，也可能是一个远程的实现，也可能一个集群实现。

  8. 信息交换层（Exchange）：封装请求响应模式，同步转异步，以 Request 和 Response 为中心，扩展接口为 Exchanger、ExchangeChannel、ExchangeClient 和 ExchangeServer。

  9. 网络传输层（Transport）：抽象 mina 和 netty 为统一接口，以 Message 为中心，扩展接口为 Channel、Transporter、Client、Server 和 Codec。

  10. 数据序列化层（Serialize）：可复用的一些工具，扩展接口为 Serialization、 ObjectInput、ObjectOutput和ThreadPool。


从上图可以看出，Dubbo 对于服务提供方和服务消费方，从框架的10层中分别提供了各自需要关心和扩展的接口。根据官方提供的，对于上述各层之间关系的描述，如下所示：

  ● 在 RPC 中，Protocol 是核心层，也就是只要有 Protocol + Invoker + Exporter 就可以完成非透明的 RPC 调用，然后在 Invoker 的主过程上 Filter 拦截点。

  ● 图中的 Consumer 和 Provider 是抽象概念，只是想让看图者更直观的了解哪些类分属于客户端与服务器端，不用 Client 和 Server 的原因是 Dubbo 在很多场景下都使用 Provider, Consumer, Registry, Monitor 划分逻辑拓普节点，保持统一概念。

  ● 而 Cluster 是外围概念，所以 Cluster 的目的是将多个 Invoker 伪装成一个 Invoker，这样其它人只要关注 Protocol 层 Invoker 即可，加上 Cluster 或者去掉 Cluster 对其它层都不会造成影响，因为只有一个提供者时，是不需要 Cluster 的。

  ● Proxy 层封装了所有接口的透明化代理，而在其它层都以 Invoker 为中心，只有到了暴露给用户使用时，才用 Proxy 将 Invoker 转成接口，或将接口实现转成 Invoker，也就是去掉 Proxy 层 RPC 是可以 Run 的，只是不那么透明，不那么看起来像调本地服务一样调远程服务。

  ● 而 Remoting 实现是 Dubbo 协议的实现，如果你选择 RMI 协议，整个 Remoting 都不会用上，Remoting 内部再划为 Transport 传输层和 Exchange 信息交换层，Transport 层只负责单向消息传输，是对 Mina, Netty, Grizzly 的抽象，它也可以扩展 UDP 传输，而 Exchange 层是在传输层之上封装了 Request-Response 语义。

  ● Registry 和 Monitor 实际上不算一层，而是一个独立的节点，只是为了全局概览，用层的方式画在一起。


## 五、Dubbo的缺点

对语言的支持不友好，只支持JAVA语言。




## 六、参考文献
[dubbo-user-book](http://dubbo.apache.org/books/dubbo-user-book/)
[dubbo-dev-book](http://dubbo.apache.org/books/dubbo-dev-book/)
[Dubbo架构设计详解](http://shiyanjun.cn/archives/325.html)
[阿里中间件团队博客-Dubbo分类](http://jm.taobao.org/categories/Dubbo/)
