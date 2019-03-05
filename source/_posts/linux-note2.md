---
title: Linux学习笔记 (二)：目录文件操作常用命令
date: 2017-10-17 22:05:09
categories:
- Linux
tags:
- Linux
- cat
- man
---

Linux 中的所有管理任务都可以在控制台中完成。许多情况下，使用控制台比使用图形化的程序更快捷，而且还可能实现额外的功能。不仅如此，所有的控制台任务都可以写到脚本中，这样就可以自动执行。


## 进入控制台
在典型的 Linux 系统中，通过组合键 Ctrl + Alt + (F1 - F6) 您可以切换到另外的控制台；如果您是在图形模式下，那么您可以打开一个 终端 (terminal)以进入控制台窗口。通常在桌面的任务条上会有终端的按钮。

## 命令
所有的命令和选项都区分大小写。 -R 与 -r不同，会去执行不同的操作。控制台命令几乎全都是小写的。下面是一些最常用的命令：

### cd
使用我们所熟悉的 cd 命令可以在目录间切换。一定注意的是在 Linux 中用的是正斜杠 (/)，而不是您所熟悉的反斜杠 (\)。反斜杠也用到了，但只是用来说明命令需要换行继续，这样可以提高比较长的命令的可读性。

### ls
ls 命令用于列出一个目录下的所有文件。可以使用许多不同的开关更改列表的表示形式：

列出文件
![](/images/2018041701.png)

### pwd 
显示当前工作目录

### mkdir 
创建目录

### cp
使用 cp 命令来复制文件。这个命令与 DOS 下的 copy 命令基本一样。基本的开关如下：
复制文件
![](/images/2018041702.png)

### mv
使用 mv 命令来移动和重命名文件。这个命令的工作方式基本上与 DOS 中的 move 命令一样，不过它可以移动整个目录结构及所有文件。

### cat
使用 cat 命令来查看文件的内容。它相当于 DOS 中的 type 命令。它将把文件的内容转储到另一个文件、屏幕或者其他命令。 cat 是concatenate 的简写，还可以将一系列的文件合并为一个大文件。

### more
使用命令 more 可以以分页的方式查看文件。它基本上与 DOS 中的 more命令相同。

### less
less 命令也是用来查看文件，但是它支持上下滚屏以及在文档中进行文本搜索。

### vi
有一些人可能会说 vi 表示“virtually impossible”。它是 Unix 中的一个历史悠久的文本编辑器。 vi 并不真正直观，但是现在几乎所有的类 Unix 环境中都有 vi 。对于 Linux 中安装的版本有一个内置的教程，一旦您熟悉了 vi ，只需几次击键就可以完成不可思议的任务。说实话，没有任何编辑器能够取代 vi 来编辑密码和配置文件。

### man
使用 man 命令来查看命令的文档。man 是 manual 的缩写。几乎每一个命令都有相应的文档。要深入了解 man ，请输入以下命令：
man man

### info
info 命令与 man 命令类似，不过它提供了超链接文本，可以更方便地浏览文档。


