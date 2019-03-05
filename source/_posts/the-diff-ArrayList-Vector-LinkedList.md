---
title: 夯实基础 1：ArrayList、Vector、LinkedList 的区别
date: 2018-08-30 22:43:48
categories:
- JDK
tags:
- 集合
- 夯实基础
- ArrayList
- Vector
- LinkedList
---


## 一、集合框架层次结构
ArrayList、Vector、LinkedList 这三者都是集合框架中的 List，所以要弄清楚它们之间的区别与联系，最好先对集合框架类的层级有个整体直观的认识。

下面是集合框架的简要类图：

![](/images/2018083001.png)

从上图可以看到，Collection接口是所有集合的根，然后扩展开提供了三大类集合，分别是：

- List，有序集合，列表中的元素可重复，它提供了方便的访问、插入、删除等操作。

- Set，Set是不允许元素重复的，这是和List最明显的区别，也就是不存在两个equals返回true的情况。广泛用于需要保证元素唯一的场合。

- Queue/Deque ，则是Java提供的标准队列结构的实现，除了集合的基本功能，它还支持类似 先入先出（FIFO ，First-in-First-Out)储后入先出（LIFO，Last-In-First-Out)等特定行 为。这里不包括 BlockingQueue ，因为通常是并发编程杨合，所以被放置在并发包里。

每种集合的通用逻辑，都被抽象到相应的抽象类之中，比如AbstractList就集中了各种List操作的 通用部分。这些集合不是完全孤立的，比如，LinkedList本身，既是List，也是 Deque。

## 二、ArrayList、Vector、LinkedList 

下面可以看一个简化版的类图：

![](/images/2018083002.png)

从上图可以看到 ArrayList、Vector、LinkedList 三者都实现了List 接口。因此，它们在功能及用法上都非常的相似，比如都提供按照索引位置进行取值、添加、删除操作，都提供了迭代器用于遍历元素等功能。它们之间的主要区别，来源于底层实现上的不同，所以在行为、性能、线程安全性上有所差别。


- ArrayList 是一个可改变大小的动态数组，随着元素的添加，会动态的增加容量，因为ArrayList本质上就是一个数组，所以内部的元素可以直接通过get与set方法进行访问。需要注意的是，ArrayList 本身不是线程安全的，所以与Vector 相比，不存在同步的开销，性能上好很多。


- Vector 和ArrayList类似，不同的是在方法的前面加了synchronized，因此Vector 是线程安全的。
如果你的程序本身是线程安全的（即不存在多个线程之间共享同一个集合/对象），那么不建议选择Vector ，毕竟同步是有额外开销的。

- LinkedList 是一个双链表，在添加和删除元素时具有比ArrayList更好的性能，但在get与set方面弱于ArrayList。 LinkedList 还实现了 Queue 接口，该接口比List提供了更多的方法,包括 offer()、peek()、poll()等。LinkedList本身，既是List，也是 Deque。

## 三、性能比较
下面写个例子对比下 ArrayList、LinkedList 在访问、添加、删除元素方面的差异。

{% codeblock lang:java%}
	public static void main(String[] args) {

		ArrayList<Integer> arrayList = new ArrayList<Integer>();
		LinkedList<Integer> linkedList = new LinkedList<Integer>();
		 
		// ArrayList add
		long startTime = System.nanoTime();
		 
		for (int i = 0; i < 100000; i++) {
			arrayList.add(i);
		}
		long endTime = System.nanoTime();
		long duration = endTime - startTime;
		System.out.println("ArrayList  add: " + duration);
		 
		// LinkedList add
		startTime = System.nanoTime();
		 
		for (int i = 0; i < 100000; i++) {
			linkedList.add(i);
		}
		endTime = System.nanoTime();
		duration = endTime - startTime;
		System.out.println("LinkedList add: " + duration);
		 

		// ArrayList get
		startTime = System.nanoTime();
		 
		for (int i = 0; i < 10000; i++) {
			arrayList.get(i);
		}
		endTime = System.nanoTime();
		duration = endTime - startTime;
		System.out.println("ArrayList  get: " + duration);
		 
		// LinkedList get
		startTime = System.nanoTime();
		 
		for (int i = 0; i < 10000; i++) {
			linkedList.get(i);
		}
		endTime = System.nanoTime();
		duration = endTime - startTime;
		System.out.println("LinkedList get: " + duration);
		 	
 
		// ArrayList remove
		startTime = System.nanoTime();
		 
		for (int i = 9999; i >=0; i--) {
			arrayList.remove(i);
		}
		endTime = System.nanoTime();
		duration = endTime - startTime;
		System.out.println("ArrayList  remove: " + duration);
		 
		// LinkedList remove
		startTime = System.nanoTime();
		 
		for (int i = 9999; i >=0; i--) {
			linkedList.remove(i);
		}
		endTime = System.nanoTime();
		duration = endTime - startTime;
		System.out.println("LinkedList remove: " + duration);
	 }
{% endcodeblock%}
在JDK1.7 中的运行效果如下所示：

![](/images/2018083003.png)

**小结：**
可以看到，ArrayList 在访问元素比 LinkedList 好，单在添加、删除元素方面 LinkedList 性能更好。 



## 四、不同容器适合的场景(如何考虑选择)

- Vector和ArrayList作为动态数组，其内部元素以数组形式顺序存储，所以非常适合随机访问的场合。除了尾部插入和删除元素，往往性能会先对较差，比如我们在中间插入一个元素，需要移动后续的所有元素。
- LinkedList 进行节点的插入、删除却要高效的多，但随机访问性能却要比动态数组慢。

所以在开发的过程中，应考虑对应的功能是偏向于插入、删除、还是随机访问比较多，来进行针对性的选择。**如果是插入、删除比较频繁，则选用 LinkedList ；如果随机性访问多，则选择动态数组（Vector 和 ArrayList），然后再结合是否需要线程安全来进一步选择，如果需要线程安全则使用Vector，如果不需要线程安全，则选择 ArrayList 。**



##  五、Vector和ArrayList 的扩容机制

Vector和ArrayList在随着元素的添加，当数组满时，会请求更大的空间，创建新数组，并拷贝原有数组数据。区别的是，Vector 每次扩容时增加1倍，而ArrayList则是增加 50%。如下面的代码所示：

**Vector 的 grow 源码**

{% codeblock lang:java%}
    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
        /**
         *这里可以看到，如果在构造 Vector 的时候指定了 步长 capacityIncrement ，
         *则在原容量基础上增加指定步长，否则增加1倍原容量
         */
        int newCapacity = oldCapacity + ((capacityIncrement > 0) ?
                                         capacityIncrement : oldCapacity);
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
{% endcodeblock%}


**ArrayList 的 grow 源码**

{% codeblock lang:java%}
    /**
     * Increases the capacity to ensure that it can hold at least the
     * number of elements specified by the minimum capacity argument.
     *
     * @param minCapacity the desired minimum capacity
     */
    private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
       //这里可以看到在原容量的基础上再增加 原容量的一半。
        int newCapacity = oldCapacity + (oldCapacity >> 1);  
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
{% endcodeblock%}


**最佳实践：**
值得注意的是，动态扩容会创建新数组，并拷贝原有数组数据到新的数组，所以每次扩容都会带来一定的开销。而默认情况下 ArrayList 和 Vector 的初始容量非常小，在JDK1.7 中默认是10，所以JDK提供了构造函数，支持在创建动态数组的时候指定数组的初始容量。所以**如果可以预估数据量的话，分配一个较大的初始值可以减少动态扩容带来的开销。**


**ArrayList 的 相应的构造方法**

{% codeblock lang:java%}
    /**
     * Constructs an empty list with the specified initial capacity.
     *
     * @param  initialCapacity  the initial capacity of the list
     * @throws IllegalArgumentException if the specified initial capacity
     *         is negative
     */
    public ArrayList(int initialCapacity) {
        super();
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        this.elementData = new Object[initialCapacity];
    }
{% endcodeblock%}


**Vector 的 相应的构造方法**

{% codeblock lang:java%}
    /**
     * Constructs an empty vector with the specified initial capacity and
     * with its capacity increment equal to zero.
     *
     * @param   initialCapacity   the initial capacity of the vector
     * @throws IllegalArgumentException if the specified initial capacity
     *         is negative
     */
    public Vector(int initialCapacity) {
        this(initialCapacity, 0);
    }

    /**
     * Constructs an empty vector with the specified initial capacity and
     * capacity increment.
     *
     * @param   initialCapacity     the initial capacity of the vector
     * @param   capacityIncrement   the amount by which the capacity is
     *                              increased when the vector overflows
     * @throws IllegalArgumentException if the specified initial capacity
     *         is negative
     */
    public Vector(int initialCapacity, int capacityIncrement) {
        super();
        if (initialCapacity < 0)
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        this.elementData = new Object[initialCapacity];
        this.capacityIncrement = capacityIncrement;
    }
{% endcodeblock%}

可以看到， 创建 ArrayList 和 Vector 时，都可以指定数组的初始容量，并且 Vector  还可以指定数组每次扩容的增量。

下面写个例子测试对比一下使用默认初始容量与指定初始初始容量的效果：

{% codeblock lang:java%}
	public static void main(String[] args){
		
		ArrayList<Integer> arrayList1 = new ArrayList<Integer>();
		ArrayList<Integer> arrayList2 = new ArrayList<Integer>(10000000);
		
		// arrayList1 add
		long startTime = System.nanoTime();
		
		for (int i = 0; i < 10000000; i++) {
			arrayList1.add(i);
		}
		long endTime = System.nanoTime();
		long duration = endTime - startTime;
		System.out.println("arrayList1  add: " + duration);
		
		// arrayList2 add
		long startTime2 = System.nanoTime();
		
		for (int i = 0; i < 10000000; i++) {
			arrayList2.add(i);
		}
		long endTime2 = System.nanoTime();
		long duration2 = endTime2 - startTime2;
		System.out.println("arrayList2  add: " + duration2);
	}
{% endcodeblock%}

运行效果如下所示： 

![](/images/2018083004.png)

可以看到，如果可以预估数据量的话，分配一个较大的初始值可以减少动态扩容带来的开销，效果还是比较明显的。


## 六、参考文献

[关于Java集合的小抄](http://calvin1978.blogcn.com/articles/collection.html)

