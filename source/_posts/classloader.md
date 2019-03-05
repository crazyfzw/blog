---
title: Java 虚拟机 3 ：Java的类加载机制
date: 2018-07-05 21:44:31
categories:
- JVM
tags:
- 类加载机制
- 类加载
- classLoder
- JVM
- 类的生命周期
- 双亲委派模型
- 委托机制
---

## 一、Class文件
在开始讲类加载机制之前，不妨先来了解一下 java 中的这个 ”类“。我们都知道 java 最著名的优点之一就是 摆脱了硬件平台的束缚，实现了”一次编写、到处运行“，那么 java 是怎么做到这种跨平台的呢？答案是通过  虚拟机 + “字节码”。

1. java程序在编译时并不直接编译成依赖于平台的特定机器语言，而是编译成与平台无关的"字节码"，由java虚拟机来执行，java虚拟机执行的时候才将字节码翻译成目标平台对应的机器指令代码。

2. 不同平台的不同虚拟机都可以载入和执行这种平台无关的“字节码”。

这种具有特定的二进制文件格式的“字节码”就是 “Class文件”，即类加载机制中的“类”。

![](/images/2018071001.png)


class文件一组以8位字节为单位的二进制流，由无符号数和表两种数据类型组成组成，无符号数实质上就是不同大小的字节，u1、u2、u4、u8分别代表1、2、4、8个字节；表是由多个无符号数或者其他表作为数据项构成的复合数据类型。

**class类文件由以下部分组成： **
- 魔数
- 次版本
- 主版本
- 常量池
- 类访问标识
- 此类信息常量池索引
- 父类信息常量池索引
- 接口集合常量池索引
- 字段表集合
- 方法表集合
- 类属性集合

## 二、类的生命周期
类从被加载到虚拟机内存中开始，到卸载出内存，它的整个生命周期包括：加载（Loading）、验证（Verification）、准备（Preparation）、解析（Resolution）、初始化（Initiallization）、使用（Using）和卸载（Unloading）这7个阶段。其中验证、准备、解析3个部分统称为连接（Linking），这7个阶段的发生顺序如下图：
![](/images/2018071002.png)


图中，加载、验证、准备、初始化、卸载这5个阶段的顺序是确定的，类的加载过程必须按照这种顺序按部就班地开始，而解析阶段不一定：它在某些情况下可以在初始化阶段之后才开始，这是为了支持Java语言的运行时绑定（也称为动态绑定）。

## 三、类加载的时机

类加载的时机主要还是依赖于初始化的时机。虚拟机规定有且仅有5种情况会触发类的初始化 ，而在初始化之前，自然是要先经过加载、验证、准备的，所以类加载的时机依主要还是看什么情况下会触发类的初始化。下文中会详细讲下类初始化的触发条件。

## 四、类加载的过程

### 加载
把数据从 Class 文件加载到内存，有预加载和运行时加载2种：

**1、预加载：**虚拟机启动时，会加载 JAVA_HOME/lib/ 下的 rt.jar 中 .class 文件，这个 jar 包里面的内容是程序运行时非常可能会用到的基础类，像 java.lang.*、java.util.*、java.io.*等，因此随着虚拟机一起加载。可以写一个空的main函数，设置虚拟机参数为 "-XX:+TraceClassLoading"，运行一下 

![](/images/2018071003.png)

![](/images/2018071004.png)
...

**2、运行时加载：**虚拟机会根据类的全限定名在内存中查找是否已经加载了这个类，如果没有，则会通过委托机制（双亲委派模型，后面会细讲）加载这个类。在加载阶段，虚拟机做了以下3件事情：
1) 根据全限定名 获取 .class 文件的二进制字节流；
2）将字节流所代表的静态存储结构转化为方法区的运行时数据结构；
3）在内存中生成一个代表这个类的 java.lang.Class 对象，作为方法区这个类的各种数据访问入口。


### 验证
验证是连接阶段的第一步，这一阶段的目的是为了确保.class文件的字节流中包含的信息符合当前虚拟机的要求，并且不会危害虚拟机自身的安全。 虚拟机如果不检查输入的字节流，对其完全信任的话，很可能会因为载入了有害的字节流而导致系统崩溃，所以验证是虚拟机对自身保护的一项重要工作。

验证阶段主要会完成下面4个阶段的校验动作：文件格式验证、元数据验证、字节码验证、符号引用验证。

**1.文件格式验证**
验证字节流是否符合 Class 文件格式的规范，并且能够被当前版本的虚拟机处理。

- 是否以魔数 0xCAFEBABE 开头

- 主次版本号是否在当前虚拟机处理范围之内，紧接着魔数的4个字节存储的是 Class 文件的版本号：第5和第6是次版本号，第7和弟8个字节是主版本号。高版本的JDK能向下兼容以前版本的.class文件，但不能运行以后的class文件。比如：在JDK1.7下编译生成的Class文件，那么JDK1.7及以上的版本能运行这个 Class 文件，但是JDK1.6乃更低的JDK版本是无法运行 Class文件的。

- 常量池中的常量是否有不被支持的常量类型；

- 指向常量的各种索引值中是否有指向不存在的常量或不符合类型的常量；

- CONSTANTUtf8info型的常量中是否有不符合UTF8编码的数据；

- Class文件中各个部分及文件本身是否有被删除的或附加的其他信息。

 等等

**2.元数据验证**
主要目的是对类的元数据信息进行语义校验，保证不存在不符合 Java 语言规范的元数据信息。

- 这个类是否有父类；
- 这个类的父类是否继承了不准许被继承的类；
- 如果这个类不是抽象类,是否实现了其父类或者接口之中要求实现的所有方法；
- 类中的字段方法是否与父类产生矛盾。
 等等


**3.字节码验证**

对方法体进行校验，主要目的是通过数据流和控制流分析，确定程序语义是合法的、符合逻辑的。

- 保证任意时刻操作数栈的数据类型与指令代码序列都能配合工作；
- 保证跳转指令不会跳转到方法体以外的字节码指令上；
- 保证方法体中的类型转换是有效的。
等等

**4.符号引用验证**
目的是确保解析动作能正常进行，如果无法通过符号引用验证，抛出  java.lang.NoSuchFieldError、java.lang.NoSuchMethodError、java.lang.IIegalAccessError 等。

- 符号引用中通过字符串描述的全限定名是否找到相应的类；
- 在指定的类中是否存在符合方法的字段描述符以及简单名称说描述的方法和字段；
- 符号引用中的类、字段、方法的访问性是否被当前类访问。

### 准备
准备阶段是正式为类变量分配内存并设置其初始值的阶段，这些变量所使用的内存都将在方法区中分配。关于这点，有两个地方注意一下：

1、这时候只会对类变量（被static修饰的变量）进行内存分配，而不会给实例变量分配内存，，实例变量将会在对象实例化的时候随着对象一起分配在Java堆中；

2、在准备阶段，对于非final修饰的static变量，设置的初始值为数据类型的零值，对于 被final修饰的 static变量，则会直接赋予所指定的值。
比如"public static int value = 123;"，value在准备阶段过后是0而不是123，给value赋值为123的动作将在初始化阶段才进行；而"public static final int value = 123;"就不一样了，在准备阶段，虚拟机就会给value直接赋值为123。

基本数据类型的零值如下表：

| 数据类型 | 零值 | 数据类型 | 零值 |
|----------|-----------|-----------|-----------|
|  int | 0 | boolean | false |
| long | 0L | float | 0.0f |
| short | (short) 0 | double | 0.0d |
| char | '\u0000' | reference | |
| byte | (byte) 0 | - |  - | 


### 解析
解析动作主要针对类或接口、字段、类方法、接口方法、方法类型、方法句柄和调用点限定符7类符号引用进行。解析阶段是虚拟机将常量池内的符号引用替换为直接引用的过程。那么，符号引用与直接引用又有什么区别呢？

**1、符号引用**
符号引用以一组符号来描述所引用的目标，定义在java虚拟机规范中的Class文件格式中，它与虚拟机实现的内存布局无关，引用的目标并不一定加载到内存中。

符号引用包含了下面3种信息：

- 类和接口的全限定名

- 字段的名称和描述符

- 方法的名称和描述符


下面写个简单的例子，然后先用 javac 编译出二进制字节码，然后再用 jdk 自带的反编译工具 javap 反编译输出常量表。

{% codeblock lang:java%}
public class TestClass {

	private int n;
	
	public int increase() {
		return n + 1;
	}
}
{% endcodeblock %}

![](/images/2018071005.png)

结果如下：
![](/images/2018071006.png)


Constant Pool 的结果中，带"Utf8"的就是符号引用，比如 #8 为 n, #9 为 I, 表示的是 int 型的变量 n。

**2、直接引用**
直接引用可以是直接指向目标的指针、相对偏移量或是一个能间接定位到目标的句柄。直接引用是和虚拟机实现的内存布局相关的，如果有了直接引用，那引用的目标必定已经存在在内存中了。同一个符号引用在不同的虚拟机示例上翻译出来的直接引用一般不会相同。

### 初始化
初始化阶段是类加载过程的最后一步，到了初始化阶段，才真正开始执行类中定义的 java 程序代码（或者说是字节码）

**初始化阶段主要做了以下2件事：**

1. 给静态变量赋予指定的值，需要注意区别的是，在准备阶段，给静态变量设置的初始值是类型的零值，到了初始化阶段才会赋予程序实际指定的值。

2. 执行静态代码块

注意一下，虚拟机会保证类的初始化在多线程环境中被正确地加锁、同步，即如果多个线程同时去初始化一个类，那么只会有一个类去执行这个类的<clinit>()方法，其他线程都要阻塞等待，直至活动线程执行<clinit>()方法完毕。因此如果在一个类的<clinit>()方法中有耗时很长的操作，就可能造成多个进程阻塞。不过其他线程虽然会阻塞，但是执行<clinit>()方法的那条线程退出<clinit>()方法后，其他线程不会再次进入<clinit>()方法了，因为同一个类加载器下，一个类只会初始化一次。

**初始化的时机（触发条件）**
虚拟机规定有且仅有以下5种情况会触发类的初始化  （而加载、验证、准备自然需要在此之前开始）：
1. 使用 new 关键字实例化对象的时候，读取或设置一个类的静态字段（该字段不被 final 修饰）的时候，以及调用一个类的静态方法的时候；
2. 使用 java.lang.reflect 包的方法对类进行反射调用的时候；
3. 当初始化一个类的时候,如果发现其父类还没有进行过初始化，则需要先初始化其父类；
4. 当虚拟机启动的时候,用户需要指定一个要执行的主类(包含 main 方法的那个类)，虚拟机需要先初始化这个主类；
5. 当使用JDK1.7的动态语言支持时，如果一个 java.lang.invoke.MethodHandle 实例最后的解析结果为 REFgetStatic、REFputStatic、REF_invokeStatic 的方法句柄,并且这个方法句柄所对应的类没有进行过初始化。

以上5种称为对类的主动引用，只有主动引用才会触发对类的初始化，除此之外，所有引用类的方式都不会触发初始化，称为被动引用，常见的有下面3种：

**1、通过子类引用父类静态字段，不会导致子类初始。**

{% codeblock lang:java%}
public class SuperClass
{
    public static int value = 123;
    
    static
    {
        System.out.println("SuperClass init");
    }
}
{% endcodeblock %}

{% codeblock lang:java%}
public class SubClass extends SuperClass
{
    static
    {
        System.out.println("SubClass init");
    }
}
{% endcodeblock %}

{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
        System.out.println(SubClass.value);
    }
}
{% endcodeblock %}

运行结果：
![](/images/2018071007.png)


**2、通过数组定义引用类，不会触发此类的初始化**

{% codeblock lang:java%}
public class SuperClass
{
    public static int value = 123;
    
    static
    {
        System.out.println("SuperClass init");
    }
}
{% endcodeblock %}

{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
        SuperClass[] supArr= new SuperClass[10];
    }
}
{% endcodeblock %}

运行结果：
![](/images/2018071008.png)


**3、引用常量时，常量在编译阶段会存入类的常量池中，本质上并没有直接引用到定义常量的类，因此也不会触发类的初始化。**

{% codeblock lang:java%}
public class ConstClass
{
    public static final String HELLOWORLD =  "Hello World";
    
    static
    {
        System.out.println("ConstCLass init");
    }
}
{% endcodeblock %}

{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
        System.out.println(ConstClass.HELLOWORLD);
    }
}
{% endcodeblock %}

运行结果：
![](/images/2018071009.png)



## 五、类与类加载器
Java 代码要想运行，首先需要将源代码进行编译生成 .class 文件，然后把 .class 字节码文件加载到 JVM  中运行，实现这个加载动作的程序就是类加载器。在类加载阶段，类加载器负责通过一个类的全限定名来获取此类的二进制字节流。

类加载器虽然只用于实现类的加载动作，但它在Java程序中起到的作用却远远不限定于类加载阶段。对于任意一个类，都需要由加载它的类加载器和这个类本身一同确立其在Java虚拟机中的唯一性，每一个类加载器，都拥有一个独立的类名称空间。通俗点说就是：比较两个类是否"相等"，只有在这两个类是由同一个类加载器加载的前提下才有意义，否则即使这两个类来源于同一个.class文件，被同一个虚拟机加载，只要加载它们的类加载器不同，这两个类必定不相等。

Java为我们提供了3种原生的类加载器：分别是启动类加载器（Bootstrap ClassLoader）、拓展类加载器（Extension ClassLoader）、应用程序类加载器（Application ClassLoader）。除此之外，用户还可以根据自己的需要自定义类加载器。

下面分别详细介绍下3种原生的类加载器：


### 启动类加载器

启动类加载器，又称引导类加载器。区别于那些由独立于虚拟机外部、由java语言实现的类加载器，启动类加载器使用C++实现，是虚拟机自身的一部分。主要负责加载 <JAVA_HOME>\lib 目录下 rt.jar、resources.jar、charsets.jar 等 java 核心类库。

通过下面代码我们可以查看启动类加载器的扫描路径：

{% codeblock lang:java%}
public class TestMain {

	public static void main(String[] args) {
        URL[] urls = sun.misc.Launcher.getBootstrapClassPath().getURLs();    
        for (int i = 0; i < urls.length; i++) {    
            System.out.println(urls[i].toExternalForm());    
        }  
	}
}
{% endcodeblock%}

运行结果如下：
![](/images/2018071301.png)


### 拓展类加载器

扩展类加载器，由 sun.misc.Launcher$ExtClassLoader 实现，主要负责加载 Java 的扩展类库，默认加载 JAVA_HOME/jre/lib/ext/ 目录下的所有 Jar 包或者由 java.ext.dirs 系统属性指定的 Jar 包。


通过下面代码我们可以查看启动类加载器的扫描路径：
{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
       System.out.println(System.getProperty("java.ext.dirs"));
    }
}
{% endcodeblock%}

运行结果：
```
E:\Program Files\Java\jdk1.8.0_91\jre\lib\ext;C:\Windows\Sun\Java\lib\ext
```


### 应用程序类加载器
应用程序类加载器，又称系统类加载器。由 sun.misc.Launcher$AppClassLoader 实现，负责在 JVM 启动时，加载来自在命令java中的-classpath或者java.class.path系统属性或者 CLASSPATH 操作系统属性所指定的 JAR 类包和类路径。调用 ClassLoader.getSystemClassLoader() 可以获取该类加载器。如果没有特别指定，则用户自定义的任何类加载器都将该类加载器作为它的父加载器。

执行以下代码即可获得 classpath 加载路径：
{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
        System.out.println(ClassLoader.getSystemClassLoader());
    }
}
{% endcodeblock%}

运行结果：
```
sun.misc.Launcher$AppClassLoader@73d16e93
```


### 3种原生类加载器的关系

![](/images/2018071401.png)


需要注意2点：
- AppClassloader 的父加载器是 ExtClassloader。
- ExtClassloader 的父加载器为 null，但是要注意的是 ExtClassloader 的父加载器并不是 BootstrapClassloader。


执行以下代码验证下:
{% codeblock lang:java%}
public class TestMain
{
    public static void main(String[] args)
    {
		  System.out.println(ClassLoader.getSystemClassLoader());
		  System.out.println(ClassLoader.getSystemClassLoader().getParent());
		  System.out.println(ClassLoader.getSystemClassLoader().getParent().getParent());
    }
}
{% endcodeblock%}

运行结果：
```
sun.misc.Launcher$AppClassLoader@73d16e93
sun.misc.Launcher$ExtClassLoader@15db9742
null
```

根据结果可以看出：Application ClassLoader 是系统类加载器；Application ClassLoader 的父加载器确实是 Extension ClassLoader。那么为什么 ExtClassLoader 的父加载器为 null 呢？原因是因为 Bootstrap ClassLoader 以外的ClassLoader 都是Java实现的，因此这些 ClassLoader 势必在 Java 堆中有一份实例在，所以 Extension ClassLoader 和 Application ClassLoader 都能打印出实现类。但是Bootstrap ClassLoader 是JVM的一部分，是用 C++ 写的，不属于Java，自然在Java堆中也没有自己的空间， BootstrapClassloader 对 Java 不可见，所以就返回null了。

## 六、双亲委派模型（类的加载机制：委托机制）

Java 类加载器使用的是委托机制，也就是一个类加载器在加载一个类时候会首先尝试委派给父类加载器来加载。类加载器之间的层次关系如下图所示，称为类加载器的双亲委派模型。

![](/images/2018071402.png)


### 双亲委派模型的工作过程：
如果一个类加载器收到类加载的请求，它首先不会自己尝试去加载这个类，而是把这个请求委派给父类加载器去完成，并且每一个层次的类加载器都是如此，因此所有的加载请求，最终都应该传送到顶层的启动类加载器中，只有当父加载器反馈无法完成这个加载请求（它的搜索范围中没有找到所需的类），子类加载器才会尝试自己去加载。



下面从源码看如何实现委托机制：

{% codeblock lang:java%}
protected Class<?> loadClass(Stringname,boolean resolve)  
       throws ClassNotFoundException  
   {  
       synchronized (getClassLoadingLock(name)) {  
           // 首先从jvm缓存查找该类
           Class c = findLoadedClass(name); // (1)
           if (c ==null) {  
               longt0 = System.nanoTime();  
               try {  //然后委托给父类加载器进行加载
                   if (parent !=null) {  
                       c = parent.loadClass(name,false);  (2)
                   } else {  //如果父类加载器为null,则委托给BootStrap加载器加载
                       c = findBootstrapClassOrNull(name);  (3)
                   }  
               } catch (ClassNotFoundExceptione) {  
                   // ClassNotFoundException thrown if class not found  
                   // from the non-null parent class loader  
               }  

               if (c ==null) {  
                   // 若仍然没有找到则调用findclass查找
                   // to find the class.  
                   longt1 = System.nanoTime();  
                   c = findClass(name);  (4)

                   // this is the defining class loader; record the stats  
                   sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 -t0);  
                   sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);  
                   sun.misc.PerfCounter.getFindClasses().increment();  
               }  
           }  
           if (resolve) {  
               resolveClass(c);  //（5）
           }  
           returnc;  
       }  
   }  

{% endcodeblock%}

代码（1）表示从 JVM 缓存查找该类，如果该类之前被加载过，则直接从 JVM 缓存返回该类。

代码（2）表示如果 JVM 缓存不存在该类，则看当前类加载器是否有父加载器，若有则委托父类加载器进行加载，否者调用（3），委托 BootStrapClassloader 进行加载，如果还是没有找到，则调用当前 Classloader 的 findclass 方法进行查找。

代码（5）则是当字节码加载到内存后进行链接操作，对文件格式和字节码验证，并为 static 字段分配空间并初始化，符号引用转为直接引用，访问控制，方法覆盖等。

从上面源码知道要想修改类加载委托机制，实现自己的载入策略，可以通过覆盖 ClassLoader 的 findClass 方法或者覆盖 loadClass 方法来实现。


### 为什么要使用委托加载机制?

1. 避免重复加载，当父类加载器已经加载了该类的时候，就没有必要子 ClassLoader 再加载一次。

2. Java类随着它的加载器一起具备了一种带有优先级的层次关系。例如java.lang.Object，存放于rt.jar中，无论哪一个类加载器要去加载这个类，最终都是由Bootstrap ClassLoader去加载，因此Object类在程序的各种类加载器环境中都是一个类。相反，如果没有双亲委派模型，由各个类自己去加载的话，如果用户自己编写了一个java.lang.Object，并放在CLASSPATH下，那系统中将会出现多个不同的Object类，Java体系中最基础的行为也将无法保证，应用程序也将会变得一片混乱。


## 七、参考文献
《深入理解Java虚拟机》 – 周志明 第六章、第七章
[https://www.ibm.com/developerworks/cn/java/j-lo-classloader/index.html](https://www.ibm.com/developerworks/cn/java/j-lo-classloader/index.html)
[http://www.infoq.com/cn/articles/cf-Java-class-loader](http://www.infoq.com/cn/articles/cf-Java-class-loader)
[http://ifeve.com/jvm-classloader/](http://ifeve.com/jvm-classloader/)
[https://gitbook.cn/books/5a7719e7367c47172bea2b53/index.html](https://gitbook.cn/books/5a7719e7367c47172bea2b53/index.html)
[http://www.cnblogs.com/xrq730/p/4845144.html](http://www.cnblogs.com/xrq730/p/4845144.html)
[http://www.cnblogs.com/xrq730/p/4844915.html](http://www.cnblogs.com/xrq730/p/4844915.html)


