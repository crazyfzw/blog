---
title: Maven初识
date: 2017-01-25 12:06:00
categories:
- Maven
tags:
- maven
- pom.xml
- maven构建
---

## **一、概述**

Maven 的主要目的是为开发者提供
  ● 一个可复用、可维护、更易理解的工程综合模型
  ● 与这个模型交互的插件或者工具


Maven 能够帮助开发者完成以下工作：
  ● 构建
  ● 文档生成
  ● 报告
  ● 依赖
  ● SCMs
  ● 发布
  ● 分发
  ● 邮件列表


Maven 工程结构和内容被定义在一个 xml 文件中 － pom.xml，是 Project Object Model (POM) 的简称，此文件是整个 Maven 系统的基础组件

<!--more-->



## **二、安装**
http://wiki.jikexueyuan.com/project/maven/environment-setup.html




## **三、POM**
POM 代表工程对象模型。它是使用 Maven 工作时的基本组建，是一个 xml 文件。它被放在工程根目录下，文件命名为 pom.xml。POM 包含了关于工程和各种配置细节的信息，Maven 使用这些信息构建工程。


在创建 POM 之前，我们首先确定工程组（groupId），及其名称（artifactId）和版本，在仓库中这些属性是工程的唯一标识。这些可以在仓库repository中查看到相关信息

![这里写图片描述](http://img.blog.csdn.net/20170125110747398?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

下面以java EE的常见 pom.xml为例：

{% codeblock lang:xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>crazyfzw</groupId>
	<artifactId>springmvc-demo</artifactId>
	<version>1.0-SNAPSHOT</version>
	<packaging>war</packaging>
	<name>springmvc-demo</name>
	<description>springmvc-demo</description>


	<!-- 集中定义依赖版本号 -->
	<properties>
		<junit.version>4.10</junit.version>
		<spring.version>4.3.5.RELEASE</spring.version>
		<slf4j.version>1.6.4</slf4j.version>
		<log4j.version>1.2.17</log4j.version>
		<jackson.version>2.8.5</jackson.version>
		<mapper.version>2.3.4</mapper.version>
		<commons-lang3.version>3.3.2</commons-lang3.version>
		<commons-io.version>1.3.2</commons-io.version>
		<redis.version>2.9.0</redis.version>
		<spring-data-redis.version>1.7.5.RELEASE</spring-data-redis.version>
		<jxls-core.version>1.0.6</jxls-core.version>
		<poi.version>3.15</poi.version>
		<mchange-commons-java.version>0.2.12</mchange-commons-java.version>
		<hibernate.version>4.3.9.Final</hibernate.version>
		<quartz.version>2.2.3</quartz.version>
		<fastjson.version>1.2.22</fastjson.version>
		<jstl.version>1.2</jstl.version>
		<servlet-api.version>2.5</servlet-api.version>
		<jsp-api.version>2.0</jsp-api.version>
		<p6spy.version>2.1.4</p6spy.version>
	</properties>

	<dependencies>
		<!-- api -->
		<dependency>
			<groupId>com.alibaba</groupId>
			<artifactId>fastjson</artifactId>
			<version>${fastjson.version}</version>
		</dependency>

		<!-- 单元测试 -->
		<dependency>
			<groupId>junit</groupId>
			<artifactId>junit</artifactId>
			<version>${junit.version}</version>
			<scope>test</scope>
		</dependency>

		<!-- Spring -->
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-context</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-context-support</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-beans</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-webmvc</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-jdbc</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-aspects</artifactId>
			<version>${spring.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework</groupId>
			<artifactId>spring-orm</artifactId>
			<version>${spring.version}</version>
		</dependency>

		<!-- 日志 -->
		<dependency>
			<groupId>org.slf4j</groupId>
			<artifactId>slf4j-log4j12</artifactId>
			<version>${slf4j.version}</version>
		</dependency>

		<dependency>
		  <groupId>log4j</groupId>
		  <artifactId>log4j</artifactId>
		  <version>${log4j.version}</version>
		</dependency>
		<!-- Jackson Json处理工具包 -->
		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
			<artifactId>jackson-databind</artifactId>
			<version>${jackson.version}</version>
		</dependency>
		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
		    <artifactId>jackson-core</artifactId>
			<version>${jackson.version}</version>
		</dependency>
		<dependency>
			<groupId>net.sf.json-lib</groupId>
			<artifactId>json-lib</artifactId>
			<version>2.4</version>
			<classifier>jdk15</classifier>
		</dependency>
		<!-- 通用Mapper -->
		<dependency>
			<groupId>com.github.abel533</groupId>
			<artifactId>mapper</artifactId>
			<version>${mapper.version}</version>
		</dependency>

		<!-- apache-velocity -->
		<dependency>
			<groupId>org.apache.velocity</groupId>
			<artifactId>velocity</artifactId>
			<version>1.7</version>
		</dependency>

		<!--c3p0工具包 -->
		<dependency>
			<groupId>com.mchange</groupId>
			<artifactId>mchange-commons-java</artifactId>
			<version>${mchange-commons-java.version}</version>
		</dependency>


		<!-- Apache工具组件 -->
		<dependency>
			<groupId>org.apache.commons</groupId>
			<artifactId>commons-lang3</artifactId>
			<version>${commons-lang3.version}</version>
		</dependency>
		<dependency>
			<groupId>org.apache.commons</groupId>
			<artifactId>commons-io</artifactId>
			<version>${commons-io.version}</version>
		</dependency>
		<dependency>
			<groupId>commons-fileupload</groupId>
			<artifactId>commons-fileupload</artifactId>
			<version>1.3.1</version>
		</dependency>
		<dependency>
			<groupId>commons-dbcp</groupId>
			<artifactId>commons-dbcp</artifactId>
			<version>1.4</version>
		</dependency>
		<dependency>
			<groupId>commons-logging</groupId>
			<artifactId>commons-logging</artifactId>
			<version>1.1.1</version>
		</dependency>
		<dependency>
			<groupId>commons-beanutils</groupId>
			<artifactId>commons-beanutils</artifactId>
			<version>1.8.3</version>
		</dependency>
		<dependency>
			<groupId>commons-collections</groupId>
			<artifactId>commons-collections</artifactId>
			<version>3.2.1</version>
		</dependency>
		
		<!-- POI -->
		<dependency>
			<groupId>org.apache.poi</groupId>
			<artifactId>poi</artifactId>
			<version>${poi.version}</version>
		</dependency>

		<dependency>
			<groupId>org.apache.poi</groupId>
			<artifactId>poi-ooxml</artifactId>
			<version>${poi.version}</version>
		</dependency>

		<dependency>
			<groupId>org.apache.poi</groupId>
			<artifactId>poi-scratchpad</artifactId>
			<version>${poi.version}</version>
		</dependency>

		<!-- jslx -->
		<dependency>
			<groupId>net.sf.jxls</groupId>
			<artifactId>jxls-core</artifactId>
			<version>${jxls-core.version}</version>
		</dependency>
		
		<!-- jxl -->
		<dependency>
			<groupId>net.sourceforge.jexcelapi</groupId>
			<artifactId>jxl</artifactId>
			<version>2.6.12</version>
		</dependency>
		
		<!-- quartz -->
		<dependency>
			<groupId>org.quartz-scheduler</groupId>
			<artifactId>quartz</artifactId>
			<version>${quartz.version}</version>
		</dependency>
		<dependency>
			<groupId>opensymphony</groupId>
			<artifactId>quartz-all</artifactId>
			<version>1.6.1</version>
		</dependency>

		<!-- hibernate -->
		<dependency>
			<groupId>org.hibernate</groupId>
			<artifactId>hibernate-core</artifactId>
			<version>${hibernate.version}</version>
		</dependency>

		<!-- 连接池 -->
		<dependency>
			<groupId>p6spy</groupId>
			<artifactId>p6spy</artifactId>
			<version>${p6spy.version}</version>
		</dependency>
	
		<!-- ehcache -->
		<dependency>
			<groupId>net.sf.ehcache</groupId>
			<artifactId>ehcache-core</artifactId>
			<version>2.5.1</version>
		</dependency>
		<dependency>
			<groupId>com.oracle</groupId>
			<artifactId>ojdbc14</artifactId>
			<version>14.0.2.0.4.0</version>
		</dependency>

		<!-- redis -->
		<dependency>
			<groupId>redis.clients</groupId>
			<artifactId>jedis</artifactId>
			<version>${redis.version}</version>
		</dependency>
		<dependency>
			<groupId>org.springframework.data</groupId>
			<artifactId>spring-data-redis</artifactId>
			<version>${spring-data-redis.version}</version>
		</dependency>

		<!-- dubbox使用jar -->
		<dependency>
			<groupId>org.apache.zookeeper</groupId>
			<artifactId>zookeeper</artifactId>
			<version>3.4.6</version>
		</dependency>
		<dependency>
			<groupId>io.netty</groupId>
			<artifactId>netty</artifactId>
			<version>3.7.0.Final</version>
		</dependency>
		<dependency>
			<groupId>org.javassist</groupId>
			<artifactId>javassist</artifactId>
			<version>3.18.2-GA</version>
		</dependency>
		<dependency>
			<groupId>jline</groupId>
			<artifactId>jline</artifactId>
			<version>0.9.94</version>
		</dependency>
		<dependency>
			<groupId>com.101tec</groupId>
			<artifactId>zkclient</artifactId>
			<version>0.4</version>
		</dependency>
		<dependency>
			<groupId>com.alibaba</groupId>
			<artifactId>dubbo</artifactId>
			<version>2.8.4</version>
		</dependency>

		<!-- https://mvnrepository.com/artifact/joda-time/joda-time -->
		<dependency>
			<groupId>joda-time</groupId>
			<artifactId>joda-time</artifactId>
			<version>2.3</version>
		</dependency>
		
		<dependency>
			<groupId>jstl</groupId>
			<artifactId>jstl</artifactId>
			<version>${jstl.version}</version>
		</dependency>
		<dependency>
			<groupId>javax.servlet</groupId>
			<artifactId>servlet-api</artifactId>
			<version>${servlet-api.version}</version>
			<scope>provided</scope>
		</dependency>
		<dependency>
			<groupId>javax.servlet</groupId>
			<artifactId>jsp-api</artifactId>
			<version>${jsp-api.version}</version>
			<scope>provided</scope>
		</dependency>
	</dependencies>

	<build>
		<sourceDirectory>src</sourceDirectory>
		<resources>
			<resource>
				<directory>src</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
			<resource>
				<directory>resource</directory>
				<excludes>
					<exclude>**/*.java</exclude>
				</excludes>
			</resource>
		</resources>
		<plugins>
			<plugin>
				<artifactId>maven-compiler-plugin</artifactId>
				<version>3.1</version>
				<configuration>
					<source>1.7</source>
					<target>1.7</target>
				</configuration>
			</plugin>
			<plugin>
				<artifactId>maven-war-plugin</artifactId>
				<version>2.4</version>
				<configuration>
					<warSourceDirectory>WebRoot</warSourceDirectory>
					<failOnMissingWebXml>false</failOnMissingWebXml>
				</configuration>
			</plugin>
		</plugins>
	</build>
</project>
{% endcodeblock%}


## **三、仓库：**

**1) 本地仓库**
Maven 本地仓库是机器上的一个文件夹。它在你第一次运行任何 maven 命令的时候创建。
Maven 本地仓库保存你的工程的所有依赖（library jar、plugin jar 等）。当你运行一次 Maven 构建，Maven 会自动下载所有依赖的 jar 文件到本地仓库中。它避免了每次构建时都引用存放在远程机器上的依赖文件。

可以在maven安装地址的conf/settings.xml 指定本地仓库的路径

{% codeblock lang:xml %}
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
   xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
   http://maven.apache.org/xsd/settings-1.0.0.xsd">
      <localRepository>E:/myLocalRepository</localRepository>
</settings>
{% endcodeblock%}

**2）中央仓库**
http://mvnrepository.com/
https://search.maven.org/


**3)远程仓库**
可以在私有服务器上搭建自己的maven仓库，外网的内网的都可以。eg:

{% codeblock lang:xml %}
  <repositories>
      <repository>
         <id>companyname.lib1</id>
         <url>http://download.companyname.org/maven2/lib1</url>
      </repository>
      <repository>
         <id>companyname.lib2</id>
         <url>http://172.16.176.234/maven2/lib2</url>
      </repository>
   </repositories>
{% endcodeblock%}


Maven 依赖搜索顺序
步骤1：在本地仓库找
步骤2：若本地仓库没找到则去中央仓库找，找到则下载到本地仓库，留着日后备用
步骤3：若中央仓库没找到，则会检查时候有设置远程仓库，若有，则会在远程仓库中查找并下载到本地仓库备用。若没设置远程仓库或者在远程仓库中也无法找到，则会抛出错误(无法找到依赖的文件)

![这里写图片描述](http://img.blog.csdn.net/20170125110520928?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

 **针对这种情况，可以通过构建外部依赖的方法解决。**


<br>

## **四、构建外部依赖**

把jar包文件并放到工程lib下，然后在pom.xml中添加依赖，eg:

![这里写图片描述](http://img.blog.csdn.net/20170125110843211?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


{% codeblock lang:xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
       http://maven.apache.org/maven-v4_0_0.xsd">
       <modelVersion>4.0.0</modelVersion>
       <groupId>com.companyname.bank</groupId>
       <artifactId>consumerBanking</artifactId>
       <packaging>jar</packaging>
       <version>1.0-SNAPSHOT</version>
       <name>consumerBanking</name>
       <url>http://maven.apache.org</url>
      <dependencies>
          <dependency>
             <groupId>ldapjdk</groupId>
             <artifactId>ldapjdk</artifactId>
             <scope>system</scope>
             <version>1.0</version>
             <systemPath>${basedir}\src\lib\ldapjdk.jar</systemPath>
          </dependency>
       </dependencies>

    </project>
{% endcodeblock%}



## **五、依赖管理(Maven的核心特点之一)**

当一个库 A 依赖于其他库 B. 另一工程 C 想要使用库 A, 那么该工程同样也需要使用到库 B。

使用maven，我们只需要在每个工程的 pom 文件里去定义直接的依赖关系。Maven 则会自动的来接管后续的工作。比如我们在pom.xml中定义了依赖jar包A，那么A所依赖的其他jar包，会被自动下载，不需要我们去定义。是不是很省事？



本文只是初步介绍了下maven 的使用，主要是在maven管理jar包，pom.xml文件的配置方面。还没涉及到maven在项目管理以及自动化构建方面。可参考下面链接拓展学习。

[Apache Maven 入门篇](http://www.oracle.com/technetwork/cn/community/java/apache-maven-getting-started-1-406235-zhs.html)

[Maven - 构建自动化](http://wiki.jikexueyuan.com/project/maven/build-automation.html)

