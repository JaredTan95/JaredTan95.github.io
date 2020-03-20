---
keywords:
- 一万小时极客
- ELK
- Elasticsearch
- Elastic
- Logstash
- Kibana
- 学习ELK
title: "Logstash 的安装与导入数据"
subtitle: "ELK 之 Logstash 的安装与导入数据"
description:
date: 2020-03-20T13:41:07+08:00
draft: false
toc: true
categories: "middleware"
tags: ["ELK","Elasticsearch","Logstash","Kibana"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/es.jpg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/illustration-elasticsearch-heart.png", desc: "elastic"}]
---

## 前文回顾：
- [《那些年我们一起学过的 Elasticsearch》](../elk-again)
- [《反手几行命令就安装了一个 Elasticsearch 环境》](../elk-01)
- [《Elastic Stack 之 Kibana UI界面使用》](../elk-02)

上一节主要介绍了数据可视化工具 Kibana 工具的使用，不过并没有过多的介绍怎么大量的导入数据。

这一节我们将实践将著名数据集导入 Elasticsearch，前提条件是 ES 已经安装好了，可以参考[《Elastic Stack 之 Kibana UI界面使用》](../elk-02) 将 ES 和 Kibana 安装好。

## 数据集下载

下载地址：https://grouplens.org/datasets/movielens/

![我们选择最小数据集即可](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-134907@2x.png)

## Logstash 下载与安装

首先去官网下载 Logstash 安装包：https://www.elastic.co/downloads/logstash

![logstash download](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-135234@2x.png)

如果下载速度太慢可以选用这个代理地址下载：http://mirror.azk8s.cn/elastic/logstash/

![azk8s](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-135408@2x.png)

下载完安装包并解压进入 `config` 目录：

![logstash-config](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-135521@2x.png)

同时配置如下内容,你只需要按照你的数据集的路径改一下配置文件中最开始的`path`即可：

- logstash.conf

```conf
input {
  file {
    path => "/Users/tanjian/Desktop/logstash-7.6.1/movielens/ml-latest-small/movies.csv" # 这里指定数据集路径
    start_position => "beginning"
    sincedb_path => "/dev/null"
  }
}
filter {
  csv {
    separator => ","
    columns => ["id","content","genre"]
  }

  mutate {
    split => { "genre" => "|" }
    remove_field => ["path", "host","@timestamp","message"]
  }

  mutate {

    split => ["content", "("]
    add_field => { "title" => "%{[content][0]}"}
    add_field => { "year" => "%{[content][1]}"}
  }

  mutate {
    convert => {
      "year" => "integer"
    }
    strip => ["title"]
    remove_field => ["path", "host","@timestamp","message","content"]
  }

}
output {
   elasticsearch {
     hosts => "http://localhost:9200"
     index => "movies"
     document_id => "%{id}"
   }
  stdout {}
}
```

## Logstash 运行

配置好上面的 `logstash.conf` 文件后，我们就可以启动 Logstash 并开始导入数据了：

```bash
sudo ./bin/logstash -f config/logstash.conf 
```

如下图 Logstash 日志所示，正在导入数据集：

![logstash log](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-133629@2x.png)

## 打开 Kibana 查看数据

在查看数据之前，我们需要打开 `http://localhost:5601` 通过 Kibana 创建一个 Index Pattern：

![Index Pattern](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-133845.png)

之后，我们就可以通过 `Discover` 去查看我们的数据了：

![Discover](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-133909.png)

剩下的就交给你自己折腾吧，你可以去 `Dev Tools` 通过 QSL 语法搜索数据熟悉一下语法。

## 总结

本文通过安装 Logstash 与导入数据集学会了 Logstash 基本使用。
