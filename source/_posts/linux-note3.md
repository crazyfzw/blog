---
title: Linux学习笔记（三）：服务器常用命令 
date: 2017-10-20 21:05:09
categories:
- Linux
tags:
- Linux
---

#### 查看指定关键字进程
```
查看指定进程进程 ps -ef | grep  
如查看java进程  ps -ef | grep java  
查看tomcat进程  ps -ef | grep tomcat
查看某项目进程  ps -ef | grep 目录名  ps -ef | grep ems
```
<!--more-->

#### 查看实时日志
```
tail -f logs/catalina.out

tail -5000f logs/catalina.out
```


#### 查看文件
```
cat 文件名
```

#### 根据 关键词 查看日志 并返回关键词所在行：
```
cat 路径/文件名 | grep 关键词    
```


#### 下载文件
```
sz 文件名 
```

#### 查看当前目录
```
pwd
```

#### 强制终止进程 
```
kill -9 5031 
```

#### 查看内存占用情况
```
free -m 
```
#### 实时显示各个进程的资源占用情况
```
top
```