---
keywords:
- 一万小时极客
- ELK
- Elasticsearch
- Elastic
- Logstash
- Kibana
- 学习ELK
title: "Elastic Stack 之 Kibana UI界面使用"
subtitle: "道生一，一是数据；一生二，二是数据存储，将数据从无形态化为有形态；二生三，三是数据分析"
description: "介绍 Kibana 数据分析界面"
date: 2020-03-05T14:16:36+08:00
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

两篇文章介绍了 Elasticsearch 是什么，以及怎么搭建 Elasticsearch，并介绍了简单的一些查看 Elasticsearch 信息的 API，但是并没有讲解怎么往  Elasticsearch 中写入数据或者怎么存储/查询数据。是因为考虑到通过 UI 操作对刚开始学习 Elasticsearch 更加友好。所以，如何安装 Kibana 以及如何通过 Kibana 写入、查询数据将是本文的重点。

## Kibana 安装

这里还是采用 Docker 方式安装 Kibana，其实很简单，只需要如下简单命令：

```yaml
version: '2'
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:7.6.1
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch.example.org # 这里配置ES地址。
```

之前讲过，Kibana 只是为了更友好的从 ES 查询、分析数据。前提还是要连接上 ES。所以，你可以使用如下 Docker Compose 编排文件，同时安装 ES 和 Kibana：

`docker-compose.yml` 文件：
```yml
version: '2.2'
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.6.1
    container_name: es01
    environment:
      - node.name=es01
      - discovery.type=single-node
      - cluster.name=es-docker
      - bootstrap.memory_lock=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data01:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - elastic

  kibana:
    image: docker.elastic.co/kibana/kibana:7.6.1
    ports:
      - 5601:5601
    environment:
      ELASTICSEARCH_HOSTS: http://es01:9200 # 这里配置ES地址。
    networks:
      - elastic

volumes:
  data01:
    driver: local

networks:
  elastic:
    driver: bridge
```

通过 docker-compose 启动：

```bash
docker-compose up -d
```

启动完成之后可以访问 `http://localhost:5601/`:

![Kibana UI](http://q67bf0oit.bkt.clouddn.com/blog/kibana.png)

从图中左侧可以看到， Kibana 提供了很多功能，包括 Dashboard 面板、Dev Tools 开发工具（可以在里面使用QSL语句进行数据实验）、 APM 应用性能监控系统、Logs 日志、Metrics 指标分析、以及新兴的 Machine Learning 机器学习。

我们先从 Dev Tools 工具讲起，也是我们平时使用较多的一个工具, 该工具提供了语法提示，以及快速执行查询的便捷操作：

![Dev Tools](http://q67bf0oit.bkt.clouddn.com/blog/WX20200315-105927.png)

如上图，往 `hello` 索引中写入了一条数据，再从索引中查询出数据。关于 QSL 语法可以查看官方的文档：https://www.elastic.co/guide/en/elasticsearch/reference/7.6/rest-apis.html

接下来讲讲 Kibana 对 ES 的监控功能，目的是为了监控 Kibana 所连接的 ES 集群的健康状态：

![monitoring](http://q67bf0oit.bkt.clouddn.com/blog/WX20200315-110237.png)

可以从该面板中查看当前 ES 集群健康总览、当前节点数量以及每个节点资源消耗情况、当前集群 ES 索引情况：

![overview](http://q67bf0oit.bkt.clouddn.com/blog/WX20200315-111055.png)

![es overview](http://q67bf0oit.bkt.clouddn.com/blog/WX20200315-111230.png)

## 总结

本文介绍了如何安装 Kibana 以及如何通过 Kibana 写入、查询数据，同时介绍了 Kiabna 常用强大的界面功能。