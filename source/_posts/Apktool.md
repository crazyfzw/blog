---
title: 用Apktool获取别人APP中的图片及布局资源进行学习
date: 2016-04-19 17:07:16
categories:
- Android
tags:
- Apktool 
- 反编译
- apktool.jar
- apktool.bat
- 获取APP的布局文件
---

当我们看到一款UI布局很漂亮的APP，想要了解别人是怎么实现的时候，就可以通过Apktool工具来反编译别人的apk，从而获取图片及布局资源来进行学习。



其实我们下载到的Android 应用，是可以直接把后缀名改成zip的，然后解压zip就可以得到对应的文件目录

![](/images/2016041901.jpg)

<!--more-->



其中，res为所有资源文件，META-INF为签名信息，classes.dex为java源码编译后生成的字节码。

原以为这样轻松的就可以拿到别人的布局源码了，实则不然，点开res/layout下的一个布局文件看看

![](/images/2016041902.jpg)





然后发现里面都是XML文件经过编译的机器码。那么怎么获取别人的布局文件呢?这时，Apktool就派上用场了。



### 首先下载安装Apktool：

下载地址：[http://ibotpeaches.github.io/Apktool/install/](http://ibotpeaches.github.io/Apktool/install/)

![](/images/2016041903.jpg)



### 下载对应版本

*1.* 将wrapper script右键选择连接另存为得到apktool.bat文件， 

2. 在 [https://bitbucket.org/iBotPeaches/apktool/downloads](https://bitbucket.org/iBotPeaches/apktool/downloads)
   下载最新版本的apktool.jar包如现在最新的apktool_2.1.0.jar，并删除版本号重名名为apktool.jar

3. 将apktool.bat、apktool.jar、及想要编译的apk文件放在同一文件夹下

4.  通过cmd进入对应目录运行apktool.bat  d -f [apk文件 ]  [输出文件夹]就可以得到相应的布局资源文件了，截图如下

![](/images/2016041904.jpg)

![](/images/2016041905.jpg)



这时打开res下的文件目录会发现有很多abc及notfication开头的文件，这些文件是自动生成的，并不是开发者真正写的布局文件，我们需要看的是其他xml文件,如黄色部分。

![](/images/2016041906.jpg)


点开就可以看到相应的xml布局源码了

![](/images/2016041907.jpg)



如果想要看别人java源码，学习别人功能的实现的话，就要用到dex2jar及jd-gui了，

其中dex2jar可以将apk改成zip加压后得到的classes.dex文件反编译成jar文件。

jd-gui：可以查看dex2jar转换出来的jar文件，就是我们想要的java源码了。



想看详细用法的可以参考：[Android APK反编译详解](http://blog.csdn.net/ithomer/article/details/6727581)

