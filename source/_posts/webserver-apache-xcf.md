---
title: 使用Apache CXF 实现Web Service
date: 2018-04-15 13:56:07
categories:
- WebService
tags:
- webservice
- CXF
- CXF 实现 webservice的发布与调用
- JaxWsProxyFactoryBean
---


## 一、基础概念
### 1、Web service的概念：
Web service是一个平台独立的，低耦合的，自包含的、基于可编程的web的应用程序，可使用开放的XML（标准通用标记语言下的一个子集）标准来描述、发布、发现、协调和配置这些应用程序，用于开发分布式的互操作的应用程序。Web Service技术， 能使得运行在不同机器上的不同应用无须借助附加的、专门的第三方软件或硬件， 就可相互交换数据或集成。依据Web Service规范实施的应用之间， 无论它们所使用的语言、 平台或内部协议是什么， 都可以相互交换数据。Web Service是自描述、 自包含的可用网络模块， 可以执行具体的业务功能。Web Service也很容易部署，Web Service为整个企业甚至多个组织之间的业务流程的集成提供了一个通用机制。

<!--more-->

### 2、Web Service有以下的优越性：
1）平台无关。不管你使用什么平台，都可以使用Web service。
2）编程语言无关。只要遵守相关协议，就可以使用任意编程语言，向其他网站要求Web service。这大大增加了web service的适用性，降低了对程序员的要求。
3）对于Webservice提供者来说，部署、升级和维护Web service都非常单纯，不需要考虑客户端兼容问题，而且一次性就能完成。
4）对于Webservice使用者来说，可以轻易实现多种数据、多种服务的聚合（mashup），因此能够做出一些以前根本无法想像的事情。


### 3、Apache CXF的概念
Apache CXF是Apache旗下一个重磅的SOA简易框架，CXF 继承了 Celtix 和 XFire 两大开源项目的精华，提供了多种Binding 、DataBinding、Transport 以及各种 Format 的支持，并且可以根据实际项目的需要，采用代码优先（Code First）或者 WSDL 优先（WSDL First）来轻松地实现 Web Services 的发布和使用。而且可以天然的和Spring进行无缝集成。(CXF不仅支持嵌入式代码中通过jetty发布WebService，也可以通过Web容器发布WebService。)


## 二、实现

### 1.服务提供方实现

#### 1) 引入jar
        可在http://cxf.apache.org/download.html 可在下载，也可以用maven引入



#### 2）实现接口类和实现类

{% codeblock lang:java%}
package cxfdemo;

import javax.jws.WebService;

@WebService
public interface CXFDemoService {
     public String sayHello(String foo);
}
{% endcodeblock %}



{% codeblock lang:java%}
package cxfdemo;
import javax.jws.WebService;

@WebService()
public class CXFDemoServiceImpl implements CXFDemoService {

    public String sayHello(String foo) {
        return "hello "+foo;
    }
}
{% endcodeblock %}


#### 3）通过 Web 容器发布 WebService

CXF提供了spring的集成，同时还提供了org.apache.cxf.transport.servlet.CXFServlet用于在web容器中发布WebService。 前面的例子中增加了整个apache-cxf的依赖，所以会自动增加对srping的引用。

##### 3.1)只需要写beans配置文件和web.xml文件即可。

{% codeblock lang:java%}
    <!-- CXF -->
  <servlet>      
        <servlet-name>CXFServlet</servlet-name>      
        <servlet-class>      
            org.apache.cxf.transport.servlet.CXFServlet       
        </servlet-class>      
        <load-on-startup>1</load-on-startup>      
    </servlet>      
    <servlet-mapping>      
        <servlet-name>CXFServlet</servlet-name>      
        <url-pattern>/webservice/*</url-pattern>      
    </servlet-mapping>

{% endcodeblock %}

**在web.xml中增加spring的ContextLoaderListener并配置context-param**

{% codeblock lang:xml%}
  <!-- 添加对spring的支持 -->
  <context-param>
    <param-name>contextConfigLocation</param-name>
    <param-value>/WEB-INF/classes/applicationContext*.xml</param-value>
  </context-param>

  <!--Spring ApplicationContext 载入 -->
  <listener>
    <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
  </listener>
{% endcodeblock %}

##### 3.2)添加bean配置文件   applicationContext-cxf.xml (自定义的名字)

{% codeblock lang:xml%}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:context="http://www.springframework.org/schema/context"
        xmlns:jaxws="http://cxf.apache.org/jaxws" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	 xsi:schemaLocation="   
	  http://www.springframework.org/schema/beans 
	  http://www.springframework.org/schema/beans/spring-beans.xsd   
	  http://www.springframework.org/schema/context 
	  http://www.springframework.org/schema/context/spring-context-4.0.xsd
	  http://cxf.apache.org/jaxws 
      http://cxf.apache.org/schemas/jaxws.xsd">
      
      <import resource="classpath:META-INF/cxf/cxf.xml"/>
      <import resource="classpath:META-INF/cxf/cxf-extension-soap.xml"/>
      <import resource="classpath:META-INF/cxf/cxf-servlet.xml"/>


	<jaxws:endpoint address="/CXFDemoService"
		implementor="#CXFDemoServiceImpl "
		serviceName="CXFDemoService" />
		
        <!--有多个可写一起-->
	<jaxws:endpoint address="/CXFDemoService2"
		implementor="#CXFDemoService2Impl "
		serviceName="CXFDemoService2" />
</beans>
{% endcodeblock %}


**启动Tomcat WebService就已经在web容器中发布了。**


### 2.使用CXF中JaxWsProxyFactoryBean客户端代理工厂调用web服务

{% codeblock lang:java%}
public static void main(String[] args) {  
        JaxWsProxyFactoryBean factoryBean = new JaxWsProxyFactoryBean();  
        factoryBean.setServiceClass(CXFDemoService.class);  
        //webService提供方的地址
        factoryBean.setAddress("http://localhost:8080/webservice/CXFDemoService"); 
        CXFDemoService cXFDemoService= (CXFDemoService)factoryBean.create();  
        String returnResult = cXFDemoService.sayHello(" webService");  
        System.out.println("调用结果:"+returnResult );  
} 
{% endcodeblock %}

参考文章
[http://cxshun.iteye.com/blog/1275408](http://cxshun.iteye.com/blog/1275408)
[https://blog.csdn.net/shb_derek1/article/details/8018287](https://blog.csdn.net/shb_derek1/article/details/8018287)