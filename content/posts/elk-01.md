---
keywords:
- 一万小时极客
- ELK
- Elasticsearch
- Elastic
- Logstash
- Kibana
- 学习ELK
title: "反手几行命令就安装了一个 Elasticsearch 环境"
subtitle: "道生一，一是数据；一生二，二是数据存储，将数据从无形态化为有形态；二生三，三是数据分析"
description: "介绍通过压缩包和Docker安装Elasticsearch 环境"
date: 2020-03-02T22:19:31+08:00
draft: false
toc: true
categories: "middleware"
tags: ["ELK","Elasticsearch","Logstash","Kibana"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/es.jpg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/illustration-elasticsearch-heart.png", desc: "elastic"}]
---

## 三生万物

上文[《那些年我们一起学过的 Elasticsearch》](../elk-again)中提到了以 Elasticsearch 为核心，逐步衍生成了 ELK 技术栈，让我想到了道德经中的一句话。
道德经阐述到：“道生一，一生二，而二生三，三生万物”。

同时，布瑞恩(Brain Godsey)在《数据即未来》中提出：“数据科学家专注于创建依赖于数据和结果的概率陈述系统；数据科学是指导数据项目开展和决策的一系列过程和概念”；布瑞恩提出的思想与中国的太极和道德经一表一里互补的哲学思想也有着很大的相似性。

按照这样来看，那么，道生一，一是数据；一生二，二是数据存储，将数据从无形态化为有形态；二生三，三是数据分析；三生万物，是指一切存在物都是由阴、阳、和三态构成，那么最终形成的大数据则可以被理解为太极或和的形态，它能够不断发现或发明新的算法或则模式，将人类从已经形态带入一个未知的形态。未知充满了一切可能。

那和本篇文章有什么关系呢？

## 数据存储

ELK系列文章将从数据存储开始，既然产生了数据，我们则需要抓取、存储、展示。让数据从无形态化为固定形态。如何抓取数据超纲了，本篇文章主要通过 Elasticsearch 解决数据存储的问题，文章中会介绍到如何在本地安装ES以及安装多实例做ES集群。因为前面说到了ES是很方便做水平扩展的，通过多实例安装将有助于你后期分布式安装ES集群。

如果你去看过ES [Github项目地址](https://github.com/elastic/elasticsearch)的话，你应该了解到ES使用Java语言开发的。那么如果要安装ES的话一定是需要Java环境的。

此次系列文章均采用**7.6.0**最新版本。

所以我在纠结系列文章是以Java方式安装还是Docker运行环境安装之后，考虑到无论哪一种安装方式，工作量其实差不多，不过考虑到都已经2020*云原生*时代了，用Docker或许是更加友好、更便捷的方式。

第一篇就介绍两种方式安装吧，后面就基本采用Docker讲解了。

### 通过压缩包安装 Elasticsearch

从[官方下载ES](https://www.elastic.co/downloads/elasticsearch)压缩包的话里面已经自带了JDK环境，如果下载很慢的话，可以使用国内华为云镜像加速下载：https://mirrors.huaweicloud.com/elasticsearch/7.6.0/

![下载ES](http://q67bf0oit.bkt.clouddn.com/blog/WX20200303-153527@2x.png)

下载并解压之后，来大致看看文件目录结构：

```bash
LICENSE.txt # 软件包版权信息
NOTICE.txt
README.asciidoc
bin # 脚本文件
config # 配置文件，包含了主要的 elasticsearch.yml和 jvm.options 文件
jdk   # es 运行的 java 环境
lib # java 运行所使用的类库
logs # es 运行期间默认的日志文件目录
modules # 包含了ES所有的模块，
plugins # ES 提供了插件的方式去安装和扩展。你也可以自己去实现自己的插件然后丢到这里面。
```

关于配置文件，可以暂时不管。等到后面需要进行改动的时候再做介绍。

- 首先，让我们通过 bin 目录下的脚本在本地启动一个单实例：

```bash
./bin/elasticsearch

······
onitoring-kibana-7-*]
[2020-03-03T16:35:41,530][INFO ][o.e.x.i.a.TransportPutLifecycleAction] [tanjiandeMacBook-Pro-2.local] adding index lifecycle policy [watch-history-ilm-policy]
[2020-03-03T16:35:41,561][INFO ][o.e.x.i.a.TransportPutLifecycleAction] [tanjiandeMacBook-Pro-2.local] adding index lifecycle policy [ilm-history-ilm-policy]
[2020-03-03T16:35:41,700][INFO ][o.e.x.i.a.TransportPutLifecycleAction] [tanjiandeMacBook-Pro-2.local] adding index lifecycle policy [slm-history-ilm-policy]
[2020-03-03T16:35:41,858][INFO ][o.e.l.LicenseService     ] [tanjiandeMacBook-Pro-2.local] license [cc5e519d-547e-4134-bd26-2e2c93adb2cf] mode [basic] - valid
[2020-03-03T16:35:41,859][INFO ][o.e.x.s.s.SecurityStatusChangeListener] [tanjiandeMacBook-Pro-2.local] Active license is now [BASIC]; Security is disabled
```

随后，我们通过浏览器访问：`http://localhost:9200` 就可以看到，一个ES单实例的环境就已经在我们本地启动好啦：

![es url](http://q67bf0oit.bkt.clouddn.com/blog/WX20200303-163727@2x.png)

输入`http://localhost:9200/_cat` 可以看到一些查询ES运行状况的API：

```text
······
/_cat/master # 显示当前ES集群的master节点信息
/_cat/nodes # 显示当前ES集群的所有节点信息
/_cat/indices # 显示当前ES集群中存在的索引Index
/_cat/health # 显示当前ES集群的健康信息
/_cat/plugins # 显示当前ES集群中已经安装的插件
·······
```

- ES 插件安装

上面讲到了ES可以通过插件的形式安装自己需要的功能，这里就演示一下安装最通用的一个国际化分词插件：`analysis-icu`
退出/停止刚刚正在运行的ES实例，执行如下命令即可：

```bash
./bin/elasticsearch-plugin install analysis-icu
·······
-> Installing analysis-icu
-> Downloading analysis-icu from elastic
[============================================>] 100%
-> Installed analysis-icu
```

我们来查看一下是否安装成功了：

```bash
./bin/elasticsearch-plugin list
·······
analysis-icu
```

随后，我们需要再次启动即可。

- 接下来，让我们安装一个三个实例的ES集群吧：

在ES中，只要我们每次启动指定**相同**的集群名字，指定**不同**节点名称，指定**不同**的存放数据地址，就可以运行多实例。
其实，这里为我们隐藏了一些逻辑：执行多个实例，而且在没更改端口的情况下一般应用可能会出现端口冲突的报错。而如下命令在执行之后会自动检测端口并更改端口避免冲突。

```bash
./bin/elasticsearch -E node.name=node1 -E cluster.name=local-es-cluster -E path.data=node1_data -d 
./bin/elasticsearch -E node.name=node2 -E cluster.name=local-es-cluster -E path.data=node2_data -d 
./bin/elasticsearch -E node.name=node3 -E cluster.name=local-es-cluster -E path.data=node3_data -d
```
上面三个命令执行完过后，会在后台运行三个ES实例，此时，我们再次通过浏览器访问上面提到的查看ES集群节点的API：`http://localhost:9200/_cat/nodes` 

```bash
127.0.0.1 18 100 24 7.09   dilm * node1 # node1 带了一个 * ，说明node1是master节点
127.0.0.1 13 100 24 7.09   dilm - node2
127.0.0.1 11 100 23 7.09   dilm - node3
```

如何停止刚刚的三个实例？

```bash
# 首先列出那些ES进程
$ ps | grep elasticsearch
······
31739 ttys006    0:56.06 /Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home//bin/java -Des.networkaddress.cache.ttl=60 
31758 ttys006    0:56.77 /Library/Java/JavaVirtualMachines/jdk1.8.0_211.jdk/Contents/Home//bin/java -Des.networkadd
·······

# 通过kill 命令杀掉相关进程即可
$ kill 31758
$ kill 31739
```

### 通过Docker安装 Elasticsearch

所以，我们来先安装Docker环境，这一步很简单。只需要去[Docker官网](http://q67bf0oit.bkt.clouddn.com/blog/WX20200303-151053@2x.png)下载相应平台的安装包安装即可。另外，如果你对Kubernetes感兴趣的话，可以试试Docker Desktop集成的最小化Kubernetes环境。

Doceker 安装好之后，我们检查一下：

```bash
$ docker --version
Docker version 19.03.5, build 633a0ea
```

如上说明Docker已经安装好了，通过Docekr 安装其实很简单，只需要一行命令即可：

- 安装单实例

```bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.6.0
```

该命令会从镜像仓库自动拉取ES镜像并运行一个ES容器，如果发现拉取镜像很慢的话可以配置一下使用国内DaoCloud的镜像加速器：https://www.daocloud.io/mirror。

- 安装多实例：通过 Docker-Compose 编排

创建`docker-compose.yml` 文件：

```yml
version: '2.2'
services:
  es01:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.6.0
    container_name: es01
    environment:
      - node.name=es01
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es02,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
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
  es02:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.6.0
    container_name: es02
    environment:
      - node.name=es02
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es03
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data02:/usr/share/elasticsearch/data
    networks:
      - elastic
  es03:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.6.0
    container_name: es03
    environment:
      - node.name=es03
      - cluster.name=es-docker-cluster
      - discovery.seed_hosts=es01,es02
      - cluster.initial_master_nodes=es01,es02,es03
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - data03:/usr/share/elasticsearch/data
    networks:
      - elastic

volumes:
  data01:
    driver: local
  data02:
    driver: local
  data03:
    driver: local

networks:
  elastic:
    driver: bridge
```

随后，在执行`docker-compose.yml`同级目录执行 `docker-compose up -d` 即可启动三实例的ES集群运行在后台，通过`docker-compose stop`即可停止运行。

## 总结

这一篇实际操作比较多，主要介绍了通过压缩包和Docker安装单实例和多实例的ES集群。

关于文章任何疑问都可以在这里得到解答，或者通过公众号联系到我个人微信。

![加群](http://q67bf0oit.bkt.clouddn.com/blog/WechatIMG82.jpeg)