---
title: 跨域问题解决
date: 2018-06-13 22:12:11
categories:
- WEB
tags:
- 跨域
- 浏览器跨域
- cross-origin
- postMessage
- CORS 
---

## 一、跨域的由来

为了保证用户信息的安全，防止恶意的网站窃取数据，目前，所有浏览器都实行了同源策略，要求域名、协议、端口必须都相同才属于同源，只有同源才可以访问其他页面的对象，否则将受到以下限制：

（1） Cookie、LocalStorage 和 IndexDB 无法读取。
（2） DOM 无法获得。
（3） AJAX 请求不能发送。

## 二、微服务之后跨域问题更普遍存在
在现在前后端分离，分布式服务、微服务化之后，我们将复杂的业务拆分成细小的服务组件，部署到不同的主机下，往往存在不同的域名。因此，跨域问题，就更普遍存在了。


## 三、跨域问题解决方法


### 1. 使用代理页面实现跨域

该方法可以解决所有跨域获取 DOM，跨域调用 js方法等，如刷新父级页面、关闭窗口等。典型的例子就如iframe窗口和window.open方法打开的窗口，它们与父窗口无法通信的问题。常见报错：

![](/images/2018061301.png)


**实现原理：**在目标页面 A 的同级目录下新建一个代理页面 spyA，然后在调用的页面中通过 iframe 加载代理页面 spyA ，使它在加载的过程中被执行，而且它与目标页面是同源的，所以不存在跨域问题，可以利用这个代理页面避开跨域访问问题，在代理页面可以获取DOM及执行函数等操作。（我喜欢把这个代理页面称为间谍页面，你可以通过这个间谍页面做一些无法直接做到的事情）

**A.html**
{% codeblock lang:html %}
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">  
<html>  
 <head>  
  <meta http-equiv="content-type" content="text/html; charset=utf-8">  
  <title> main window </title>  
  <script type="text/javascript">    
  function doSomething(){  
    /**
     *to do something you want in here
     */
    $("#btn").val("really?");  
  }  
  </script>  
 </head>  
 <body>  
  <p>A.html main</p>  
  <p><input id="btn" type="button" value="I am a Butten"></p>  
  <iframe src="http://127.0.0.1/B.html" name="myframe" width="500" height="100"></iframe>  
 </body>  
</html>
{% endcodeblock %}


**B.html**
{% codeblock lang:html %}
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">  
<html>  
 <head>  
  <meta http-equiv="content-type" content="text/html; charset=utf-8">  
  <title> iframe window,Open in A.html</title>  
  
  <script type="text/javascript">  
  function callSpyA(){  
    if(typeof(exec_obj)=='undefined'){  
        exec_obj = document.createElement('iframe');  
        exec_obj.name = 'tmp_frame';  
        exec_obj.src = 'http://localhost:8080/spyA.html';  
        exec_obj.style.display = 'none';  
        document.body.appendChild(exec_obj);  
    }else{  
        exec_obj.src = 'http://localhost:8080/spyA.html?' + Math.random();  
    }  
  }  
  </script>  
 </head>  
 <body>  
  <p>B.html iframe</p>  
  <p><input type="button" value="exec main function" onclick="callSpyA()"></p>  
 </body>  
</html>  
{% endcodeblock %}


**spyA.html**
{% codeblock lang:html %}
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title> spy page</title>
<!-- 这是一个代理页面，用于代替完成一些受跨域限制无法直接做到的事情  -->
</head>
<body>
    <script type="text/javascript">
       <!-- do something -->
        parent.parent.doSomething(); 
    </script> 
</body>
</html>
{% endcodeblock %}

<br/>
### 2.使用 window.postMessage 方法实现跨域
 
HTML5 为 window 对象新增了一个 window.postMessage 方法，允许跨窗口通信，不论这两个窗口是否同源。

**实现原理：**是通过 message 事件监听对方消息， 当需要跨域调用时，直接通 window.postMessage 发送通知， 然后目标页面监听到消息后在监听方法里面做一些操作。（通过 window.postMessage 还读写其他窗口的 LocalStorage）


**A.html**
{% codeblock lang:html%}
<html>    
    <head>    
        <title></title>    
    </head>    
    <body>    
        <script>    
            window.addEventListener('message', function(event){    
                // event.origin属性可以过滤不是发给本窗口的消息 
                if (event.origin == 'http://a.com')   
               /**
                  *to do something you want in here
                */
                    alert(event.data); //输出：Hello   
                }
            });        
        </script>    
    </body>    
</html> 
{% endcodeblock %}


**B.html**
{% codeblock lang:html%}
<!doctype html>  
<html>  
    <head>  
    </head>  
    <body>  
        <iframe id="iframe" src="http://a.com/A.html"></iframe>  
        <script>  
            window.onload = function() {   
                document.getElementById('iframe').contentWindow.postMessage('Hello',      "http://a.com");    
            };    
        </script>  
    </body>  
</html> 
{% endcodeblock %}

<br/>
### 3. 通过 搭建中间转发层 或者 Nginx 反向代理 实现跨域

同源政策规定，AJAX 请求只能发给同源的网址，否则就报错。

但是由于同源策略只是对浏览器的一种安全策略，所以我们可以绕过浏览器实现跨域，通过搭建中间层在服务端转发前端请求到真正的目的地址，或者通过 Niginx 反响代理，利用Nginx解析URL地址的时候进行判断，将请求转发的具体的服务器上。

![](/images/2018061302.png)

<br/>
### 4. 通过 CORS 实现跨域
CORS 全称为 Cross Origin Resource Sharing（跨域资源共享），CORS 支持所有类型的 HTTP 请求，CORS 需要浏览器和服务器同时支持，但是整个 CORS 通信过程，都是浏览器自动完成，不需要用户参与。对于开发者来说，CORS 通信与同源的 AJAX 通信没有差别，代码完全一样。浏览器一旦发现AJAX请求跨源，就会自动添加一些附加的头信息，但用户不会有感觉。因此，实现 CORS 通信的关键是服务端。服务端只需添加相关响应头信息，即可实现客户端发出 AJAX 跨域请求。

值得高心的是， SpringMVC 4.2 中已经增加了增加 CORS 的支持，通过 @CrossOrigin 注解可以轻松实现跨域，可以加在整个 controller 上，也可以单独加在某个方法前面。如下：

{% codeblock lang:java %}
	@CrossOrigin("http://crazyfzw.com")
	@RequestMapping("toList")
	public String toList(HttpServletRequest request){
		String rfUrl = PropertiesUtil.getSystem("edrfUrl");
		request.setAttribute("rfUrl",rfUrl);
		return ("/web/workforminfo/workforminfo_list");
	}
{% endcodeblock%}


<br/>
## 四、参考文献：   

1.[浏览器同源政策及其规避方法](http://www.ruanyifeng.com/blog/2016/04/same-origin-policy.html)

2.[跨域资源共享 CORS 详解](http://www.ruanyifeng.com/blog/2016/04/cors.html)

3.[Spring MVC 4.2 增加 CORS 支持](https://blog.csdn.net/isea533/article/details/50449907)









