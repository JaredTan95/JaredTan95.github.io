---
keywords:
- 一万小时极客
- ELK
- Elasticsearch
- Elastic
- Logstash
- Kibana
- 学习ELK
title: "解决 Elasticsearch 7.x 以前的版本，type 不一致导致写入数据失败"
subtitle: ""
description:
date: 2020-03-13T12:57:07+08:00
draft: false
toc: true
categories: "middleware"
tags: ["ELK","Elasticsearch","Logstash","Kibana"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/es.jpg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/illustration-elasticsearch-heart.png", desc: "elastic"}]
---

当ES Client写数据的时候报了如下错误：

>2020-03-13 10:00:41.076 ERROR 9 --- [Report ES Thread 0] .g.c.c.AbstractElasticsearchReportClient : item: 2634ef87-ec48-4d38-899f-508ba8b69b9c, errorReason: Rejecting mapping update to [journal_test] as the final mapping would have more than 1 type: [default, doc]

意思就是说你写入的数据的中的`type` 与你创建索引时指定`type`不一致。比如我创建时 `"_type":"_doc"`,而写入时为 ``"_type":"default"``。因此，有两种办法，要么修改写入数据时的 type ，要么修改当前索引的 type 。

考虑到更改写入时候的 type 就得重启应用，会影响用户使用。所以这里采用**修改当前索引**的方法。

提供一种最简单的解决思路：通过 Elasticsearch 的 `reindex` 功能将当前索引 `journal_test` 备份至 `journal_test_back` 索引并删除 `journal_test`,让 ES 根据写入数据时自动生成 type 为 `default` 的索引。随后将备份数据导出到文件，修改文件中 type 为 `default`。再写入原来新的 `journal_test_2` 索引。

### 将 journal_test_2 索引数据备份至 journal_test_2_bak索引：

```curl
curl -X POST "localhost:9200/_reindex?pretty" -H 'Content-Type: application/json' -d'
{
  "source": {
    "index": "journal_test"
  },
  "dest": {
    "index": "journal_test_back"
  }
}
'
```

###  删除 journal_test 索引，让你的应用再次写入数据时 ES 自己创建索引：

```curl
curl -X DELETE "http://localhost:9200/journal_test"
```

### 将 `journal_test_back` 数据导出到 my_index_mapping.json 文件中

这里借助工具：https://github.com/taskrabbit/elasticsearch-dump，将 备份数据导出到我本地 `Desktop` 目录下：

```bash
docker run --rm -ti -v ~/Desktop:/tmp taskrabbit/elasticsearch-dump \
 --input=http://localhost:9200/journal_test_back \
 --output=/tmp/my_index_mapping.json \
 --type=data
```

编辑 my_index_mapping.json 文件,将 type 修改为 `default`。注意，为了不影响原来的备份数据，我将修改后的数据写入到新的文件(my_index_mapping_default.json)中：

```bash
cat my_index_mapping.json| sed s/\"_type\":\"doc\"/\"_type\":\"default\"/ > my_index_mapping_default.json
```

### 最后一步，将正确的数据导入正确的 `journal_test` 索引中：

```bash
docker run --rm -ti -v ~/Desktop:/tmp taskrabbit/elasticsearch-dump \
 --output=http://localhost:9200/journal_test \ # 注意索引名
 --input=/tmp/my_index_mapping_default.json \ #注意这里使用的文件
 --type=data
```

## 总结

这里提供了最简单的一种解决办法，当然还可以利用 Elastisearch 的 script 功能直接进行转化。如果你有更多方法，留言吧～


