---
title: Tablayout+Viewpager+Fragment实现滑动Tab
date: 2016-04-09 12:05:15
categories: 
- Android
tags:
- android.support.v4.a 
- Tablayout 
- ViewPager
- Fragment
- 滑动tab
---

实现活动Tab的方式有很多种，今天我们要用的是使用Google 提供的Design support library 库中的Tablayout去实现，Tablayout是Google I/O 2015 退出8个新的组件之一，可以轻松的结合Viewpager和Fragment实现滑动tab菜单。

<!--more-->


运行效果截图：

![](/images/20160101.jpg)

![](/images/20160102.jpg)


## 使用步骤：

### 1.添加支持类

在build.gradle(Module:app)中通过以下代码添加支持类：

{% codeblock lang:xml%}
dependencies {
  compile 'com.android.support:appcompat-v7:22.2.0'
  compile 'com.android.support:design:22.2.0'
}
{% endcodeblock %}

### 2.创建Sliding Tabs Layout（主布局文件）

用android.support.design.widget.TabLayout创建tab布局，用android.support.v4.view.ViewPager显示关联tab的Fragment.
eg:main_content.xml
{% codeblock lang:xml%}
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <android.support.design.widget.TabLayout
        android:id="@+id/tab_layout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"/>
    <!--app:tabMode="scrollable"-->

    <android.support.v4.view.ViewPager
        android:id="@+id/pager"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>

</LinearLayout>
{% endcodeblock %}

### 3.创建Fragment：

为每个tab项创建一个对应的fragment用于展示内容。eg:与tab1对应的fragment_tab1.xml代码如下：

#### 3.1Fragment布局

{% codeblock lang:xml%}
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools" android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context="com.crazyfzw.tablayoutviewpager.TabFragment1">

    <!-- TODO: Update blank fragment layout -->
    <TextView
        android:id="@+id/textView1"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_centerInParent="true"
        android:gravity="center"
        android:layout_gravity="center_vertical"
        android:text="tab1页内容" />
</FrameLayout>
{% endcodeblock %}

在本例中，我们再创建两个这样布局的fragment_tab2.xml、fragment_tab3.xml.

#### 3.2创建fragment布局文件对应的逻辑类Fragment.java用于展示tab的内容

eg:这里TabFragment1.java

{% codeblock lang:java%}
public class TabFragment1 extends Fragment {

    private static final String ARG_PARAM1 = "param1";
    private String mParam1;
    private TextView textView;

    public static TabFragment1 newInstance(String param1) {
        TabFragment1 fragment = new TabFragment1();
        Bundle args = new Bundle();
        args.putString(ARG_PARAM1, param1);
        fragment.setArguments(args);
        return fragment;
    }

    public TabFragment1() {}
    
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mParam1 = getArguments().getString(ARG_PARAM1);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View myview = inflater.inflate(R.layout.fragment_tab1, container, false);
        textView = (TextView) myview.findViewById(R.id.textView1);
        textView.setText(mParam1);
        return myview;
    }
}
{% endcodeblock %}


同样，为了演示本例创建相似的TabFragment2java、TabFragment3.java

### 4.创建ViewPager的适配器:

实现FragmentPagerAdapter接口并重载其中的方法，用于控制tab与内容页content的关系。其中getPageTitle(int position)方法为每个tab取得标题title,而getItem(int position)方法决定每个tab显示哪个fragment.

eg:MyViewPagerAdapter.java代码如下：

{% codeblock lang:java%}
public class MyViewPagerAdapter extends FragmentStatePagerAdapter {


    private final List<Fragment> myFragments = new ArrayList<>();
    private final List<String> myFragmentTitles = new ArrayList<>();
    private Context context;

    public MyViewPagerAdapter(FragmentManager fm, Context context) {
        super(fm);
        this.context = context;
    }

    public void addFragment(Fragment fragment, String title) {
        myFragments.add(fragment);
        myFragmentTitles.add(title);
    }

    @Override
    public Fragment getItem(int position) {
        return myFragments.get(position);
    }

    @Override
    public int getCount() {
        return myFragments.size();
    }

    @Override
    public CharSequence getPageTitle(int position) {
        return myFragmentTitles.get(position);
    }
}
{% endcodeblock %}

### 5.最后一步，在Activity中把ViewPager 与PagerAdapter绑定，然后让用setupWithViewPager(viewPager)方法把pager与tab关联在一起。

主要两步:
A:找到ViewPager控件并setAdapter(adapter);
B：找到tablayout控件并用用setupWithViewPager(viewPager)方法把pager与tab关联在一起。

eg:本例Mainactivity.java代码如下：

{% codeblock lang:java%}
public class MainActivity extends AppCompatActivity {

    private TabLayout tabLayout;
    private ViewPager viewPager;
    private MyViewPagerAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        tabLayout = (TabLayout) findViewById(R.id.tab_layout);
        viewPager = (ViewPager) findViewById(R.id.pager);

        if (viewPager != null) {
            setupViewPager(viewPager);
        }
    }

    private void setupViewPager(ViewPager viewPager) {
        adapter = new MyViewPagerAdapter(getSupportFragmentManager(), this);
        adapter.addFragment(new TabFragment1().newInstance("Page1"), "Tab 1");
        adapter.addFragment(new TabFragment2().newInstance("Page2"), "Tab 2");
        adapter.addFragment(new TabFragment3().newInstance("Page3"), "Tab 3");
        viewPager.setAdapter(adapter);
        tabLayout.setupWithViewPager(viewPager);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}
{% endcodeblock %}

运行就可以了。

**注意：**
运行的时候在 adapter.addFragment(new TabFragment1().newInstance("Page1"),"Tab1");
中很可能会出现错误，无法将子类abFragment1的对象转化为Fragment对象。提示cannot convert from Tab1Fragment(android.support.v4.app.Fragment) to Fragment(android.app.Fragment).这是因为导入包不一致，一般的问题在于：这里或者PaperAdapter中导入的是android.support.v4.app.Fragment，而Fragment的子类Tab1Fragment中导入的是android.app.Fragment，包不同所以无法转换，这里统一导入android.support.v4.app.Fragment就可以解决了。

本例源码可以到我的github去下载 [https://github.com/crazyfzw/TablayoutViewpager](https://github.com/crazyfzw/TablayoutViewpager)

**参考文献：**

https://developer.android.com/intl/zh-cn/reference/android/support/design/widget/TabLayout.html
https://github.com/codepath/android_guides/wiki/ViewPager-with-FragmentPagerAdapter
http://blog.csdn.net/jason0539/article/details/9712273

若想实现带图标的滑动tab或者更详细的Tablayout推荐参考
https://github.com/codepath/android_guides/wiki/Google-Play-Style-Tabs-using-TabLayout#design-support-library

