---
title: 阿里云ECS：Java WEB环境搭建
date: 2017-11-02 22:42:22
categories:
- Linux
tags:
- 阿里云ECS
- Linux
---

前些时间，买了个 阿里云 ECS，详细配置为 1vCPU、1GB 内存、40GB系统盘、20GB SSD，搭载的是 CentOS 7.4 系统。这里仅记录下在 ECS 上搭建 Java WEB 环境的过程。

## 一、远程连接服务器

我这里使用的是 Xshell + Xftp 组合。Xshell 用来远程访问并控制终端，Xftp  基本上只用于传输文件。

![](/images/2017110601.png)

![](/images/2017110602.png)

![](/images/2017110603.png)

## 二、 格式化和挂载数据盘   (这里以/dev/xvdb为例)

这里需要注意的是单独购买的数据盘需要先挂载数据盘，然后才能格式化。随实例一起购买的数据盘，无需挂载，直接格式化。


1.查看分区    df -h
 

2.查看数据盘  fdisk -l    


3.使用 fdisk命令分区 

  &emsp;1）运行 fdisk /dev/xvdb，对数据盘进行分区。根据提示，依次输入 n，p，1，两次回车，wq，分区就开始了

  &emsp;2）运行 fdisk -l 命令，查看新的分区是否已经建好


4.格式化新分区

  &emsp;1）运行 mkfs.ext3 /dev/xvdb1，对新分区进行格式化。格式化所需时间取决于数据盘大小。您也可自主决定选用其他文件格式，如 ext4 等

  &emsp;2）运行 echo /dev/xvdb1 /mnt ext3 defaults 0 0 >> /etc/fstab 写入新分区信息，完成后，可以使用 cat /etc/fstab 命令查看

5.挂载新分区
  运行 mount /dev/xvdb1 /mnt 挂载新分区，然后执行 df -h 查看分区。如果出现数据盘信息，说明挂载成功，可以使用新分区了


## 三、安装JDK

这里可以通过 wget 命令去在线下载，然后再用 tar 命令解压到指定目录

```
wget http://mirrors.linuxeye.com/jdk/jdk-8u141-linux-x64.tar.gz

tar xzf jdk-8u141-linux-x64.tar.gz -C /usr/local/bin
```


因为我本地已经有tomcat 以及jdk 了，所以为了方便，直接通过 Xftp 上传到指定目录

![](/images/2017110604.png)


接着设**置 JDK 的环境变量**，步骤如下：

1. 先用 vi  /etc/profile 打开配置文件
2. 然后 按 i 键进入编辑模式
3. 接着插入下面的信息，指定jdk目录
4. 接着按 Esc 键退出编辑模式，输入 :wq 保存并关闭文件，如果不小心写错，不想保存，则可以通过:q!退出。
5. 最后，通过 source /etc/profile 加载环境变量
6. 输入 java -version 查看jdk版本，验证是否安装成功

```
#set java environment
export JAVA_HOME=/usr/local/bin/jdk1.7.0_60
export CLASSPATH=$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib
export PATH=$JAVA_HOME/bin:$PATH
```

![](/images/2017110605.png)

![](/images/2017110606.png)


## 四、安装 Tomcat  

tomcat 的安装更简单， 基本上传到指定目录，在 server.xml 改下端口就行了。

![](/images/2017110607.png)


## 五、开放端口

需要格外注意的是 CentOS 7.4 系统默认开启了防火墙。需要配置安全组 放行 80、443 或 8080 端口入方向规则。

参考  《ECS安全组实践 》 https://help.aliyun.com/document_detail/51170.html?spm=5176.product25365.6.742.0SxQKm


![](/images/2017110608.png)


![](/images/2017110609.jpg)


## 六、验证

通过 tomcat 下的 startup.sh 启动下 tomcat，就可以验证了。

![](/images/2017110610.png)

![](/images/2017110611.png)


## 七、参考文献 

[1][Linux 格式化和挂载数据盘](https://help.aliyun.com/document_detail/51376.html?spm=5176.doc51170.6.717.2smpOG)

[2][手工部署Java Web项目](https://help.aliyun.com/document_detail/51376.html?spm=5176.doc51170.6.717.2smpOG)


