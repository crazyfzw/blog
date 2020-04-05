---
title: 为RecyclerView的不同item项实现不同的布局(添加分类Header)
date: 2016-04-22 21:57:38
categories:
- Android
tags:
- RecyclerView
- 多Item布局实现
- 为RecyclerView添加头部
- getSpanSize
- GridLayoutManager
---

最近在做一个应用的时候，需要为GridLayoutManager添加头部header，然后自然而然就想到了用不同的itemType去加载不同的布局。



## 1.实现多item布局，用不同的itemType去加载不同的布局。

主要思路就是先定义好标识itemType的常量，然后重写getItemViewType()方法，根据不同的位置（position）返回不同的Type，接着在onCreateViewHolder()中根据参数viewType去判断该item项应该 inflate 哪个布局文件，并返回相应的ViewHolder实例(这里ViewHolder是根据不同的item布局预先自定义好的不同的ViewHolder)

<!--more-->



比如我的代码：

{% codeblock lang:java%}

public class MyRecyclerCardviewAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder>{

    public static enum ITEM_TYPE {
        ITEM_TYPE_Theme,
        ITEM_TYPE_Video
    }
    //数据集
    public List<Integer> mdatas;
    private TextView themeTitle;

    public MyRecyclerCardviewAdapter(List<Integer> datas){
        super();
        this.mdatas = datas;
    }


    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        if (viewType == ITEM_TYPE.ITEM_TYPE_Theme.ordinal()){

            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.videothemelist,parent,false);

            return new ThemeVideoHolder(view);

        }else if(viewType == ITEM_TYPE.ITEM_TYPE_Video.ordinal()){

            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.videocardview,parent,false);
            return new VideoViewHolder(view);

        }
          return null;
    }


    @Override
    public void onBindViewHolder(final ViewHolder holder, final int position) {

        if (holder instanceof ThemeVideoHolder){

           themeTitle.setText("励志");

        }else if (holder instanceof VideoViewHolder){
            ((VideoViewHolder)holder).videologo.setImageResource(R.drawable.lianzai_02);
            ((VideoViewHolder)holder).videovname.setText("励志，俄小伙练习街头健身一年的体型变化，Dear Hard Work！");
            ((VideoViewHolder)holder).videoviewed.setText("2780次");
            ((VideoViewHolder)holder).videocomment.setText("209条");

          }

    }


    public int getItemViewType(int position){

        return position % 5 == 0 ? ITEM_TYPE.ITEM_TYPE_Theme.ordinal() : ITEM_TYPE.ITEM_TYPE_Video.ordinal();
    }




    @Override
    public int getItemCount() {
        return mdatas.size();
    }


    public class ThemeVideoHolder extends RecyclerView.ViewHolder{

        public ThemeVideoHolder(View itemView) {
            super(itemView);
            themeTitle = (TextView) itemView.findViewById(R.id.hometab1_theme_title);
        }
    }

    public class VideoViewHolder extends RecyclerView.ViewHolder {
        public ImageView videologo;
        public TextView videovname;
        public TextView videoviewed;
        public TextView videocomment;

        public VideoViewHolder(View itemView) {
            super(itemView);
            videologo = (ImageView) itemView.findViewById(R.id.videologo);
            videoviewed = (TextView) itemView.findViewById(R.id.videoviewed);
            videocomment = (TextView) itemView.findViewById(R.id.videocomment);
            videovname = (TextView) itemView.findViewById(R.id.videoname);
        }
    }
}

{% endcodeblock %}

这时，使用的是 LayoutManager 中发 LinearLayoutManager，效果图如下:

![](/images/2016042201.jpg)


但是，当我们把 LayoutManager 改成GridLayoutManager的时候你就出现了不是我们期待的效果，如下图：

![](/images/2016042202.jpg)



What the hell is going on? 什么鬼？怎么添加的header随着其他item项以cell的形式出现在网格上。仔细想一想，发现了下面代码:

```
GridLayoutManager layoutManager = new GridLayoutManager(this,2, GridLayoutManager.VERTICAL,false);
```

哦！原来我们在创建GridLayoutManager的时候需要设定每行显示多少个item项，我们这里设置的是2，而我们添加的header是以item项的形式添加进来的，所以也会以cell的形式出现。那么，有没有办法让header这个item占据两个cell，单独霸占一行呢？答案是肯定的，我们可以通过setSpanSizeLookup抽象类中的getSpanSize()方法的返回值来设定每个item项占据多少个单元格 。

{% codeblock lang:java %}

    gridManager.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                @Override
                public int getSpanSize(int position) {
                    return getItemViewType(position) == ITEM_TYPE.ITEM_TYPE_Theme.ordinal()
                            ? gridManager.getSpanCount() : 1;
                }
            });
     }

{% endcodeblock %}

那么，这段代码在自定义Adapter中应该添加在何处呢？放在onAttachedToRecyclerView()中再合适不过了。

{% codeblock lang:java %}

public void onAttachedToRecyclerView(RecyclerView recyclerView) {
        super.onAttachedToRecyclerView(recyclerView);
        RecyclerView.LayoutManager manager = recyclerView.getLayoutManager();
        if(manager instanceof GridLayoutManager) {
            final GridLayoutManager gridManager = ((GridLayoutManager) manager);
            gridManager.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
                @Override
                public int getSpanSize(int position) {
                    return getItemViewType(position) == ITEM_TYPE.ITEM_TYPE_Theme.ordinal()
                            ? gridManager.getSpanCount() : 1;
                }
            });
        }
    }
{% endcodeblock %}

这时就可以实现我想要的效果了，运行效果图如下：

![](/images/2016042203.jpg)


代码我已经抽离出来放到我的Github了：[https://github.com/crazyfzw/RecycleViewWithHeader](https://github.com/crazyfzw/RecycleViewWithHeader)



## 2.最后说一下为什么为什么用RecyclerView取代ListView。

用过ListView的都知道，在ListView中若要复用视图缓存，就要在getView()方法中手动判断convertView是否为空，若不为空则复用视图缓存，若为空则重新加载视图，而RecyclerView相当于对ListView的Adapter进行了再次封装，把ListView手动判断是否有缓存的代码封装到RecyclerView内部，使这部分逻辑不可见，我们只需要通过getItemCount()方法告诉RecyclerView有多少项数据，然后在onCreateViewHolder()中加载item布局实例化ViewHolder，然后在onBindViewHolder()中完成数据的绑定即可。







