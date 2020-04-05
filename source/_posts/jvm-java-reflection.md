---
title: Java 虚拟机 4 ：Java的反射机制
date: 2018-07-07 10:54:50
categories:
- JVM
tags:
- 反射机制
- java反射
- java反射-Fields
- java反射-Classes
- Java反射-Method
- Java反射-Annotation
- 动态调用
- JVM
---
 
## 一、什么是反射

在Java运行时环境中，对于任意一个类，能否知道这个类有哪些属性和方法？对于任意一个对象，能否调用它的任意一个方法？答案是肯定的。这种动态获取类的信息，以及动态调用对象的方法的功能来自于Java语言的反射（Reflection）机制。

<!--more-->

Java反射机制主要提供了以下功能：
- 在运行时判断任意一个对象所属的类；
- 在运行时构造任意一个类的对象；
- 在运行时判断任意一个类所具有的成员变量和方法；
- 在运行时调用任意一个对象的方法；
- 生成动态代理。


在JDK中，主要由以下类来实现Java反射机制，这些类都位于java.lang.reflect包中：
- Class类： 代表一个类；
- Field类：代表类的成员变量（成员变量也称为类的属性）；
- Method类：代表类的方法；
- Constructor类：代表类的构造方法；
- Array类：提供了动态创建数组，以及访问数组元素的静态方法。

## 二、java反射的作用(应用)

>Java Reflection makes it possible to inspect classes, interfaces, fields and methods at runtime, without knowing the names of the classes, methods etc. at compile time. It is also possible to instantiate new objects, invoke methods and get/set field values using reflection.

**上面几句话概括了java反射机制的2个核心作用：**
Java反射机制可以让我们在编译期(Compile Time)之外的运行期(Runtime)动态获取类，接口，变量以及方法等信息。反射机制还可以让我们在运行期实例化对象，动态调用对象的方法。下面详细写下java机制的这2个核心作用。


### 1、获取程序在运行时刻的内部结构（动态获取类的信息）

Java 反射的第一个主要作用是获取程序在运行时刻的内部结构。这对于程序的检查工具和调试器来说，是非常实用的功能。只需要短短的十几行代码，就可以遍历出来一个Java类的内部结构，包括其中的构造方法、声明的域和定义的方法等。

以下例子用反射获取类的对象，然后通过这个对象获取这个类的所有 public 方法:

{% codeblock lang:java%}
public class ReflectionDemo {

	public void sayHi(){
		System.out.println("hi");
	}
	
	public void sayHello(){

		System.out.println("hello");
	}
	
	public static void main(String[] args) {

		Method[] methods = ReflectionDemo.class.getMethods();
	
		for(Method method : methods){

		    System.out.println("method = " + method.getName());
	
		}
	}
}
{% endcodeblock%}

运行结果：
![](/images/2018070901.png)


### 2、在运行时刻对一个Java对象进行操作（动态调用对象的方法）

java反射的另外一个作用是在运行时刻对一个Java对象进行操作。这些操作包括动态创建一个Java类的对象，获取某个域的值以及调用某个方法。在Java源代码中编写的对类和对象的操作，都可以在运行时刻通过反射API来实现。

{% codeblock lang:java%}
public class Rectangle {
	
	private int length;  //长
	private int width;   //宽
	
	public Rectangle(int length, int width) {
        this.length = length;
        this.width = width;
    }
	
	public int getArea(){
		return length * width;
	}

}
{% endcodeblock%}

{% codeblock lang:java%}
public class MainText {

	public static void main(String[] args) {
		/**
		 * 获取对象调用方法的传统写法
		 */
		Rectangle rectangle0 = 	new Rectangle(3, 4);
		System.out.println("长方形rectangle0的面积是："+rectangle0.getArea());
		
	        /**
	         * 通过java反射动态调用对象的写法
	         */
		try {			
		    Constructor constructor = Rectangle.class.getConstructor(int.class, int.class); //获取构造方法
		    Rectangle rectangle1 = (Rectangle) constructor.newInstance(4,5);                //创建对象
		    Method method = Rectangle.class.getMethod("getArea");                           //获取方法
		    System.out.println("长方形rectangle1的面积是："+method.invoke(rectangle1));      //调用方法
		} catch (Exception e) { 
		    e.printStackTrace();
		} 
	}
}
{% endcodeblock%}

运行结果：
![](/images/2018070902.png)


## 三、java反射机制的详细用法

在JDK中，主要由以下类来实现Java反射机制，这些类都位于java.lang.reflect包中。
- Class类： 代表一个类。
- Field类：代表类的成员变量（成员变量也称为类的属性）。
- Method类：代表类的方法。
- Constructor类：代表类的构造方法。
- Array类：提供了动态创建数组，以及访问数组元素的静态方法。


### 1.Java反射-Classes

| Method | Description |
| ------------- |-------------|
| 1) public String getName() | 返回含包名的完整类名 |
| 3) public static Class forName(String className)throws ClassNotFoundException | 加载类并返回Class对象 |
| 4) public Object newInstance()throws InstantiationException,IllegalAccessException | 创建实例对象 |
| 5) public Class getSuperclass() | 返回父类Class引用 |
| 6) public Field[] getFields()throws SecurityException  | 获取类的public类型的属性 |
| 7) public Field[] getDeclaredFields()throws SecurityException  | 获取类的所有属性 |
| 8) public Method[] getMethods()throws SecurityException  | 获取类的public类型的方法 |
| 9) public Method[] getDeclaredMethods() | 获取类的所有类型的方法 |
| 10) public Method getDeclaredMethod(String name,Class[] parameterTypes)throws NoSuchMethodException,SecurityException |  返回类中指定参数类型的方法 |
| 12) public Constructor[] getDeclaredConstructors()throws SecurityException | 获取类的构造方法数组 |           
| 13) getDeclaredConstructor(Class[] parameterTypes) | 获取类的特定构造方法，parameterTypes参数指定构造方法的参数类型 |
| 14) public boolean isInterface() | 判断是否是接口|
| 15) public boolean isArray() | 判断是否是数组 |
| 16) public boolean isPrimitive() | 判断是否是原始数据类型|


以下是根据 API 中的一些方法获取类信息的示例：

{% codeblock lang:java%}
public class MainText {

	public static void main(String[] args) throws ClassNotFoundException {

		/**
		 * 获取类
		 */
		Class class1 = MainText.class;	
		Class class2 = Class.forName("reflection.Rectangle");
		System.out.println(class2.getName());
		System.out.println(class2.getSimpleName());
				
		Package pack = class2.getPackage();     //获取包
		Field[] field = class2.getFields(); 	//获取字段
		Method[] method = class2.getMethods();  //获取方法
		Annotation[] annotations = class2.getAnnotations(); //获取注解
		Constructor[] constructors = class2.getConstructors(); //获取构造器	
		
		/**
		 * 获取修饰符并判断类型
		 */
		int modifiers = class2.getModifiers();
		//判断的值为 true or false
		Modifier.isAbstract(modifiers);
		Modifier.isFinal(modifiers);
		Modifier.isInterface(modifiers);
		Modifier.isNative(modifiers);
		Modifier.isPrivate(modifiers);
		Modifier.isProtected(modifiers);
		Modifier.isPublic(modifiers);
		Modifier.isStatic(modifiers);
		Modifier.isStrict(modifiers);
		Modifier.isSynchronized(modifiers);
		Modifier.isTransient(modifiers);
		Modifier.isVolatile(modifiers);
	}
}

{% endcodeblock%}

### 2.Java反射-Fields

通过使用 java.lang.reflect.Field , 可以在运行期访问或者改变类成员变量的值。

下面以一个简单的例子演示下获取Field的值与改变Field的值:

{% codeblock lang:java%}
public class Point {
	  private int x;      
	  public int y;    
	  
	  public Point(int x, int y) {   	  
		  super();          
		  this.x = x;          
		  this.y = y; 
	  }      
}
{% endcodeblock%}

{% codeblock lang:java%}
public class MainText {

	public static void main(String[] args) throws ClassNotFoundException, NoSuchFieldException, SecurityException, IllegalArgumentException, IllegalAccessException {

		/**
		 * 获取变量信息
		 */
		Point instanceObj = new Point(3,5);  
		Class class1 = instanceObj.getClass();	
		Field[] field1 = class1.getFields();      //获取Field 列表
		Field field2 = class1.getField("y");      //获取指定Field
		String fieldName = field2.getName();      //获取变量名
		Object fieldType = field2.getType();      //获取变量类型
		int a = field2.getModifiers();            //获取修饰符
		Modifier.isAbstract(a);                   //判断是否含某修饰符       
		System.out.println(field2.get(instanceObj));      //获取对象对应的Field值
		
		/**
		 * 改变变量的值
		 */
		field2.set(instanceObj, 6);                    //改变Field的值 
		System.out.println(field2.get(instanceObj));   //输出改变后的值

	}
}
{% endcodeblock%}

下面一个例子是网上一个比较有趣的例子，主要体现了使用Field时一些需要特别注意的地方，摘于[http://www.360doc.com/content/17/0820/17/46591991_680655030.shtml](http://www.360doc.com/content/17/0820/17/46591991_680655030.shtml)

{% codeblock lang:java%}
public class Point {
	  private int x;      
	  public int y;    
	  
	  public Point(int x, int y) {   	  
		  super();          
		  this.x = x;          
		  this.y = y; 
	  }      
}
{%  endcodeblock%}

{% codeblock lang:java%}
public class ReflectTest {
    //这里说的Field都是 类 身上的，不是实例上的  
    public static void main(String[] args) throws Exception {  
          
        Point pt1 = new Point(3,5);  
          
        //得到一个字段  
        Field fieldY = pt1.getClass().getField("y"); //y 是变量名  
        //fieldY的值是5么？？ 大错特错  
        //fieldY和pt1根本没有什么关系，你看，是pt1.getClass()，是 字节码 啊  
        //不是pt1对象身上的变量，而是类上的，要用它取某个对象上对应的值  
        //要这样  
        System.out.println(fieldY.get(pt1)); //这才是5  
        //现在要x了    
        /*  
        Field fieldX = pt1.getClass().getField("x"); //x 是变量名 
        System.out.println(fieldX.get(pt1));  
        */  
          
        //运行 报错 私有的，找不到  
        //NoSuchFieldException  
        //说明getField 只可以得到 公有的  
        //怎么得到私有的呢？？  
          
        /* 
        //这个管你公的私的，都拿来 
        Field fieldX = pt1.getClass().getDeclaredField("x");
        //然后轮到这里错了 
        // java.lang.IllegalAccessException: 
        //Class com.ncs.ReflectTest can not access a member of class com.ncs.Point with modifiers "private" 
        System.out.println(fieldX.get(pt1)); 
        */           
        //三步曲 一是不让你知道我有钱 二是把钱晃一下，不给用  三是暴力抢了  
        //暴力反射    
        Field fieldX = pt1.getClass().getDeclaredField("x"); //这个管你公的私的，都拿来  
        fieldX.setAccessible(true);//上面的代码已经看见钱了，开始抢了  
        System.out.println(fieldX.get(pt1));             
    }  
}
{%  endcodeblock%}

运行结果：
![](/images/2018070903.png)


**关于 Field 的用法需要特别注意的是下表的区别：**

![](/images/2018070904.png)

1. getField()、getFields() 方法能获得的是 public 的字段，包括父类中的字段；
2. geDeclaredField()、geDeclaredFields() 获取的包括 public、private 和 proteced 的字段，但是不包括父类的申明字段。


### 3.Java反射-Method

通过使用 java.lang.reflect.Method, 可以在运行期动态调用对象的方法。

下面写个小 demo 演示下在运行期动态调用有参方法还有无参方法:

{% codeblock lang:java%}
public class Rectangle {
	
	private int length;  //长
	private int width;   //宽

	public Rectangle(int length, int width) {
        this.length = length;
        this.width = width;
    }
	
	public int getArea(){
		return length * width;
	}
	
	public int getArea(int length, int width){
		return length * width;		
	}
}
{% endcodeblock%}

{% codeblock lang:java%}
public class MainText {

	public static void main(String[] args){


		Rectangle instanceObj = new Rectangle(3,5);  
		Class class1 = instanceObj.getClass();	
		Method method[] = class1.getMethods();              //获取所有 public 方法        		

		/**
		 * 调用无参方法
		 * 目标方法没有参数，那么在调用getMethod()方法时第二个参数传入null即可
		 */
		try {
			Method method1 = class1.getMethod("getArea", null); //获取指定的无参方法
			System.out.println(method1);
			System.out.println(method1.invoke(instanceObj, null));
		
		} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException | SecurityException e) {			
			e.printStackTrace();
		}
		
		/**
		 * 调用带参数的方法
		 * 目标方法有参数，那么在调用getMethod()方法时需要用new Class[]{} 参数对应的参数类型
		 */
		try {
			Method method2 = class1.getMethod("getArea",new Class[]{int.class, int.class});  //获取指定的带参数的方法
			System.out.println(method2);
			System.out.println(method2.invoke(instanceObj, 4,5));
		} catch (IllegalAccessException | IllegalArgumentException | InvocationTargetException | NoSuchMethodException | SecurityException e) {				
			e.printStackTrace();
		}
		
	}
}
{% endcodeblock%}

运行结果：
![](/images/2018070905.png)

**关于Method.invoke()方法需要特别注意2点：**

1. 如果是一个静态方法调用的话则可以用null代替指定对象作为invoke()的参数，如果调用的方法不是静态方法，就要传入有效的对象实例而不是null。

2. Method.invoke(Object target, Object … parameters) 的第二个参数是一个可变参数列表，必须要传入与你要调用方法的形参一一对应的实参，否则会抛出 java.lang.IllegalArgumentException:  异常。


### 4.Java反射-Annotation

利用Java反射机制可以在运行期获取Java类的注解信息，包括以下:
- 类注解
- 方法注解
- 参数注解
- 变量注解

下面通过一个例子演示一下类注解的用法：

{% codeblock lang:java%}
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface MyAnnotation {
	public String name();
	public String value();
}
{% endcodeblock%}

{% codeblock lang:java%}
@MyAnnotation(name="Java Reflection",  value = "Hello World")
public class MyObject {

}
{% endcodeblock%}

{% codeblock lang:java%}
public class MainText {

	public static void main(String[] args) {
		
		Class class1 = MyObject.class;
		Annotation[] annotations = class1.getAnnotations();  //获取类的注解
		for (Annotation annotation : annotations) {
			if (annotation instanceof MyAnnotation) {
				MyAnnotation myAnnotation = (MyAnnotation) annotation;
				System.out.println("name:" + myAnnotation.name());
				System.out.println("value:" + myAnnotation.value());
			}
		}
	}
}
{% endcodeblock%}

<br/>
下面再通过一个例子演示一下方法注解的用法：

{% codeblock lang:java%}
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface MyAnnotation {
	public String name();
	public String value();
}
{% endcodeblock%}

{% codeblock lang:java%}
public class MyObject {
	
	@MyAnnotation(name="Java Reflection",  value = "Hello World")
	public void doSomething(){
		
	}
}
{% endcodeblock%}

{% codeblock lang:java%}
public class MainText {

public static void main(String[] args) throws NoSuchMethodException, SecurityException {
		Class class1 = MyObject.class;
		Method method = class1.getMethod("doSomething", null);
		
		Annotation[] annotations = method.getAnnotations();  //获取类的注解
		for (Annotation annotation : annotations) {
			if (annotation instanceof MyAnnotation) {
				MyAnnotation myAnnotation = (MyAnnotation) annotation;
				System.out.println("name:" + myAnnotation.name());
				System.out.println("value:" + myAnnotation.value());
			}
		}
	}
}
{% endcodeblock%}

需要注意以下2点：

1. @Retention(RetentionPolicy.RUNTIME)表示这个注解可以在运行期通过反射访问。如果没有在注解定义的时候使用这个指示那么这个注解的信息不会保留到运行期，这样反射就无法获取它的信息。

2. @Target(ElementType.TYPE) 表示这个注解只能用在类型上面（比如类跟接口），同样可以把TYPE改为FIELD或者METHOD，或者不用这个指定，那么，这个注解就在类、方法和变量上就都可以使用。


## 四、反射的适用场景及优缺点

### 反射的适用场景
>Java Reflection is quite powerful and can be very useful. For instance, Java Reflection can be used to map properties in JSON files to getter / setter methods in Java objects, like Jackson, GSON, Boon etc.does. Or, Reflection can be used to map the column names of a JDBC ResultSet to getter / setter methods in a Java object.


Java反射机制功能强大而且非常实用，举个例子，比如 jackson，Gson ，利用 java 反射 可以把JSON 中的属性 映射到 java 实体对象 的   getter / setter 方法上。比如Hibernate通过java 反射还可以把数据库中的列字段映射到java实体对象的 getter / setter 方法上。（把从数据库查询的结果记录映射到对应的实体类）

**反射主要用在以下地方：**

**1. 用于开发灵活可配置的基础框架**
反射机制是很多Java框架的基石，而一般应用层面很少用。典型的如 Hibernate、Spring中也用到很多反射机制。最经典的就是在xml文件或者properties里面写好了配置，然后在Java类里面解析xml或properties里面的内容，得到一个字符串，然后用反射机制，根据这个字符串获得某个类的Class实例，这样就可以动态配置一些东西，不用每一次都要在代码里面去new或者做其他的事情，以后要改的话直接改配置文件，代码维护起来就很方便了。

**2. 插件化支持**
因为一开始还不能确定插件的类型还有名称，所以无法初始化，需要在程序运行过程中，获取到插件的信息，然后再通过反射实例化对象并完成后续的动态调用。

**3.在编码阶段还不能确定类名，**类名需要从配置或者其他地方读取过来，这时候就没有办法硬编码new ClassName(),而必须用到反射才能创建这个对象。


### 反射的优缺点

**优点：**
可以在运行期获取类信息、实例化对象、动态调用方法，修改程序行为，利用这些特性可以设计出灵活和拓展性更好的程序。

**缺点：**

1. 使用反射的性能较低，jvm 需要做额外的检查校验，并且可能会导致JVM无法优化代码;
2. 使用反射相对来说不安全，写法也更复杂，更容易出错，运行期的BUG比编译期的BUG更不容易被发现；
3. 破坏了类的封装性，可以通过反射获取这个类的私，有方法和属性，

### 怎么考虑是否使用反射
**在业务场景中，如果非必须，则不直接使用java的反射。**

## 五、参考文献
[http://ifeve.com/java-reflection/](http://ifeve.com/java-reflection/)
[https://www.javatpoint.com/java-reflection](https://www.javatpoint.com/java-reflection)
[http://www.360doc.com/content/11/1231/14/1954236_176297236.shtml](http://www.360doc.com/content/11/1231/14/1954236_176297236.shtml)
[https://blog.csdn.net/tjpu_lin/article/details/23557443](https://blog.csdn.net/tjpu_lin/article/details/23557443)
[https://blog.csdn.net/zolalad/article/details/29370565](https://blog.csdn.net/zolalad/article/details/29370565)
