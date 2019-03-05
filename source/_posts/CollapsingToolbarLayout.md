---
title: >-
  Material
  Design之利用CollapsingToolbarLayout轻松实现知乎日报新闻详情页顶部效果（带banner的toolbar伸缩折叠效果）
date: 2016-05-07 22:11:21
categories:
- Android
tags:
- CollapsingToolbarLay 
- 可伸缩折叠的Toolbar
- Collapsing
- Toolbar 
- layout_collapseMode
---

我们都知道CoordinatorLayout+AppBarLayout可以轻松实现滚动隐藏ToolBar的效果，今天我要写的是CollapsingToolbarLayout+CoordinatorLayout+AppBarLayout实现带Banner的Toolbar折叠效果————向上滚动时，Banner会随着滚动手势向上收缩至隐藏，Banner上的文字（实际上是CollapsingToolbarLayout上的文字）会逐渐缩小最后显示在Toolbar上，向下滚动时，Banner会逐渐显示并还原为原来大小，同时文字也会最近变大重回原来的位置。


知乎日报新闻详情页就用了这种效果，那赶紧看下面Gif效果图吧：

![](/images/2016050701.gif)



**实现方法：**

## 1.布局xml：

{% codeblock lang:xml %}

<?xml version="1.0" encoding="utf-8"?>
    <android.support.design.widget.CoordinatorLayout
        xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:tools="http://schemas.android.com/tools"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        tools:context=".MainActivity">

        <android.support.design.widget.AppBarLayout
            android:layout_width="match_parent"
            android:layout_height="256dp"
            android:fitsSystemWindows="true">

            <android.support.design.widget.CollapsingToolbarLayout
                android:id="@+id/collapsing_toolbar_layout"
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                android:fitsSystemWindows="true"
                app:contentScrim="@color/toolbarcolor"
                app:expandedTitleMarginStart="38dp"
                app:layout_scrollFlags="scroll|exitUntilCollapsed">

                <ImageView
                    android:layout_width="match_parent"
                    android:layout_height="match_parent"
                    android:fitsSystemWindows="true"
                    android:scaleType="centerCrop"
                    android:src="@drawable/skill"
                    app:layout_collapseMode="parallax"
                    app:layout_collapseParallaxMultiplier="0.7"/>


                <android.support.v7.widget.Toolbar
                    android:id="@+id/toolbar"
                    android:layout_width="match_parent"
                    android:layout_height="?attr/actionBarSize"
                    app:layout_collapseMode="pin"/>

            </android.support.design.widget.CollapsingToolbarLayout>

        </android.support.design.widget.AppBarLayout>

        <android.support.v4.widget.NestedScrollView
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:scrollbars="vertical"
            app:layout_behavior="@string/appbar_scrolling_view_behavior">

            <WebView
                android:id="@+id/webview"
                android:layout_width="match_parent"
                android:layout_height="match_parent"></WebView>
        </android.support.v4.widget.NestedScrollView>

    </android.support.design.widget.CoordinatorLayout>

{% endcodeblock %}

**CollapsingToolbarLayout中的属性：**

**A：contentScrim** - 设置当完全CollapsingToolbarLayout折叠(收缩)后的背景颜色。

**B：expandedTitleMarginStart** - 设置扩张时候(还没有收缩时)title与左边的距离。

**C：layout_scrollFlags:设置滚动表现：**

- 1) Scroll, 表示向下滚动列表时候,CollapsingToolbarLayout会滚出屏幕并且消失
- 2) exitUntilCollapsed, 表示这个layout会一直滚动离开屏幕范围,直到它收折成它的最小高度.
- 3) enterAlways: 一旦向上滚动这个view就可见。
- 4) enterAlwaysCollapsed: 这个flag定义的是已经消失之后何时再次显示。假设你定义了一个最小高度（minHeight）同时enterAlways也定义了， 那么view将在到达这个最小高度的时候开始显示，并且从这个时候开始慢慢展开，当滚动到顶部的时候展开完。  

                        




**ImageView及Toolbar中的属性：**

A: layout_collapseMode="parallax",这是控制滚出屏幕范围的效果的

- 1) pin,确保Toolbar在view折叠的时候仍然被固定在屏幕的顶部。

- 2) parallax,设置为这个模式时，在内容滚动时，CollapsingToolbarLayout中的View（比如ImageView)也可以同时滚动，实现视差滚动效果, 通常和layout_collapseParallaxMultiplier(设置视差因子，值为0~1)搭配使用。

                  

     

## 2.主要java代码：

{% codeblock lang:java %}

 Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        toolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBackPressed();
            }
        });

        //使用CollapsingToolbarLayout必须把title设置到CollapsingToolbarLayout上，设置到Toolbar上则不会显示
        CollapsingToolbarLayout mCollapsingToolbarLayout = (CollapsingToolbarLayout) findViewById(R.id.collapsing_toolbar_layout);
        mCollapsingToolbarLayout.setTitle("Bar Brother 徒手健身");
        //通过CollapsingToolbarLayout修改字体颜色
        mCollapsingToolbarLayout.setExpandedTitleColor(Color.WHITE);//设置还没收缩时状态下字体颜色
        mCollapsingToolbarLayout.setCollapsedTitleTextColor(Color.WHITE);//设置收缩后Toolbar上字体的颜色
        //toolbar navigationicon 改变返回按钮颜色
        final Drawable upArrow = getResources().getDrawable(R.drawable.abc_ic_ab_back_mtrl_am_alpha);
        upArrow.setColorFilter(getResources().getColor(R.color.white), PorterDuff.Mode.SRC_ATOP);
        getSupportActionBar().setHomeAsUpIndicator(upArrow);

        mWebView = (WebView) findViewById(R.id.webview);
        //设置支持js
        mWebView.getSettings().setJavaScriptEnabled(true);
        //!!设置跳转的页面始终在当前WebView打开
        mWebView.setWebViewClient(new WebViewClient());
        mWebView.loadUrl("https://");

    }

}

{% endcodeblock %}



源码可在我的Github下载：[https://github.com/crazyfzw/CollapsingToolbarLayoutDemo](https://github.com/crazyfzw/CollapsingToolbarLayoutDemo)



参考：

   [http://developer.android.com/intl/ko/reference/android/support/design/widget/CollapsingToolbarLayout.html](http://developer.android.com/intl/ko/reference/android/support/design/widget/CollapsingToolbarLayout.html)

   [http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2015/0717/3196.html](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2015/0717/3196.html)



推荐：[http://www.jcodecraeer.com/a/anzhuokaifa/developer/2015/0531/2958.html](http://www.jcodecraeer.com/a/anzhuokaifa/developer/2015/0531/2958.html)
