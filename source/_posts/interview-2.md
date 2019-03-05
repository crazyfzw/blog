---
title: 2016秋招笔试面试题一：Java及基础部分
date: 2016-12-30 00:00:49
categories: 
- Interview
tags:
- java面试题
- 秋招笔试面试题
---



## **1.面向对象的特征**

**1) 抽象：** 抽象就是忽略一个主题中与当前目标无关的那些方面，以便更充分地注意与当前目标有关的方面。抽象并不打算了解全部问题，而只是选择其中的一部分，暂时不用部分细节。抽象包括两个方面，一是过程抽象，二是数据抽象。

 **2) 继承：** 继承是一种联结类的层次模型，并且允许和鼓励类的重用，它提供了一种明确表述共性的方法。对象的一个新类可以从现有的类中派生，这个过程称为类继承。新类继承了原始类的特性，新类称为原始类的派生类（子类），而原始类称为新类的基类（父类）。派生类可以从它的基类那里继承方法和实例变量，并且类可以修改或增加新的方法使之更适合特殊的需要。 

**3) 封装：** 封装是把过程和数据包围起来，对数据的访问只能通过已定义的界面。面向对象计算始于这个基本概念，即现实世界可以被描绘成一系列完全自治、封装的对象，这些对象通过一个受保护的接口访问其他对象。

 **4) 多态性：** 多态性是指允许不同类的对象对同一消息作出响应。多态性包括参数化多态性和包含多态性。多态性语言具有灵活、抽象、行为共享、代码共享的优势，很好的解决了应用程序函数同名问题。    
 <br/> 
## **2.java和c++最大的区别**

 - 内存管理 
 - 指针

## **3.JAVA 中int和Integer的区别**

int是一种基本数据类型，而Integer是相应于int的类类型，称为对象包装。
		
Integer类在对象中包装了一个基本类型int的值。Integer类型的对象包含一个int类型的字段，Integer是int的封装类。
此外，该类提供了多个方法，能在int类型和String类型之间互相转换，还提供了处理int类型时非常有用的其他一些常量和方法。
详细可见：http://www.jianshu.com/p/4d6fc88f9458
  
<br/>
## **4.Java的作用域**
**private** 私有权限。只有自己能用。
**friendly** 包权限。同一个包下的可用。不写时默认为friendly 
**protected** 继承权限。（是包权限的扩展，子女类也可使用）。
**public** 谁都可以用。
详细可见：
http://blog.csdn.net/ladofwind/article/details/774072
  
<br/> 
## **5.overload和override的区别**
**override：**（重写，会覆盖父类的方法，是父类与子类之间多态性的一种表现）
1) 方法名、参数、返回值必须相同。 
2) 子类方法不能缩小父类方法的访问权限。 
3) 子类方法不能抛出比父类方法更多的异常(但子类方法可以不抛出异常)。 
4) 存在于父类和子类之间。，被覆盖的方法不能为private
5) 方法被定义为final不能被重写。 


{% codeblock lang:java%}
class A{     
public int getVal(){     
   return(5);     
}     
}     
class B extends A{     
public int getVal(){     
   return(10);     
}     
}     

public class override {     
public static void main(String[] args) {     
   B b = new B();     
   A a= (A)b;//把 b 强 制转换成A的类型     
   int x=a.getVal();     
   System.out.println(x);     
}     
}   

{% endcodeblock%}


**overload**（重载，一个类中定义多个同名的方法，这些方法的参数不相同，是一个类中多态性的一种表现） 
1) 参数类型、个数、顺序至少有一个不相同。   
2) 不能通过访问权限、返回类型、抛出的异常进行重载； 
3) 存在于父类和子类、同类中。 
4) 方法的异常类型和数目不会对重载造成影响； 

{% codeblock lang:java %}
class OverloadDemo {     
	void test(){     
	   System.out.println("NO parameters");     
	}     
	void test(int a){     
	   System.out.println("a:"+a);     
	}//end of Overload test for one integer parameter.     
	void test(int a, int b){     
	   System.out.println("a and b:"+a+" "+b);     
	       
	}  
	double test(double a){     
	   System.out.println("double a:"+a);     
	   return a*a;     
	}  
}  

public class Overload{     
	public static void main(String[] args) {     
	   OverloadDemo ob = new OverloadDemo();     
	   double result;     
	   ob.test();     
	   ob.test(10);     
	   ob.test(10, 20);     
	   result = ob.test(123.25);     
	   System.out.println("Result of ob.test(123.25):"+result);  
	 }  
}  
{% endcodeblock %}
  
 <br/> 
## **6. volatile关键字的作用**
当我们使用volatile关键字去修饰变量的时候，所以线程都会直接在内存中读取该变量并且不缓存它。这就确保了线程读取到的变量是同内存中是一致的。从而保证多线程中变量的安全性。
  
## **7.error和exeception的区别**
![这里写图片描述](http://img.blog.csdn.net/20161229225813014?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

Error类和Exception类都继承自Throwable类。		

Error的继承关系：java.lang.Object > java.lang.Throwable > java.lang.Error
		
		
Exception的继承关系：
java.lang.Object > java.lang.Throwable >　java.lang.Exception
		
		
**二者的不同之处：**
Exception：
1) 可以是可被控制(checked) 或不可控制的(unchecked)
2) 表示一个由程序员导致的错误
3) 应该在应用程序级被处理		

Error：
1) 总是不可控制的(unchecked)
2) 经常用来用于表示系统错误或低层资源的错误
3) 如何可能的话，应该在系统级被捕捉
详细可见：http://wenku.baidu.com/link?url=Xvk-

<br/>
## **8. String、StringBuffer、StringBuilder的区别**

**String 与StringBuffer对比**
      String 类型和 StringBuffer 类型的主要性能区别其实在于 String 是不可变的对象, 因此在每次对 String 类型进行改变的时候其实都等同于生成了一个新的 String 对象，然后将指针指向新的 String 对象，所以经常改变内容的字符串最好不要用 String ，因为每次生成对象都会对系统性能产生影响，特别当内存中无引用对象多了以后， JVM 的 GC 就会开始工作，从而降低了效率。
     而使用 StringBuffer 类则结果就不一样了，每次结果都会对 StringBuffer 对象本身进行操作，而不是生成新的对象，再改变对象引用。别是字符串对象经常改变的情况下推荐使用 StringBuffer 特。 

**StringBuffer与StringBuilder对比**
StringBuffer：线程安全
StringBuilder：线程不安全，单在单线程中，性能比StringBuffer好

区别在于StringBuffer支持并发操作，线性安全的，适 合多线程中使用。StringBuilder不支持并发操作，线性不安全的，不适合多线程中使用。新引入的StringBuilder类不是线程安全的，但其在单线程中的性能比StringBuffer高。

由此可见，如果我们的程序是在单线程下运行，或者是不必考虑到线程同步问题，我们应该优先使用StringBuilder类；如果要保证线程安全，自然是StringBuffer。
详细可见  
http://blog.csdn.net/rmn190/article/details/1492013
http://blog.csdn.net/mad1989/article/details/26389541

<br/>
## **9.final，finally, finalize的区别**
**final** 用于声明属性，方法和类，分别表示属性不可交变，方法不可覆盖，类不可继承。
**finally** 是异常处理语句结构的一部分，表示总是执行。
**finalize**是Object类的一个方法，在垃圾收集器执行的时候会调用被回收对象的此方法，供垃圾收集时的其他资源回收，例如关闭文件等。

详细可见：	
http://jingyan.baidu.com/article/597a064363b676312b5243ad.html

<br/>
## **10.数组与链表的区别，哪个访问更快**

**数组：**静态分配连续的存储空间，每个元素的占用的内存大小相同，可以通过下表快速访问任以元素，访问速度快，但是插入删除要移动大量元素，所以不适合做用于存储需要频繁该改变的数据。

**链表：**动态分配内存，不连续，通过指针联系，如果要访问链表中一个元素，需要从第一个元素开始，一直找到需要的元素位置。但是增加和删除一个元素对于链表数据结构就非常简单了，只要修改元素中的指针就可以了。如果应用需要经常插入和删除元素你就需要用链表数据结构了。 

总结：
数组静态分配内存，链表动态分配内存，不易造成浪费； 
数组在内存中连续，链表不连续； 
数组元素在栈区，链表元素在堆区； 
数组利用下标定位，时间复杂度为O(1)，链表定位元素时间复杂度O(n)； 
数组插入或删除元素的时间复杂度O(n)，链表的时间复杂度O(1)。 
详细可见：
http://blog.csdn.net/wangshihui512/article/details/9787699

<br/>
## **11.java的垃圾处理机制**
**概念：**在C++中，对象所占的内存在程序结束运行之前一直被占用，在明确释放之前不能分配给其它对象；而在Java中，当没有对象引用指向原先分配给某个对象的内存时，该内存便成为垃圾。JVM的一个系统级线程会自动释放该内存块。垃圾收集意味着程序不再需要的对象是”无用信息”，这些信息将被丢弃。当一个对象不再被引用的时候，内存回收它占领的空间，以便空间被后来的新对象使用。

**优点：**
 1）垃圾回收能自动释放内存空间，减轻编程的负担
 2）有效的减少内存泄漏

**缺点：**
垃圾回收的一个潜在的缺点是它的开销影响程序性能。Java虚拟机必须追踪运行程序中有用的对象，而且最终释放没用的对象。这一个过程需要花费处理器的时间。 


在HotSpot虚拟机中，物理的将内存分为两个—年轻代(young generation)和老年代(old generation)。

**年轻代：**新创建的对象都存放在这里。因为大多数对象很快变得不可达，所以大多数对象在年轻代中创建，然后消失。当对象从这块内存区域消失时，我们说发生了一次“minor GC”。

**老年代：**没有变得不可达，存活下来的年轻代对象被复制到这里。这块内存区域一般大于年轻代。因为它更大的规模，GC发生的次数比在年轻代的少。对象从老年代消失时，我们说“major GC”（或“full GC”）发生了。

**mimor GC**（发生在年轻代中）
为了理解GC，我们学习一下年轻代，对象第一次创建发生在这块内存区域。年轻代分为3块，Eden区和2个Survivor区。

年轻代总共有3块空间，其中2块为Survivor区。各个空间的执行顺序如下：

绝大多数新创建的对象分配在Eden区。

在Eden区发生一次GC后，存活的对象移到其中一个Survivor区。

在Eden区发生一次GC后，对象是存放到Survivor区，这个Survivor区已经存在其他存活的对象。

一旦一个Survivor区已满，存活的对象移动到另外一个Survivor区。然后之前那个空间已满Survivor区将置为空，没有任何数据。

经过重复多次这样的步骤后依旧存活的对象将被移到老年代。

major GC (又叫full GC，发生在啊老年代中)
当老年代数据满时，基本上会执行一次GC，使数据从老年代消失时

详细可见：
http://www.importnew.com/20354.html
http://lemote.blog.163.com/blog/static/1748395072013111641050934/

<br/>
## **12.java内存泄漏**

在C++中，内存泄漏的范围更大一些。有些对象被分配了内存空间，然后却不可达，由于C++中没有GC，这些内存将永远收不回来。在Java中，这些不可达的对象都由GC负责回收，因此程序员不需要考虑这部分的内存泄露。

在Java中，内存泄漏就是存在一些被分配的对象，这些对象有下面两个特点，首先，这些对象是可达的，即在有向图中，存在通路可以与其相连；其次，这些对象是无用的，即程序以后不会再使用这些对象。如果对象满足这两个条件，这些对象就可以判定为Java中的内存泄漏，这些对象不会被GC所回收，然而它却占用内存。

所以在Java中也有内存泄漏，但范围比C++要小一些。因为Java从语言上保证，任何对象都是可达的，所有的不可达对象都由GC管理。

![这里写图片描述](http://img.blog.csdn.net/20161229230246863?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

详细可见：		
https://www.ibm.com/developerworks/cn/java/l-JavaMemoryLeak/

<br/>
## **13.进程及线程**
一个进程是一个独立(self contained)的运行环境，它可以被看作一个程序或者一个应用。而线程是在进程中执行的一个任务。Java运行环境是一个包含了不同的类和程序的单一进程。线程可以被称为轻量级进程。线程需要较少的资源来创建和驻留在进程中，并且可以共享进程中的资源。
[阮一峰：进程与线程的一个简单解释](http://www.ruanyifeng.com/blog/2013/04/processes_and_threads.html)
[JAVA多线程和并发基础面试问答](JAVA%E5%A4%9A%E7%BA%BF%E7%A8%8B%E5%92%8C%E5%B9%B6%E5%8F%91%E5%9F%BA%E7%A1%80%E9%9D%A2%E8%AF%95%E9%97%AE%E7%AD%94)

<br/>
## **14.同步及异步**
**同步：**指一个进程在执行某个请求的时候，若该请求需要一段时间才能返回信息，那么这个进程将会一直等待下去，直到收到返回信息才继续执行下去；		

**异步：**指进程不需要一直等下去，而是继续执行下面的操作，不管其他进程的状态。当有消息返回时系统会通知进程进行处理，这样可以提高执行的效率。

<br/>
## **15.死锁**
两个线程或两个以上线程都在等待对方执行完毕才能继续往下执行的时候就发生了死锁。结果就是这些线程都陷入了无限的等待中。

**死锁的四个条件是：**
禁止抢占：no preemption
持有和等待：hold and wait
互斥：mutual exclusion
循环等待：circular waiting

**死锁的消除**
最简单的消除死锁的办法是重启系统。更好的办法是终止一个进程的运行。可以把一个或多个进程回滚到先前的某个状态。
详细可见:
https://zh.wikipedia.org/wiki/%E6%AD%BB%E9%94%81

<br/>
## **16.生产者消费者架构**
(在并发编程中使用生产者和消费者模式能够解决绝大多数并发问题。该模式通过平衡生产线程和消费线程的工作能力来提高程序的整体处理数据的速度。)

生产者消费者问题（英语：Producer-consumer problem），也称有限缓冲问题（英语：Bounded-buffer problem），是一个多线程同步问题的经典案例。该问题描述了两个共享固定大小缓冲区的线程——即所谓的“生产者”和“消费者”——在实际运行时会发生的问题。生产者的主要作用是生成一定量的数据放到缓冲区中，然后重复此过程。与此同时，消费者也在缓冲区消耗这些数据。该问题的关键就是要保证生产者不会在缓冲区满时加入数据，消费者也不会在缓冲区中空时消耗数据。
要解决该问题，就必须让生产者在缓冲区满时休眠（要么干脆就放弃数据），等到下次消费者消耗缓冲区中的数据的时候，生产者才能被唤醒，开始往缓冲区添加数据。同样，也可以让消费者在缓冲区空时进入休眠，等到生产者往缓冲区添加数据之后，再唤醒消费者。通常采用进程间通信的方法解决该问题，常用的方法有信号灯法[1]等。如果解决方法不够完善，则容易出现死锁的情况。出现死锁时，两个线程都会陷入休眠，等待对方唤醒自己。

生产者消费者模式
产者消费者模式是通过一个容器来解决生产者和消费者的强耦合问题。生产者和消费者彼此之间不直接通讯，而通过阻塞队列来进行通讯，所以生产者生产完数据之后不用等待消费者处理，直接扔给阻塞队列，消费者不找生产者要数据，而是直接从阻塞队列里取，阻塞队列就相当于一个缓冲区，平衡了生产者和消费者的处理能力。

用处广泛
Java中的线程池类其实就是一种生产者和消费者模式的实现方式，但是实现方法更高明。生产者把任务丢给线程池，线程池创建线程并处理任务，如果将要运行的任务数大于线程池的基本线程数就把任务扔到阻塞队列里，这种做法比只使用一个阻塞队列来实现生产者和消费者模式显然要高明很多，因为消费者能够处理直接就处理掉了，这样速度更快，而生产者先存，消费者再取这种方式显然慢一些。


(补充:什么是阻塞队列？如何使用阻塞队列来实现生产者-消费者模型？
java.util.concurrent.BlockingQueue的特性是：当队列是空的时，从队列中获取或删除元素的操作将会被阻塞，或者当队列是满时，往队列里添加元素的操作会被阻塞。
阻塞队列不接受空值，当你尝试向队列中添加空值的时候，它会抛出NullPointerException。
阻塞队列的实现都是线程安全的，所有的查询方法都是原子的并且使用了内部锁或者其他形式的并发控制。
BlockingQueue接口是java collections框架的一部分，它主要用于实现生产者-消费者问题。)
详细可见：
http://www.infoq.com/cn/articles/producers-and-consumers-mode
https://zh.wikipedia.org/wiki/%E7%94%9F%E4%BA%A7%E8%80%85%E6%B6%88%E8%B4%B9%E8%80%85%E9%97%AE%E9%A2%98

<br/>
## **17.set用法**
http://www.cnblogs.com/TimeStory/p/3858479.html

<br/>
## **18.设计模式之设计原则**

**1) 单一职责原则(SRP)** 
定义：就一个类而言，应该仅有一个引起它变化的原因。 

**2)  开放封闭原则(ASD)** 
定义：类、模块、函数等等等应该是可以拓展的，但是不可修改。

**3) 里氏替换原则(LSP)** 
定义：所有引用基类（父类）的地方必须能透明地使用其子类的对象替换

**4) 依赖倒置原则(DIP)** 
定义：高层模块不应该依赖低层模块，两个都应该依赖于抽象。抽象不应该依赖于细节，细节应该依赖于抽象。 

**5) 迪米特原则(LOD)** 
定义：一个软件实体应当尽可能少地与其他实体发生相互作用。 

**6) 接口隔离原则(ISP)** 
定义：一个类对另一个类的依赖应该建立在最小的接口上。 也就是说，我们要为各个类建立专用的接口，而不要试图去建立一个很庞大的接口供所有依赖它的类去调用。 

详细可见：		
http://blog.csdn.net/itachi85/article/details/50491657

<br/>
## **19.抽象类与接口的区别**
![这里写图片描述](http://img.blog.csdn.net/20161230000616380?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


![这里写图片描述](http://img.blog.csdn.net/20161230000636824?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvRlpXX0ZhaXRo/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
		
详细可见：
http://www.importnew.com/12399.html

