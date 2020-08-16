---
keywords:
- 一万小时极客
- Skywalking
- Openresty
- Elasticsearch
- Java
title: "Skywalking OAP 后端出现【 id  is  too  long】异常"
subtitle: "Skywalking OAP 后端写入 ES 时出现【 id  is  too  long】异常"
description:
date: 2020-03-20T16:01:58+08:00
draft: false
toc: true
categories: "APM"
tags: ["Apache Skywalking", "Nginx", "OpenResty", "Lua"]
img: "http://cdn.jared-says.cn/687474703a2f2f736b7977616c6b696e672e6170616368652e6f72672f6173736574732f6672616d652d76382e6a70673f753d3230323030343233.jpeg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/19225044_MRmZ.jpg", desc: ""}]
---

进入 Skywalking OAP 容器，日志中出现如下异常日志：

![oap logs](http://q67bf0oit.bkt.clouddn.com/blog/WX20200320-153815@2x.png)

还有如下日志：

```bash
2019-03-0109:12:11,578- org.apache.skywalking.oap.server.core.register.worker.RegisterPersistentWorker-3264081149[DataCarrier.IndicatorPersistentWorker.endpoint_inventory.Consumser.0.Thread] ERROR []-ValidationFailed:1: id is too long, must be no longer than 512 bytes but was:684;

org.elasticsearch.action.ActionRequestValidationException:ValidationFailed:1: id is too long, must be no longer than 512 bytes but was:684;
```

根据第一张图片中的异常信息，猜测是探针在往 OAP 注册，而 OAP 正在将元数据写入到 Elasticsearch 中由于 id 值太长报错了。同理，是因为skywalking 在往elasticsearch 中 endpoint_inventory 索引写数据时，索引的 id 值太长了。这种频率在疯狂的刷新。

随后深入 Elasticsearch 源码发现：server/src/main/java/org/elasticsearch/action/index/IndexRequest.java

```java
        if (id != null && id.getBytes(StandardCharsets.UTF_8).length > 512) {
            validationException = addValidationError("id is too long, must be no longer than 512 bytes but was: " +
                            id.getBytes(StandardCharsets.UTF_8).length, validationException);
        }
```

不过这里并没有具体指出是哪一个 id 过长，不太方便排查。因此，提了一个 PR 将具体信息输出来，不过得在 Elasticsearch 8.0 才有。
相关 PR：https://github.com/elastic/elasticsearch/pull/49433

## 该异常可能造成结果

当 Skywalking OAP 在注册或者写入 ES 时，当服务名、实例名或者 URL 名过长就会导致该异常。而 skywalking 注册/写入失败后会不断的重试，就会有上面日志不断刷的现象。严重后果可能导致 Skywalking OAP 不可用。

## 如何避免？

注意服务名、实例名、URL 名称不要取太长即可。


