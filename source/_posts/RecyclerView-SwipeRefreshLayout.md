---
title: RecyclerView+SwipeRefreshLayout实现下拉刷新列表
date: 2016-04-12 21:25:22
categories:
- Android
tags:
- RecyclerView
- SwipeRefreshLayout 
- 下拉刷新
- RecyclerView+SwipeRefreshLayout
---

## 一：RecyclerView的用法：



 **RecyclerView是google在2014年I/O大会上提出新的用于取代ListView的组件，是 android-support-v7-21 版本中新增的一个 Widgets，它的灵活性与可替代性比listview更好。**
<!--more-->



 使用 RecyclerView首先应该认识两个要点：

**1. Adapter：**使用RecyclerView之前，需要继承RecyclerView.Adapter定义一个自己的适配器，作用是将数据与每一个item的界面进行绑定，注意，与ListView不同，这里不在是使用传统的ArrayAdapter、SimpleAdapter、BaseAdapter。


**2.LayoutManager：** 控制每个Item项的布局显示。

目前SDK中提供了三种自带的LayoutManager:
LinearLayoutManager（可以实现垂直滚动的线性列表、水平线滚动性列表）
GridLayoutManager    （可以实现垂直Grid列表、水平线Grid列表列表）
StaggeredGridLayoutManager (可以实现瀑布流列表)

RecyclerView的详细用法可以参考：

[http://developer.android.com/reference/android/support/v7/widget/RecyclerView.html](http://developer.android.com/reference/android/support/v7/widget/RecyclerView.html)

[http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2014/1118/2004.html](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2014/1118/2004.html)

[http://blog.csdn.net/lmj623565791/article/details/45059587](http://blog.csdn.net/lmj623565791/article/details/45059587)


## 二：SwipeRefreshLayout的用法：
SwipeRefreshLayout也是一个下拉刷新控件，已经被加在在support v4兼容包下，两个要点：


**1.** 只要在需要刷新的控件最外层加上SwipeRefreshLayout，然后他的child首先是可滚动的view，如RecyclerView、ListView等


**2.** 实现SwipeRefreshLayout.OnRefreshListener接口，并找到SwipeRefreshLayout组件注册监听事件。注意：下拉刷新的数据更新逻辑代码应该写在onRefresh()方法中。

SwipeRefreshLayout的详细用法可以参考：

http://developer.android.com/reference/android/support/v4/widget/SwipeRefreshLayout.html

http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2014/1028/1861.html





## 三、下面我通过RecyclerView+SwipeRefreshLayout实现下拉刷新的垂直列表来演示RecyclerView及SwipeRefreshLayout的用法：
运行效果图gif：


![](/images/2016041201.gif)


### 1. 在build.gradle 中添加依赖

```
compile 'com.android.support:recyclerview-v7:22.2.0'
```

这里只要是recyclerview-v7:21.0.+就可以了。


### 2. 创建布局文件

{% codeblock lang:xml%}

<?xml version="1.0" encoding="utf-8"?>
<android.support.v4.widget.SwipeRefreshLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/id_swiperefreshlayout"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    app:layout_behavior="@string/appbar_scrolling_view_behavior">

    <android.support.v7.widget.RecyclerView
        android:id="@+id/id_recyclerview"
        android:layout_width="match_parent"
        android:layout_height="wrap_content" />

</android.support.v4.widget.SwipeRefreshLayout>

{% endcodeblock %}

### 3.继承RecyclerView.Adapter创建自己的Adapter.


{% codeblock lang:java %}

public class MyRecyclerViewAdapter extends RecyclerView.Adapter<MyRecyclerViewAdapter.ViewHolder>{

    //数据集
    public String[] datass;

    //1.在构造函数中取得数据集
    public MyRecyclerViewAdapter(String[] datas){
        super();
        this.datass = datas;
    }

   //定义一个接口
    public static interface  OnItemClickListener{
        void onItemClick(View view, int positon);
    }


    private OnItemClickListener mOnItemClickListener;
    //添加接口和设置Adapter的方法
    public void setOnItemClickListener(OnItemClickListener listener) {
        this.mOnItemClickListener = listener;
    }
    ///3.创建新View，被LayoutManager所调用
    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        // 创建一个View，简单起见直接使用系统提供的布局，就是一个TextView
        View view = LayoutInflater.from(parent.getContext()).inflate(android.R.layout.simple_list_item_1,parent,false);
        //创建一个ViewHolder
        ViewHolder viewHolder= new ViewHolder(view);
        return viewHolder;
    }

    //4.将数据与界面进行绑定的操作
    @Override
    public void onBindViewHolder(final ViewHolder holder, final int position) {

        holder.textView.setText(datass[position]);
        if (mOnItemClickListener!=null){
            holder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mOnItemClickListener.onItemClick(holder.itemView, position);
                }
            });
        }
    }

    //5.返回数据的长度
    @Override
    public int getItemCount() {
        return datass.length;
    }

    //2.自定义的ViewHolder，取得每个Item的的所有界面元素
    public class ViewHolder extends RecyclerView.ViewHolder {
        public TextView textView;

        public ViewHolder(View itemView) {
            super(itemView);
            textView = (TextView) itemView.findViewById(android.R.id.text1);
        }
    }
}
{% endcodeblock %}

### 4.在Activity中找到RecyclerView并绑定自定义的Adapter显示列表，实现SwipeRefreshLayout.OnRefreshListener接口，并找到SwipeRefreshLayout组件注册监听事件。注意：下拉刷新的数据更新逻辑代码应该写在onRefresh()方法中。


{% codeblock lang:java %}

public class MainActivity extends AppCompatActivity implements SwipeRefreshLayout.OnRefreshListener{

    private RecyclerView mRecyclerView;
    private SwipeRefreshLayout swipeRefreshLayout;
    private MyRecyclerViewAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
        fab.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Snackbar.make(view, "Replace with your own action", Snackbar.LENGTH_LONG)
                        .setAction("Action", null).show();
            }
        });

        //显示垂直的RecyclerView
        initVerticalRecyclerView();

        //设置SwipeRefreshLayout实现下拉刷新效果
        swipeRefreshLayout = (SwipeRefreshLayout) findViewById(R.id.id_swiperefreshlayout);
        //设置进度条颜色，最多设置4种循环显示
        swipeRefreshLayout.setColorSchemeResources(android.R.color.white,
                android.R.color.holo_green_light,
                android.R.color.holo_orange_light, android.R.color.holo_red_light);
        swipeRefreshLayout.setOnRefreshListener(this);
    }

    private void initVerticalRecyclerView() {

        mRecyclerView = (RecyclerView) findViewById(R.id.id_recyclerview);
        //创建一个垂直的线性布局管理器
        LinearLayoutManager layoutManager = new LinearLayoutManager(this,LinearLayoutManager.VERTICAL,false);

        //找到RecyclerView，并设置布局管理器
        mRecyclerView.setLayoutManager(layoutManager);

        //如果确定每个item项的高度是固定的，设置这个选项可以提高性能
        mRecyclerView.setHasFixedSize(true);

        //创建或取得数据集，数据推荐还是时有List集合
        final String[] datas = new String[20];
        for(int i=0; i<datas.length; i++){
            datas[i]="item"+i;
        }

        //创建adapter并且制定数据集
        adapter = new MyRecyclerViewAdapter(datas);

        //为RecyclerView绑定Adapter
        mRecyclerView.setAdapter(adapter);

        //在Adapter中添加好事件后，变可以在这里注册事件实现监听了
        adapter.setOnItemClickListener(new MyRecyclerViewAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(View view, int positon) {
                Toast.makeText(getBaseContext(), "item"+positon, Toast.LENGTH_LONG).show();

            }
        });
    }


    @Override
    public void onRefresh() {
        // 刷新时模拟数据的变化
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                swipeRefreshLayout.setRefreshing(false);
                for (int i=0; i<11; i++) {
                    int temp = (int) (Math.random() * 10);
                    adapter.datass[i] = "new" + temp;
                }
                adapter.notifyDataSetChanged();
            }
            }, 1000);

    }
}

{% endcodeblock %}


[完整源码可以到我的github下载：https://github.com/crazyfzw/RecyclerViewDemo](https://github.com/crazyfzw/RecyclerViewDemo)

