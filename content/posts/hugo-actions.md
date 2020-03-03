---
keywords: 
- 一万小时极客
- Hugo
- GitHub Pages
- Github Actions
title: "折腾Hugo | GitHub Pages | Github Actions自动构建发布免费个人网站"
subtitle: "Hugo | GitHub Pages | Github Actions"
description: "Hugo | GitHub Pages | Github Actions"
date: 2020-02-25T16:49:03+08:00
draft: false
toc: true
categories: "hugo"
tags: ["hugo", "Github"]
img: "http://q67bf0oit.bkt.clouddn.com/v2-aae7b15a75b245b6cffa5698c409ae85_1200x500.jpg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/v2-aae7b15a75b245b6cffa5698c409ae85_1200x500.jpg", desc: "Github Actions"}]
---

之前也折腾过个人博客，从大学时候玩的 Wordpress、Ghost，最近又开始折腾博客。由于我个人是比较喜欢通过Github来做博客系统的，对比了目前市面上比较主流的博客系统，比如Hexo、Hugo， 顺便推荐一下国内比较活跃的 Java 开源博客系统 Halo，更多可移步：https://github.com/halo-dev/halo

这一次我选择了 Hugo，一方面是为了降低维护成本，最实际的则是降低服务器成本。至于对Github pages速度太慢的问题我将采用CDN加速解决。

## 首先来将一下整个流程的大致原理：

![hugo 流程图](http://q67bf0oit.bkt.clouddn.com/blog/hugo-flow.jpg)

本地添加文章，提交到Github，之后会自动触发Github Actions帮助我们把刚刚添加的文章通过Hugo发布到Github Pages进行托管。之后即可通过 Github 给 Pages 生成的 URL 访问即可。我将Hugo源码和Pages分别用两个仓库来管理，Github Actions会将Hugo仓库（**JaredTan95.github.io.source**）源码编译成静态资源推到Pages仓库（**JaredTan95.github.io**）

## 详细步骤

- 创建 `JaredTan95.github.io.source` 仓库：

我将源码仓库设置为了 Private，看个人需求。
![JaredTan95.github.io.source](https://imgkr.cn-bj.ufileos.com/f6a667be-d64e-4c71-9067-ff5185d3a3fd.png)

- 创建 `JaredTan95.github.io` 仓库：

![JaredTan95.github.io](https://imgkr.cn-bj.ufileos.com/4c223d1d-9fcc-4ba5-b3e0-5ef0df4633eb.png)

- 为两个仓库绑定 SSH Key：

因为当我们在通过Git提交源码之后，Github Actions会编译生成静态文件并通过Git Push到 **`JaredTan95.github.io`**，因此这一步需要 Git 账户认证。

我们先生成一对SSH Key，生成的Public Key和Private Key都会用到，我采用如下方式生成：


![ssh key](https://imgkr.cn-bj.ufileos.com/a3ee750d-8585-4ead-89f7-d8c5189273aa.png)

*注意：上图红框标注的这里覆盖了默认的生成路径，这样就不会影响到电脑中旧的SSH Key。*

这一步比较重要，我们要将生成的 **Public Key** 添加到 `JaredTan95.github.io` 仓库：

![public key](https://imgkr.cn-bj.ufileos.com/8a31e887-907c-4635-896c-b55e35d2c692.png)

然后将 **Private Key** 添加到 `JaredTan95.github.io.source` 仓库：
这里 Secrets 变量名要一定是： **ACTIONS_DEPLOY_KEY**, 后面会用到。
![Private Key](https://imgkr.cn-bj.ufileos.com/cdaecbc4-62be-40f6-a574-962e663d156b.png)

- 将 `JaredTan95.github.io.source` 仓库克隆到本地，开始初始化 Hugo 系统：

```
# 选取一个目录
cd ~/Desktop/

# 克隆 source 仓库
git clone git@github.com:JaredTan95/JaredTan95.github.io.source.git

# 进入仓库
cd JaredTan95.github.io.source/ 
```

生成 Hugo 源码并进行配置：
```
# 在当前目录生成 Hugo 源码
hugo new site . 

# 为当前博客选取一个主题，你可以不执行这一命令使用默认的主题
git submodule add https://github.com/halogenica/beautifulhugo.git themes/beautifulhugo 

# 编辑 config.toml 配置文件，使 beautifulhugo 主题生效
echo 'theme = "beautifulhugo"' >> config.tomlecho 'theme = "beautifulhugo"' >> config.tom

# 此时你就可以运行预览效果
hugo serve
```

![hugo serve](https://imgkr.cn-bj.ufileos.com/0b7ace2e-b496-4815-9183-2d077bbdef2e.png)

![hugo serve](https://imgkr.cn-bj.ufileos.com/2b2f719a-5685-4fae-9085-ad28881dc63f.png)



如果你觉得满意没问题之后，即可推送到 Github
```
git add .
git commit -m "first commit"
git push -u origin master
```

- 最后一步，配置 Github 自动构建发布 Actions 即可：

可以通过 Github 自动为我们仓库生成，注意是为 `JaredTan95.github.io.source` 仓库配置 Actions。

![Actions](https://imgkr.cn-bj.ufileos.com/9afb591d-69ce-4563-a719-86ad1878cb12.png)

直接将以下文件贴进去，修改远程仓库即可，其他的基本上不用更新：

```yml
name: Deploy Hugo Site to Github Pages on Master Branch

on:
  push:
    branches:
      - master

jobs:
  build-deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v1  # v2 does not have submodules option now
       # with:
       #   submodules: true

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.62.2'
          # extended: true

      - name: Build
        run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          deploy_key: ${{ secrets.ACTIONS_DEPLOY_KEY }} # 这里的 ACTIONS_DEPLOY_KEY 则是上面设置 Private Key的变量名
          external_repository: JaredTan95/JaredTan95.github.io # Pages 远程仓库 
          publish_dir: ""
          keep_files: false # remove existing files
          publish_branch: master  # deploying branch
          commit_message: ${{ github.event.head_commit.message }}

```

![flow yml](https://imgkr.cn-bj.ufileos.com/df96aa97-2dc5-44ca-b22a-41cd0c88b4ab.png)

修改好之后，点击右上角 commit 提交即可。我们可以手动触发打包动作也可以在本地重新commit一次，检查流水线是否会被触发。

触发之后可以查看流水线日志：


![flow log](https://imgkr.cn-bj.ufileos.com/4becaeb8-2a99-414f-93be-98c9e4d818d6.png)

自此，整个搭建就结束了，我们可以访问Github为`JaredTan95/JaredTan95.github.io` 仓库生成的域名： `https://jaredtan95.github.io/`  查看效果。

## 总结
本次搭建耗费了不少时间，主要在于Github访问较慢，克隆Hugo主题也比较慢。目前唯一的不足则是Github Pages访问较慢，后面通过自定义域名+CDN加快访问速度。
