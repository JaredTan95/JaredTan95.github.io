---
keywords:
- 抠腚Coding笔记
- gRPC
- Java
title: "gRPC 简介并实战——文末附源码"
subtitle: ""
description: "在本文中，介绍了如何使用 gRPC 来简化两个服务之间的通信开发，与此同时，我们可以更加专注地定义服务以及更加专注的实现我们的业务逻辑。"
date: 2020-02-26T15:05:46+08:00
draft: false
toc: true
categories: "java"
tags: ["Java", "gRPC", "ProtoBuf"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/640.png"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/640.png", desc: "Google gRPC"}]
---

## 1. 介绍

**gRPC 是一个高性能的开源 RPC 框架，最初由 Google 开发。** 

RPC 是什么？在客户端应用里可以像调用本地方法对象一样直接调用另一台不同机器上的服务端应用的方法。国内开源的 RPC 框架有阿里Dubbo、蚂蚁金服的 SOFA-RPC、百度 bRPC、新浪 Motan等等。

废话不多说，直接就开始使用 gRPC。**文末附源码链接。**

## 2. 概述

本文将使用以下步骤使用 gRPC 创建典型的C/S服务：

1. 首先在 `.proto` 文件中定义服务: gRPC 使用 `protobuf` 作为 IDL，明确定义了参数及类型。
2. 通过  `protobuf` 编译器自动生成客户端-服务端通信 Stub 的代码。
3. 创建服务器端的程序，并对 stub 进行实现。
4. 创建客户端应用程序，使用生成的 stub 进行 RPC 调用服务端方法。

我们先来定义一个简单的 `HelloService` 服务，它返回问候语和姓名。

## 3. Maven 依赖

这里添加 `grpc-netty` , `grpc-protobuf` 和 `grpc-stub` 三个依赖:

```xml
<dependency>
    <groupId>io.grpc</groupId>
    <artifactId>grpc-netty</artifactId>
    <version>1.16.1</version>
</dependency>
<dependency>
    <groupId>io.grpc</groupId>
    <artifactId>grpc-protobuf</artifactId>
    <version>1.16.1</version>
</dependency>
<dependency>
    <groupId>io.grpc</groupId>
    <artifactId>grpc-stub</artifactId>
    <version>1.16.1</version>
</dependency>
```

## 4.定义 `.proto` 文件

创建 `HelloService.proto` 文件，并开始如下定义：

```protobuf
syntax = "proto3"; // 告诉编译器此文件使用什么版本的语法，而且默认情况下，编译器在单个 Java 文件中生成所有 Java 代码。
option java_multiple_files = true; // 可选配置，再次告诉编译器所有内容都将在单个文件中生成。
package com.github.jaredtan95.demo.grpc; //最后，我们指定要用于生成的 Java 类的包。


// 定义消息结构体，相当于 Http Request
// 并对每个属性都定义数据类型，需要为每个属性分配一个唯一编号，称为标记。此标记由 protobuf 用于表示属性，而不是使用属性名称。
// 因此，与 JSON 不同，我们每次都会传递属性名称 name，而 protobuf 将使用数字 1 来表示 name。
message HelloRequest {
    string firstName = 1;
    string lastName = 2;
}

// 定义消息结构体，相当于 Http Response
// 这里的响应体定义与 `HelloRequest` 类似。需要注意的是，我们可以在多个消息类型之间使用相同的标记：
message HelloResponse {
    string greeting = 1;
}

// 最后，让我们定义服务(method)。对于我们的 HelloService，我这里定义了一个 hello() 操作：单次接受一个请求并返回一个响应
service HelloService {
    rpc hello(HelloRequest) returns (HelloResponse);
}

```

另外要指出的是，gRPC 还支持通过将 `stream` 关键字来标示是否进行流式处理。
也就是说，客户端和服务端交互有四种情况，客户端流式/非流式——服务端流式/非流式。

## 5. 生成代码

现在，我们需要将 `HelloService.proto` 文件传递 protobuf 编译器 `protoc` 来生成 Java 文件。有多种方法可以触发此功能。

- 如果采用 protoc 编译器 的方式，这也是最简单的一种方式：

首先你需要下载编译器：https://developers.google.com/protocol-buffers/docs/downloads， 并通过如下命令来将 HelloService.proto 生成 Java 文件：

```shell
protoc -I=$SRC_DIR --java_out=$DST_DIR $SRC_DIR/HelloService.proto
```

- 当然，你也可以用 Maven 插件的方式：

gRPC 提供了 [protobuf-maven-plugin](https://search.maven.org/classic/#search%7Cga%7C1%7Cg%3A%22org.xolstice.maven.plugins%22%20AND%20a%3A%22protobuf-maven-plugin%22), 在Maven
中添加如下配置：

```xml
<build>
  <extensions>
    <extension>
      <groupId>kr.motd.maven</groupId>
      <artifactId>os-maven-plugin</artifactId>
      <version>1.6.1</version>
    </extension>
  </extensions>
  <plugins>
    <plugin>
      <groupId>org.xolstice.maven.plugins</groupId>
      <artifactId>protobuf-maven-plugin</artifactId>
      <version>0.6.1</version>
      <configuration>
        <protocArtifact>
          com.google.protobuf:protoc:3.3.0:exe:${os.detected.classifier}
        </protocArtifact>
        <pluginId>grpc-java</pluginId>
        <pluginArtifact>
          io.grpc:protoc-gen-grpc-java:1.4.0:exe:${os.detected.classifier}
        </pluginArtifact>
      </configuration>
      <executions>
        <execution>
          <goals>
            <goal>compile</goal>
            <goal>compile-custom</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

上面的 `os-maven` 插件可以生成各种与平台相关的属性。

## 6. 创建服务端程序

不过无论您使用上面哪种方法生成代码，都将生成以下关键文件：

- `HelloRequest.java` 文件， 包含 HelloRequest 请求类型定义
- `HelloResponse.java` 文件，它包 HelloResponse 响应类型定义
- `HelloServiceImplBase.java` 文件，它包含抽象类 `HelloServiceImplBase`，它提供了我们在服务接口中定义的所有操作的实现

### 6.1 重写抽象类 `HelloServiceImplBase`的实现

抽象类 `HelloServiceImplBase` 的默认实现是抛出运行时异常 `io.grpc.StatusRuntimeException`，用于指出该方法未被实现。

让我们来扩展此类并重写服务定义中提到的 `hello()` 方法：

```java
public class HelloServiceImpl extends HelloServiceImplBase {
 
    @Override
    public void hello(
      HelloRequest request, StreamObserver<HelloResponse> responseObserver) {
 
        String greeting = new StringBuilder()
          .append("Hello, ")
          .append(request.getFirstName())
          .append(" ")
          .append(request.getLastName())
          .toString();
 
        HelloResponse response = HelloResponse.newBuilder()
          .setGreeting(greeting)
          .build();
 
        responseObserver.onNext(response);
        responseObserver.onCompleted();
    }
}
```
如果我们将 `hello()` 的签名与我们在 `HellService.proto` 文件中写入的签名进行比较，我们会注意到它不会返回 `HelloResponse`。相反，它将第二个参数称为 StreamObserver<HelloResponse>，它是 `响应观察者`，是服务器调用其响应的`回调`。
正如最开始提到的那样，客户端将获得进行阻塞调用或非阻塞调用（流式）的选项。

gRPC 使用生成器（builder）创建对象。我们使用 HelloResponse.newBuilder() 并设置"hello" 问候语以生成 HelloResponse 对象。我们将此对象设置为响应观察者的 onNext()方法，将其发送到客户端。

最后，我们需要调用 "onCompleted()" 来指定我们已完成对这次 RPC 的处理，否则连接将挂起，客户端将等待更多信息进来。

### 6.2 运行服务端程序

接下来，我们需要启动 gRPC 服务器来监听传入的请求：

```java
public class GrpcServer {
    public static void main(String[] args) {
        Server server = ServerBuilder
          .forPort(8080)
          .addService(new HelloServiceImpl()).build();
 
        server.start();
        server.awaitTermination();
    }
}
```

在这里，我们再次使用生成器(`ServerBuilder`) 在端口 8080 上创建一个 gRPC 服务器，并添加我们定义的 `HelloServiceImpl` 服务。`start()` 将启动服务器。在我们的示例中，我们将调用 `awaittermination()` 以保持服务器在后台保持运行。

## 创建客户端程序

gRPC 提供了一个通道构造，用于抽象基础详细信息，如连接、连接池、负载平衡等。


```java
public class GrpcClient {
    public static void main(String[] args) {
        // 这里使用 `ManagedChannelBuilder` 创建通道，并指定需要连接的服务器地址和端口。
        ManagedChannel channel = ManagedChannelBuilder.forAddress("localhost", 8080)
          .usePlaintext() //这里将使用纯文本，无需任何加密
          .build();
 
        /** 接下来，我们需要创建一个 Stub，我们将用它来进行实际的调用远程的 hello() 方法。Stub（存根）是客户端与服务器交互的主要方式。使用自动生成Stub时，Stub 类包含了用于包装通道（channel）的构造函数。
        **/
        HelloServiceGrpc.HelloServiceBlockingStub stub 
          = HelloServiceGrpc.newBlockingStub(channel);
 
        // 是时候进行 hello() RPC 调用了。在这里，我们传递 Hello 请求。我们可以使用newBuilder 来设置 HelloRequest 对象的姓、名属性。并得到从服务器返回的 HelloResponse 对象。
        HelloResponse helloResponse = stub.hello(HelloRequest.newBuilder()
          .setFirstName("test")
          .setLastName("gRPC")
          .build());
 
        channel.shutdown();
    }
}
```

需要说明的是，上面使用阻塞/同步的存根（newBlockingStub），以便 RPC 调用等待服务器响应，并将返回响应或引发异常。有两种类型的存根由 gRPC 提供，另外一种便于非阻塞/异步调用。


## 8. 总结

在本文中，介绍了如何使用 gRPC 来简化两个服务之间的通信开发，与此同时，我们可以更加专注地定义服务以及更加专注的实现我们的业务逻辑。

最后，Github 源码链接：[https://github.com/JaredTan95/grpc-demo](https://github.com/JaredTan95/grpc-demo)

