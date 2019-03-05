---
title: Redis 开发与运维 2：Redis环境搭建及Redis shell的使用
date: 2018-08-10 22:46:11
categories:
- Redis
tags:
- Redis
- Redis shell
- Redis 环境搭建
- redis-server
- redis-cli
---

## 一、版本选择


>Redis 借鉴了 Linux 操作系统对于版本号的命名规则：版本号第二位如果是奇数，则为非稳定版本（例如2.7、2.9、3.1），如果是偶数，则为稳定版本（例如2.6、2.8、3.0、3.2、4.0）。当前奇数版本就是下一个稳定版本的开发版本，例如2.9版本是3.0版本的开发版本。所以我们在生产环境通常选取偶数版本的 Redis。

生产环境推荐选用偶数版本，推荐从 2.6、2.8、3.0、3.2 、4.0 这几个重大版本中选。几个版本的区别可参考 [Redis重大版本](https://www.cnblogs.com/yangmingxianshen/p/8043851.html)

## 二、安装 Redis

进入 /usr/local 目录

### 下载安装包
```
$ wget http://download.redis.io/releases/redis-4.0.0.tar.gz
```

![](/images/2018081101.png)


### 解压
```
tar xzf redis-4.0.0.tar.gz
```

![](/images/2018081102.png)


### 创建软链接
建立一个名叫 redis 的软链接指向 redis-4.0.0 目录，这样做是为了不把 redis 目录固定在指定版本上，有利于Redis未来版本升级，算是安装软件的一种好习惯。（类型window 系统的快捷方式）

```
ln -s redis-4.0.0 redis 
```

![](/images/2018081103.png)


### 编译
```
make
```

![](/images/2018081104.png)


### 安装
```
make install
```

![](/images/2018081105.png)


make install 会将 Redis 的相关运行文件放到 /usr/local/bin/ 下，这样就可以在任意目录下执行 Redis 的命令了。

![](/images/2018081106.png)

查看 redis 版本
```
redis-cli -v
```

显示如下，说明已经安装成功啦。

![](/images/2018081107.png)


**小结：**
整个安装过程其实非常简单，总共6步：
```
$ wget http://download.redis.io/releases/redis-4.0.0.tar.gz

$ tar xzf redis-4.0.0.tar.gz

$ ln -s redis-4.0.0 redis

$ cd redis

$ make

$ make install
```

## 三、配置、 启动、 操作、 关闭 Redis

前面已经提到 使用 make install 安装 Redis 之后，src和/usr/local/bin目录下多了几个以redis开头可执行文件，我们称之为RedisShell，这些可执行文件可以做很多事情，比如可以启动和停止Redis、可以检测和修复Redis的持久化文件，还可以检测Redis的性能。 下面是是我们最常用到的 Redis shell 说明：

| 可执行文件 | 作用描述 |
| :--: | :--: |
| redis-server | 启动 Redis |
| redis-cli | Redis 命令行客户端 |
| redis-benchmark | Redis 基准测试工具 |
| redis-check-aof | Redis AOF 持久化文件检测和修复工具 |
| redis-check-dump | Redis RDB 持久化文件检测和修复工具 |
| redis-sentinel | 启动 Redis Sentinel |



### 启动服务
启动 Redis 服务的方法有三种，分别是：默认配置启动、运行配置启动、配置文件启动。生产环境推荐用配置文件启动，因为这种方式提供了更大的灵活性。

下面分别介绍下三种启动方式：

**默认配置启动**
```
redis-server
```

直接启动无法自定义配置，生产环境应该避免使用这种方式启动 Redis 服务。

**运行配置启动**
```
redis-server --configKey1 configValue1	 --configKey2 configValue2 ...
```

比如要指定端口（注： Redis 的默认端口是 6379），可以
```
redis-server --port 6380
```

**配置文件启动（生产环境推荐使用这种方式）**

通常我们会在一台机器上启动多台 Redis，并且将配置管理在集中目录下，习惯性的做法是把 Redis安装目录下的 redis.conf 拷贝到  /opt/redis/ 下，然后作为模板根据需要修改。

然后通过指定该配置文件启动 Redis 服务
```
redis-server  /opt/redis/redis.conf
```

![](/images/2018081108.png)


### 操作
操作是通过 Redis命令行客户端来完成，有两种方式，一种是交互方式，一种是命令方式，推荐使用交互方式。

在用 redis-cli 连接 Redis服务之前，可以先用 ps -ef |grep redis 看redis是否在服务，以及查看对应的 ip 端口信息。

![](/images/2018081109.png)

**交互方式（推荐使用这种方式）**
通过 redis-cli -h{host}- p{port} 的方式连接到Redis服务，之后所有的操作都是通过交互的方式实现，不需要再执行redis-cli了。

![](/images/2018081110.png)


**命令方式**
用 redis-cli -h{host} -p{port} {command} 直接得到命令的返回结果。

![](/images/2018081111.png)


### 关闭服务
```
redis-cli shutdown
```
![](/images/2018081112.png)


## 四、参考文献

[1]《Redis 开发与运维》付磊; 张益军著