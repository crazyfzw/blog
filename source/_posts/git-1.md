---
title: Git 提交代码到远程仓库
date: 2017-12-20 21:05:09
categories:
- Git
tags:
- Git
---

## Git 命令

### 一、Git如何把本地代码推送到远程仓库


#### 1. 拉取指定分支代码
```
git clone -b dev https://github.com/crazyfzw/RecycleViewWithHeader.git
```


#### 2. 初始化版本库 
```
git init 
```

#### 3. 添加文件到版本库（只是添加到缓存区） .代表添加文件夹下所有文件
```
git add . 
```

#### 4. 把添加的文件提交到版本库，并填写提交备注
```
git commit -m  "first commit"
```
*到目前为止，已经完成了本地代码库的初始化，但是还没有提交到远程服务器，所以关键的来了，要提交到就远程代码服务器，进行以下两步：*

<!--more-->

#### 5. 把本地库与远程库关联
```
git remote add origin 你的远程库地址
```
#### 6. 推送代码到远程仓库（ 第一次推送时）
```
git push -u origin master
```
#### 7. 推送代码到远程仓库（第一次推送后，直接使用该命令即可推送修改）
```
git push origin master
```

