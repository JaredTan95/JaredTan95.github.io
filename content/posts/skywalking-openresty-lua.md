---
keywords:
- 一万小时极客
- Skywalking
- Openresty
- Lua
- Java
title: "当 Openresty/Nginx 遇上 Skyalking"
subtitle: ""
description: "当我们的使用Nginx/Openresty 为我们的微服务做负载均衡的时候，怎样才能将整条链路通过请求串起来，以及怎样保证整个链路的拓扑图正确呢?"
date: 2020-03-06T22:19:31+08:00
draft: false
toc: true
categories: "APM"
tags: ["Apache Skywalking", "Nginx", "OpenResty", "Lua"]
img: "http://cdn.jared-says.cn/687474703a2f2f736b7977616c6b696e672e6170616368652e6f72672f6173736574732f6672616d652d76382e6a70673f753d3230323030343233.jpeg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/19225044_MRmZ.jpg", desc: ""}]
---

> Skywalking 支持 HTTP 1.1 的 PR 折腾了我好久，E2E 端到端测试是真的把我搞“怕”了···

## OpenResty 是什么？

OpenResty是一个基于 Nginx 与 Lua 的高性能 Web 平台，其内部集成了大量精良的 Lua 库、第三方模块以及大多数的依赖项。用于方便地搭建能够处理超高并发、扩展性极高的动态 Web 应用、Web 服务和动态网关。

因此，很多公司都会使用 OpenResty 开发出适合自己业务的高性能 web Server 模块。

那么它和 Skywalking 有什么关心呢？我们得先知道Skywalking是什么，Skywalking 是由Java 语言开发的一套APM系统，主要监控服务与服务之间的调用链路以及服务应用指标。官方的介绍是：分布式系统的应用程序性能监视工具，专为微服务、云原生架构和基于容器（Docker、K8s、Mesos）架构而设计。具体可以移步 Github: https://github.com/apache/skywalking

假设，当我们的使用Nginx/Openresty 为我们的微服务做负载均衡的时候，怎样才能将整条链路通过请求串起来，以及怎样保证整个链路的拓扑图正确呢？
目前的解决方案是在 Nginx 中支持链路信息的上报，同时能够将请求链路关键信息传递给上游应用。

## Apache Skywalking Nginx Lua 项目
Githu项目地址：https://github.com/apache/skywalking-nginx-lua，该项目是吴晟采用 Lua 实现的 Nginx/Oopenresty SDK。主要就是实现将 Nginx 作为一个节点注册至Skywalking，同时将链路 TraceId 传递给上游服务，并将链路上报给 Skywalking。

## Skywalking 7.x 开始支持 HTTP 1.1

> 具体PR请参考: https://github.com/apache/skywalking/pull/4399

Skywalking 监控 Java、Golang、Node、.NET 语言的链路都是采用了 SDK 或者 Agent 的方式将数据上报到 Skyalking 后端。不过都是采用 gRPC 的方式和后端交互，**Apache Nginx Lua** 考虑到 Nginx 足以胜任 10K 以上并发连接响应，并没有采用 Nginx gRPC的方式，因此需要 Skywalking 支持 HTTP 1.1 的通信接口。


## 怎么玩起来？
这里先画一个怎么玩的逻辑图：

![skywalking_nginx_lua](http://q67bf0oit.bkt.clouddn.com/blog/skywalking_nginx_lua.png)

怎么搭建Skywalkng 的流程就不再赘述了，不是本文的重点，着重介绍怎么跑**Skywalking Nginx Lua**。
可以查看 Skywalkng 教程可以查看发布在**哔哩哔哩**上面的教程：https://www.bilibili.com/video/av35990012/

- 首先安装 Openresty
参照官网：https://openresty.org/cn/download.html

Macos 系统采用 Homebrew 安装：

```
> brew install openresty/brew/openresty

==> Summary
🍺  /usr/local/Cellar/openresty/1.15.8.2: 303 files, 6.5MB, built in 1 minute
==> Caveats
==> openresty-openssl
openresty-openssl is keg-only, which means it was not symlinked into /usr/local,
because only for use with OpenResty.

If you need to have openresty-openssl first in your PATH run:
  echo 'export PATH="/usr/local/opt/openresty-openssl/bin:$PATH"' >> ~/.zshrc

For compilers to find openresty-openssl you may need to set:
  export LDFLAGS="-L/usr/local/opt/openresty-openssl/lib"
  export CPPFLAGS="-I/usr/local/opt/openresty-openssl/include"

==> openresty
To have launchd start openresty/brew/openresty now and restart at login:
  brew services start openresty/brew/openresty
Or, if you don't want/need a background service you can just run:
  openresty
```

- 克隆或者下载 Apache Nginx Lua库

```bash
git clone https://github.com/apache/skywalking-nginx-lua.git 
cd skywalking-nginx-lua/examples/
```

该目录存放了关于Nfinx的样例配置，如下是部分内容：

- nginx.conf：

```conf
http {
   # 这里指向刚刚克隆下来的 skywalking nginx lua项目
    lua_package_path "path/to/skywalking-nginx-lua/lib/skywalking/?.lua;;";
    # Buffer represents the register inform and the queue of the finished segment 
    lua_shared_dict tracing_buffer 100m;
    
    init_worker_by_lua_block {
        local metadata_buffer = ngx.shared.tracing_buffer

        metadata_buffer:set('serviceName', 'User Service Name')
        -- Instance means the number of Nginx deloyment, does not mean the worker instances
        metadata_buffer:set('serviceInstanceName', 'User Service Instance Name')

        # 这里需要指定上报Skywalking 的后端地址。端口默认是12800
        require("client"):startBackendTimer("http://127.0.0.1:12800")
    }

    server {
        listen 8080;
        location /test {
            default_type text/html;

            rewrite_by_lua_block {
                require("tracer"):start("upstream service")
            }
            # 这里则是 上图中 nginx 上游服务的地址
            proxy_pass http://127.0.0.1:8080/upstream/test;
            body_filter_by_lua_block {
                if ngx.arg[2] then
                    require("tracer"):finish()
                end
            }
            log_by_lua_block {
                require("tracer"):prepareForReport()
            }
        }
    }
}
```

- 直接启动 OpenResty 即可，并指定配置文件,例如：

```bash
openresty -c /Users/tanjian/gitprojects/skywalking-nginx-lua/examples/nginx.conf
```

## 疑问？
私信联系我吧 :）

![](http://q67bf0oit.bkt.clouddn.com/blog/WX20200307-133600@2x.png)
