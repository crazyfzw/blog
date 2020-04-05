---
title: 2016秋招笔试面试题二：Android及网络协议部分
date: 2016-12-31 11:45:49
categories:
- Interview
tags:
- android面试题
- 秋招笔试面试题
---


# **一、Android基础**

## **1.Android四大组件的理解**

**Activity：**从字面上理解，Activity是活动的意思。一个Activity通常展现为一个可视化的用户界面，是Android程序与用户交互的窗口，也是Android组件中最基本也是最复杂的一个组件。从视觉效果来看，一个Activity占据当前的窗口，响应所有窗口事件，具备有控件，菜单等界面元素。从内部逻辑来看，Activity需要为了保持各个界面状态，需要做很多持久化的事情，还需要妥善管理生命周期，和一些转跳逻辑。
<!--more-->


**Service：**服务是运行在后台的一个组件，从某从意义上说，服务就像一个没有界面的Activity。它们在很多Android的概念方面比较接近，封装有一个完整的功能逻辑实现，接受上层指令，完成相关的事件，定义好需要接受的Intent提供同步和异步的接口。

**BroadcastReceiver：**广播接收者，不执行任何任务，广播是一种广泛运用的在应用程序之间传输信息的机制 。而 BroadcastReceiver 是对发送出来的广播进行过滤接收并响应的一类组件。Broadcast Receiver 不包含任何用户界面。然而它们可以启动一个Activity以响应接受到的信息，或者通过NotificationManager通知用户。可以通过多种方式使用户知道有新的通知产生：闪动背景灯、震动设备、发出声音等等。通常程序会在状态栏上放置一个持久的图标，用户可以打开这个图标并读取通知信息。在Android中还有一个很重要的概念就是Intent，如果说Intent是一个对动作和行为的抽象描述，负责组件之间程序之间进行消息传递。那么Broadcast Receiver组件就提供了一种把Intent作为一个消息广播出去，由所有对其感兴趣的程序对其作出反应的机制。

**Content Provider：**即内容提供者，作为应用程序之间唯一的共享数据的途径，Content Provider 主要的功能就是存储并检索数据以及向其他应用程序提供访问数据。 
对应用而言，也可以将底层数据封装成ContentProvider，这样可以有效的屏蔽底层操作的细节，并且使程序保持良好的扩展性和开放性。Android提供了一些主要数据类型的Contentprovider，比如音频、视频、图片和私人通讯录等。可在android.provider包下面找到一些android提供的Contentprovider。可以获得这些Contentprovider，查询它们包含的数据，当然前提是已获得适当的读取权限。如果我们想公开自己应用程序的数据，可以创建自己的 Content provider 的接口。


## **2.Activity的生命周期**
![这里写图片描述](http://img.blog.csdn.net/20161231134946734?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)		


## **3.activity的onCreat()方法参数的作用**
onCreate方法的参数是一个Bundle类型的参数，savedInstanceState也就是保存Activity的状态的,当
一个Activity在生命周期以不正常的状态结束前，会调用onsaveInstanceState该方法保存状态。

## **4.AsyncTask 的使用**

为了更加方便我们在子线程中更新UI元素，Android从1.5版本就引入了一个AsyncTask类，使用它就可以非常灵活方便地从子线程切换到UI线程。

{% codeblock lang:java %}
public class DownloadTask extends AsyncTask {  
	@Override
	protectedvoid onPreExecute() {  
	        progressDialog.show();  
	} 

	@Override
	protected Boolean doInBackground(Void... params) {  
	try {  
		while (true) {  
			int downloadPercent = doDownload();  
			publishProgress(downloadPercent);  
			if (downloadPercent >= 100) {  
			    break;  
			}  
	    }  
	} catch (Exception e) {  
	    return false;  
	 }  
	return true;  
	}  

	@Override
	protectedvoid onProgressUpdate(Integer... values) {  
	        progressDialog.setMessage("当前下载进度：" + values[0] + "%");  
	    } 

	@Override
	protectedvoid onPostExecute(Boolean result) {  
	        progressDialog.dismiss();  
	if (result) {  
	            Toast.makeText(context, "下载成功", Toast.LENGTH_SHORT).show();  
	        } else {  
	            Toast.makeText(context, "下载失败", Toast.LENGTH_SHORT).show();  
	        }  
	}  
}  
{% endcodeblock %}

**1) onPreExecute()**
这个方法会在后台任务开始执行之间调用，用于进行一些界面上的初始化操作，比如显示一个进度条对话框等。
**2)  doInBackground(Params...)**
这个方法中的所有代码都会在子线程中运行，我们应该在这里去处理所有的耗时任务。任务一旦完成就可以通过return语句来将任务的执行结果进行返回，如果AsyncTask的第三个泛型参数指定的是Void，就可以不返回任务执行结果。注意，在这个方法中是不可以进行UI操作的，如果需要更新UI元素，比如说反馈当前任务的执行进度，可以调用publishProgress(Progress...)方法来完成。
**3) onProgressUpdate(Progress...)**
当在后台任务中调用了publishProgress(Progress...)方法后，这个方法就很快会被调用，方法中携带的参数就是在后台任务中传递过来的。在这个方法中可以对UI进行操作，利用参数中的数值就可以对界面元素进行相应的更新。
**4) onPostExecute(Result)**
当后台任务执行完毕并通过return语句进行返回时，这个方法就很快会被调用。返回的数据会作为参数传递到此方法中，可以利用返回的数据来进行一些UI操作，比如说提醒任务执行的结果，以及关闭掉进度条对话框等。

详见：[郭霖的AsyncTask完全解析](http://blog.csdn.net/guolin_blog/article/details/11711405)


## **5.IntentService与Service的异同**

IntentService是继承Service的，那么它包含了Service的全部特性，当然也包含service的生命周期，那么与service不同的是，IntentService在执行onCreate操作的时候，内部开了一个线程，去你执行你的耗时操作。


## **6.IntentService 的使用**

IntentService是会自动开启子线程并会自动结束的Service

{% codeblock lang:java%}
public class TestIntentService extends IntentService {  
    /**
     * 需要一个无参数的构造方法，调用父类的带String参数的构造方法，参数是线程名称
     */
	public TestIntentService() {  
	  super("TestIntentService");  
	}  

    /**
     * 重写IntentService的onHandleIntent，处理耗时的任务。这个方法是在单独线程中运行，而不是在主线程中，所以不会阻塞主线程。
     */
     
	@Override
	protectedvoid onHandleIntent(Intent intent) {  
	// 耗时任务代码
	    }  
}  
{% endcodeblock %}

1) IntentService 会创建一个线程，来处理所有传给onStartCommand()的Intent请求。
2) 对于startService()请求执行onHandleIntent()中的耗时任务，会生成一个队列，每次只有一个Intent传入onHandleIntent()方法并执行。也就是同一时间只会有一个耗时任务被执行，其他的请求还要在后面排队， onHandleIntent()方法不会多线程并发执行。
3) 当所有startService()请求被执行完成后，IntentService 会自动销毁，所以不需要自己写stopSelf()或stopService()来销毁服务。
4) 提供默认的onBind()实现 ，即返回null，不适合绑定的 Service。
5) 提供默认的 onStartCommand() 实现，将intent传入等待队列中，然后到onHandleIntent()的实现。所以如果需要重写onStartCommand() 方法一定要调用父类的实现。

详见： 叉叉哥的IntentService 解析


## **7.Android的几种数据存储方式**

 - SharePreferences
   
 - SQLite
   
 - Contert Provider
   
 - 文件存储
   
 - 网络数据库存储


## **8.SQLite数据库版本更新时如何避免数据丢失**

随着应用的升级或者需求的变化，有时需要在原来的表的基础上增加字段，并且需要保证不丢失原来的数据。

其实SqliteOpenHelper的构造方法里有一个参数是int version, 意思是指当前数据库的版本。比如我们的1.0应用中数据库版本是1，当我们需要在2.0版本的应用中改变数据库（可能是增加一个字段，或者是删除一个字段等），我们就要设置int verison的值大于前面一个版本的数据库版本的值，例如改为2，就会触发onUpgrade()方法。所以，我们可以在onUpgrade()方法中进行更新数据库操作。


为了避免表结构改变而引起数据丢失，我们可以在改变表结构之前，通过建立临时表来处理。

那么可以采取在一个事务中执行如下语句来实现修改表的需求。
**1) 将表改为临时表**

ALTER TABLE User RENAME TO _TEMP_User;

**2) 创建新的表**

CREATE TABLE User (Userid text primary key not null, Sex text not null,Birthday text not null,Name text not null);

**3) 导入数据**

INSERT INTO User SELECT Userid,"","",Name FROM TO_TEMP_User;

或者

INSERT INTO User() SELECT Userid,"","",Name FROM TO_TEMP_User;
*注意，“”是用来补充原来不存在的数据的。

**4)  删除临时表**

DROP TABLE _TEMP_User;

详细可见：http://www.lai18.com/content/1369050.html


## **9.Android中，进程通讯(IPC)的方式有哪些**

1)  Linux系统进程间通信有哪些方式？

 - socket 
  
 - name pipe命名管道
 
 - message queue消息队列     

 - singal信号量

 - share memory共享内存
    
2) Java系统的通信方式是什么？
 
 - socket  
 - name pipe

 
3) Android系统通信方式是什么？
 Binder 通信

Android进程间通信是通过Binder来实现的。远程Service在Client绑定服务时，会在onBind()的回调中返回一个Binder，当Client调用bindService()与远程Service建立连接成功时，会拿到远程Binder实例，从而使用远程Service提供的服务。

详细可见：
http://gold.xitu.io/entry/570af83b8ac247004c31a130


## **9.Android中，线程通讯的几种方式**  　 
   　
    1)  handle
    
　　2)  Activity.runOnUIThread(Runnable)

　　3)  View.Post(Runnable)

　　4)  View.PostDelayed(Runnabe,long)

　　5)  AsyncTask
　　
　　6)IntentService：内部有handlethread，属于服务的一种执行完自动结束  优点：优先级高不易被杀死。



# **二、协议**
## **1.OSI，TCP/IP，五层协议的体系结构，以及各层协议**

OSI分层 （7层）：物理层、数据链路层、网络层、传输层、会话层、表示层、应用层。

TCP/IP分层（4层）：网络接口层、 网际层、运输层、 应用层。

五层协议 （5层）：物理层、数据链路层、网络层、运输层、 应用层。

**每一层的协议如下：**

 - 物理层：RJ45、CLOCK、IEEE802.3 （中继器，集线器） 
 
 - 数据链路：PPP、FR、HDLC、VLAN、MAC （网桥，交换机）
   
 - 网络层：IP、ICMP、ARP、RARP、OSPF、IPX、RIP、IGRP、 （路由器） 传输层：TCP、UDP、SPX
   
 - 会话层：NFS、SQL、NETBIOS、RPC 表示层：JPEG、MPEG、ASII

 -  应用层：FTP、DNS、Telnet、SMTP、HTTP、WWW、NFS 

**每一层的作用如下：**

  - 物理层：通过媒介传输比特,确定机械及电气规范（比特Bit） 数据链路层：将比特组装成帧和点到点的传递（帧Frame）
 
  - 网络层：负责数据包从源到宿的传递和网际互连（包PackeT）
  
  -  传输层：提供端到端的可靠报文传递和错误恢复（段Segment）
  
  - 会话层：建立、管理和终止会话（会话协议数据单元SPDU） 表示层：对数据进行翻译、加密和压缩（表示协议数据单元PPDU）
  
  - 应用层：允许访问OSI环境的手段（应用协议数据单元APDU）
   
   注意：HTTP协议： 超文本传输协议，是一个属于应用层的面向对象的协议，由于其简捷、快速的方式，适用于分布式超媒体信息系统。

详细可见：
http://www.nowcoder.com/ta/review-network/review?tpId=33&tqId=21189&query=&asc=true&order=&page=1


## **2.TCP和UDP的区别**

1) TCP提供面向连接的、可靠的数据流传输，而UDP提供的是非面向连接的、不可靠的数据流传输。

2) TCP传输单位称为TCP报文段，UDP传输单位称为用户数据报。

3) TCP注重数据安全性，UDP数据传输快，因为不需要连接等待，少了许多操作，但是其安全性却一般。


## **3.TCP协议中的三次握手及四次挥手**

**三次握手：**
第一次握手：客户端发送syn包(syn=x)到服务器，并进入SYN_SEND状态，等待服务器确认；

第二次握手：服务器收到syn包，必须确认客户的SYN（ack=x+1），同时自己也发送一个SYN包（syn=y），即SYN+ACK包，此时服务器进入SYN_RECV状态；

第三次握手：客户端收到服务器的SYN＋ACK包，向服务器发送确认包ACK(ack=y+1)，此包发送完毕，客户端和服务器进入ESTABLISHED状态，完成三次握手。

握手过程中传送的包里不包含数据，三次握手完毕后，客户端与服务器才正式开始传送数据。理想状态下，TCP连接一旦建立，在通信双方中的任何一方主动关闭连接之前，TCP 连接都将被一直保持下去。

**四次挥手**
与建立连接的“三次握手”类似，断开一个TCP连接则需要“四次握手”。

第一次挥手：主动关闭方发送一个FIN，用来关闭主动方到被动关闭方的数据传送，也就是主动关闭方告诉被动关闭方：我已经不 会再给你发数据了(当然，在fin包之前发送出去的数据，如果没有收到对应的ack确认报文，主动关闭方依然会重发这些数据)，但是，此时主动关闭方还可 以接受数据。

第二次挥手：被动关闭方收到FIN包后，发送一个ACK给对方，确认序号为收到序号+1（与SYN相同，一个FIN占用一个序号）。

第三次挥手：被动关闭方发送一个FIN，用来关闭被动关闭方到主动关闭方的数据传送，也就是告诉主动关闭方，我的数据也发送完了，不会再给你发数据了。

第四次挥手：主动关闭方收到FIN后，发送一个ACK给被动关闭方，确认序号为收到序号+1，至此，完成四次挥手。

详细可见：
http://www.nowcoder.com/ta/review-network/review?tpId=33&tqId=21194&query=&asc=true&order=&page=6


## **4.TCP的三次握手过程？为什么会采用三次握手，若采用二次握手可以吗？**

答:建立连接的过程是利用客户服务器模式，假设主机A为客户端，主机B为服务器端。
（1）TCP的三次握手过程：主机A向B发送连接请求；主机B对收到的主机A的报文段进行确认；主机A再次对主机B的确认进行确认。
（2）采用三次握手是为了防止失效的连接请求报文段突然又传送到主机B，因而产生错误。失效的连接请求报文段是指：主机A发出的连接请求没有收到主机B的确认，于是经过一段时间后，主机A又重新向主机B发送连接请求，且建立成功，顺序完成数据传输。考虑这样一种特殊情况，主机A第一次发送的连接请求并没有丢失，而是因为网络节点导致延迟达到主机B，主机B以为是主机A又发起的新连接，于是主机B同意连接，并向主机A发回确认，但是此时主机A根本不会理会，主机B就一直在等待主机A发送数据，导致主机B的资源浪费。
（3）采用两次握手不行，原因就是上面说的实效的连接请求的特殊情况。


## **5.在浏览器中输入www.baidu.com后执行的全部过程**

1、客户端浏览器通过DNS解析到www.baidu.com的IP地址220.181.27.48，通过这个IP地址找到客户端到服务器的路径。客户端浏览器发起一个HTTP会话到220.161.27.48，然后通过TCP进行封装数据包，输入到网络层。

2、在客户端的传输层，把HTTP会话请求分成报文段，添加源和目的端口，如服务器使用80端口监听客户端的请求，客户端由系统随机选择一个端口如5000，与服务器进行交换，服务器把相应的请求返回给客户端的5000端口。然后使用IP层的IP地址查找目的端。

3、客户端的网络层不用关心应用层或者传输层的东西，主要做的是通过查找路由表确定如何到达服务器，期间可能经过多个路由器，这些都是由路由器来完成的工作，我不作过多的描述，无非就是通过查找路由表决定通过那个路径到达服务器。

4、客户端的链路层，包通过链路层发送到路由器，通过邻居协议查找给定IP地址的MAC地址，然后发送ARP请求查找目的地址，如果得到回应后就可以使用ARP的请求应答交换的IP数据包现在就可以传输了，然后发送IP数据包到达服务器的地址。

