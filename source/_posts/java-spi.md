---
title: Java SPI 机制
tags:
  - 进阶实战
  - Java SPI
date: 2019-08-24 12:37:56
---

## [](#SPI-可以用来做什么 "# SPI 可以用来做什么")# SPI 可以用来做什么

在设计一个框架或者组件，甚至是项目中的某些模块时，经常都需要考虑扩展性， 而扩展性好应该符合以下两点：

1.  作为框架的维护者，在添加一个新功能时，只需要添加一些新代码，而不用大量的修改现有的代码，即符合开闭原则。
2.  作为框架的使用者，在添加一个新功能时，不需要去修改框架的源码，在自己的工程中添加代码或者修改配置即可。

而 Java SPI 可以很好的满足以上两点，从而达到良好的扩展性。

Java SPI(Service Provider Interface)是 JDK 内置的一种动态加载扩展点的实现，是一种“基于接口的编程＋策略模式＋配置文件”组合实现的动态加载机制。对扩展性支持非常友好，想要扩展实现，新只需要增实现接口，然后把接口的实现描述给JDK就行了。
<!--more-->
（大致原理就是：在ClassPath的META-INF/services目录下放置一个与接口同名的文本文件，文件的内容为接口的实现类，多个实现类用换行符分隔。JDK中使用 java.util.ServiceLoader 来加载具体的实现。）


![](/images/2019082401.png)

### [](#使用场景 "使用场景")使用场景

概括地说，适用于：调用者根据实际使用需要，启用、扩展、或者替换框架的实现策略。比较常见的例子：

1.  JDBC自动加载不同类型的数据库驱动， mysql-connector-java-xxx.jar

2.  日志门面接口实现类加载，SLF4J加载不同提供商的日志实现类

3.  Dubbo中在Java SPI 的基础上做了加强， 实现了根据方法参数或者配置来决定该使用哪个扩展。比如LoadBalance 做到了根据调用者参数的指定来应用不同的负债均衡策略。

## [](#如何实现一个自定义-SPI "# 如何实现一个自定义 SPI")# 如何实现一个自定义 SPI

这里由于现实情况不同厂商的实现肯定是分开的，所以不同厂商我是建了不同的 maven-modules， 目录结果如下：

![](/images/2019082402.png)

### [](#1-定义一个接口IRepository用于实现数据储存-类似于强制制定了一种规范，你们不同的数据厂商可以有不同的实现，但是必须按照我这个标准接口来 "1\. 定义一个接口IRepository用于实现数据储存 (类似于强制制定了一种规范，你们不同的数据厂商可以有不同的实现，但是必须按照我这个标准接口来)")1\. 定义一个接口IRepository用于实现数据储存 (类似于强制制定了一种规范，你们不同的数据厂商可以有不同的实现，但是必须按照我这个标准接口来)
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
<span class="line">8</span>
<span class="line">9</span>
</pre></td><td class="code"><pre><span class="line"></span>
<span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">interface</span> <span class="title">IRepository</span> </span>&#123;</span>
<span class="line">    <span class="comment">/**</span></span>
<span class="line"><span class="comment">     * 建立连接</span></span>
<span class="line"><span class="comment">     * <span class="doctag">@param</span> url</span></span>
<span class="line"><span class="comment">     */</span></span>
<span class="line">    <span class="function"><span class="keyword">void</span> <span class="title">connect</span><span class="params">(String url)</span></span>;</span>
<span class="line">&#125;</span>
<span class="line"></span>
</pre></td></tr></table></figure>

### [](#2-不同厂商分别提供了自己不同的实现，MysqlRepository、OracleRepository、MongoRepository "2\. 不同厂商分别提供了自己不同的实现，MysqlRepository、OracleRepository、MongoRepository")2\. 不同厂商分别提供了自己不同的实现，MysqlRepository、OracleRepository、MongoRepository

 MysqlRepository 实现：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">MysqlRepository</span> <span class="keyword">implements</span> <span class="title">IRepository</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">connect</span><span class="params">(String url)</span> </span>&#123;</span>
<span class="line">        System.out.println(<span class="string">"connect "</span> + url + <span class="string">" to Mysql"</span>);</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

在 Resources 下新建一个 META-INF/services/com.crazyfzw.spi.api.IRepository 文件， 内容为：
<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
</pre></td><td class="code"><pre><span class="line">com.crazyfzw.spi.apiimpl.mysql.MysqlRepository</span>
</pre></td></tr></table></figure>

OracleRepository 实现：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">OracleRepository</span> <span class="keyword">implements</span> <span class="title">IRepository</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">connect</span><span class="params">(String url)</span> </span>&#123;</span>
<span class="line">        System.out.println(<span class="string">"connect "</span> + url + <span class="string">" to Oracle"</span>);</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

在 Resources 下新建一个 META-INF/services/com.crazyfzw.spi.api.IRepository 文件， 内容为：
<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
</pre></td><td class="code"><pre><span class="line">com.crazyfzw.spi.apiimpl.oracle.OracleRepository</span>
</pre></td></tr></table></figure>

MongoRepository 实现：
<figure class="highlight java"><table><tr><td class="gutter"><pre><span class="line">1</span>
<span class="line">2</span>
<span class="line">3</span>
<span class="line">4</span>
<span class="line">5</span>
<span class="line">6</span>
<span class="line">7</span>
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">MongoRepository</span> <span class="keyword">implements</span> <span class="title">IRepository</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="meta">@Override</span></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">void</span> <span class="title">connect</span><span class="params">(String url)</span> </span>&#123;</span>
<span class="line">        System.out.println(<span class="string">"connect "</span> + url + <span class="string">" to Mongo"</span>);</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

在 Resources 下新建一个 META-INF/services/com.crazyfzw.spi.api.IRepository 文件， 内容为：
<figure class="highlight plain"><table><tr><td class="gutter"><pre><span class="line">1</span>
</pre></td><td class="code"><pre><span class="line">com.crazyfzw.spi.apiimpl.oracle.OracleRepository</span>
</pre></td></tr></table></figure>

### [](#3-在应用的pom-文件中根据需要选择引入不同厂商的maven-依赖-（通过切换pom引入可以实现不同厂商的切换） "3\. 在应用的pom 文件中根据需要选择引入不同厂商的maven 依赖 （通过切换pom引入可以实现不同厂商的切换）")3\. 在应用的pom 文件中根据需要选择引入不同厂商的maven 依赖 （通过切换pom引入可以实现不同厂商的切换）

这里是invoker-test 模块的pom：
<figure class="highlight xml"><table><tr><td class="gutter"><pre><span class="line">1</span>
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
</pre></td><td class="code"><pre><span class="line"><span class="tag">&lt;<span class="name">dependencies</span>&gt;</span></span>
<span class="line">    <span class="tag">&lt;<span class="name">dependency</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">groupId</span>&gt;</span>com.crazyfzw<span class="tag">&lt;/<span class="name">groupId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">artifactId</span>&gt;</span>interface-standard<span class="tag">&lt;/<span class="name">artifactId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">version</span>&gt;</span>1.0-SNAPSHOT<span class="tag">&lt;/<span class="name">version</span>&gt;</span></span>
<span class="line">    <span class="tag">&lt;/<span class="name">dependency</span>&gt;</span></span>
<span class="line"></span>
<span class="line">    <span class="tag">&lt;<span class="name">dependency</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">groupId</span>&gt;</span>com.crazyfzw<span class="tag">&lt;/<span class="name">groupId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">artifactId</span>&gt;</span>mysql-repository<span class="tag">&lt;/<span class="name">artifactId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">version</span>&gt;</span>1.0-SNAPSHOT<span class="tag">&lt;/<span class="name">version</span>&gt;</span></span>
<span class="line">    <span class="tag">&lt;/<span class="name">dependency</span>&gt;</span></span>
<span class="line"></span>
<span class="line">    <span class="tag">&lt;<span class="name">dependency</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">groupId</span>&gt;</span>com.crazyfzw<span class="tag">&lt;/<span class="name">groupId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">artifactId</span>&gt;</span>oracle-repository<span class="tag">&lt;/<span class="name">artifactId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">version</span>&gt;</span>1.0-SNAPSHOT<span class="tag">&lt;/<span class="name">version</span>&gt;</span></span>
<span class="line">    <span class="tag">&lt;/<span class="name">dependency</span>&gt;</span></span>
<span class="line"></span>
<span class="line">    <span class="tag">&lt;<span class="name">dependency</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">groupId</span>&gt;</span>com.crazyfzw<span class="tag">&lt;/<span class="name">groupId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">artifactId</span>&gt;</span>mongo-repository<span class="tag">&lt;/<span class="name">artifactId</span>&gt;</span></span>
<span class="line">        <span class="tag">&lt;<span class="name">version</span>&gt;</span>1.0-SNAPSHOT<span class="tag">&lt;/<span class="name">version</span>&gt;</span></span>
<span class="line">    <span class="tag">&lt;/<span class="name">dependency</span>&gt;</span></span>
<span class="line"><span class="tag">&lt;/<span class="name">dependencies</span>&gt;</span></span>
</pre></td></tr></table></figure>

### [](#4-在主调用类中通过-通过ServiceLoader加载IRepository-的实现 "4\. 在主调用类中通过 通过ServiceLoader加载IRepository 的实现")4\. 在主调用类中通过 通过ServiceLoader加载IRepository 的实现
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
</pre></td><td class="code"><pre><span class="line"><span class="keyword">public</span> <span class="class"><span class="keyword">class</span> <span class="title">MainTest</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">    <span class="function"><span class="keyword">public</span> <span class="keyword">static</span> <span class="keyword">void</span> <span class="title">main</span><span class="params">(String[] args)</span> </span>&#123;</span>
<span class="line"></span>
<span class="line">        ServiceLoader&lt;IRepository&gt; serviceLoader = ServiceLoader.load(IRepository.class);</span>
<span class="line"></span>
<span class="line">        Iterator&lt;IRepository&gt; it = serviceLoader.iterator();</span>
<span class="line">        <span class="keyword">while</span> (it != <span class="keyword">null</span> &amp;&amp; it.hasNext())&#123;</span>
<span class="line">            IRepository repositoryService = it.next();</span>
<span class="line">            System.out.println(<span class="string">"class:"</span> + repositoryService.getClass().getName());</span>
<span class="line">            repositoryService.connect(<span class="string">"172.0.0.1:3306"</span>);</span>
<span class="line">        &#125;</span>
<span class="line">    &#125;</span>
<span class="line">&#125;</span>
</pre></td></tr></table></figure>

运行效果图如下：

![](/images/2019082403.png)

**调用主类无需修改代码，只需通过修改pom引入不同的依赖，就可以选择切换不同的实现。**

## [](#SPI-的优缺点 "# SPI 的优缺点")# SPI 的优缺点

### [](#优点： "优点：")优点：

1.  Java SPI的使用很简单。也做到了基本的加载扩展点的功能，可以使业务代码和组件代码脱耦，启用替换可插拔
2.  拓展性好，在不修改原来代码的基础上，通过添加代码就可以拓展新的能力
3.  切换扩展点的实现，只需要在配置文件中修改具体的实现，不需要改代码。使用方便

### [](#不足： "不足：")不足：

1.  需要遍历所有的实现，并实例化，然后我们在循环中才能找到我们需要的实现。
2.  不提供类似于Spring的IOC和AOP功能，扩展如果依赖其他的扩展，做不到自动注入和装配

针对这些问题， Dubbo在原生  Java SPI 的基础上做了一些拓展。 可见参考文献[3][4]。

**本文涉及的spi-demo源码地址： **
[https://github.com/crazyfzw/spi-demo.git](https://github.com/crazyfzw/spi-demo.git)

## [](#参考文献 "# 参考文献")# 参考文献

[1][JAVA拾遗–关于SPI机制](https://www.cnkirito.moe/spi/)

[2][JDBC实现及 DriverManager 源码解析](https://cxis.me/2017/04/17/Java%E4%B8%ADSPI%E6%9C%BA%E5%88%B6%E6%B7%B1%E5%85%A5%E5%8F%8A%E6%BA%90%E7%A0%81%E8%A7%A3%E6%9E%90/)

[3][Dubbo可扩展机制实战](http://dubbo.apache.org/zh-cn/blog/introduction-to-dubbo-spi.html)

[4][Dubbo可扩展机制源码解析](http://dubbo.apache.org/zh-cn/blog/introduction-to-dubbo-spi-2.html)