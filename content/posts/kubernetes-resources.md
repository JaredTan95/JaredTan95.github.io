---
keywords:
- 一万小时极客
- Kubernetes Resources
- Kubernetes 资源清单
title: "Kubernetes 资源清单(文章有点长)"
subtitle: "Kubernetes Resources"
description: "Kubernetes 中所有的内容都抽象为资源，资源实例化（被调用、被执行了）之后，叫做对象。"
date: 2020-03-07T21:42:47+08:00
draft: false
toc: true
categories: "kubernetes"
tags: ["kubernetes"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/kubernetesfdfdf.jpeg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/kubernetesfdfdf.jpeg", desc: "Kubernetes"}]
---

## Kubernetes 中的资源

Kubernetes 中所有的内容都抽象为资源，资源实例化（被调用、被执行了）之后，叫做对象。

大致地可以总结为：对象描述了什么容器化应用在运行（以及在哪个 Node 上）；可以被应用使用的资源；关于应用如何表现的策略，比如重启策略、升级策略，以及容错策略；

Kubernetes 对象是 **“目标性记录”**： 一旦创建对象，Kubernetes 系统将持续工作以确保对象存在。通过创建对象，可以有效地告知 Kubernetes 系统，所需要的集群工作负载看起来是什么样子的，这就是 Kubernetes 集群的 期望状态。

与 Kubernetes 对象工作(是否创建、修改，或者删除）： 需要使用 Kubernetes API。当使用 **kubectl** 命令行接口时，比如，CLI 会使用必要的 Kubernetes API 调用，也可以在程序中直接使用 Kubernetes API。

## Kubernetes 中有哪些常用资源对象？

依据资源的主要功能作为分类标准，Kubernetes的API对象大体可分为五个类别：

- 集群级别的资源：Namespace、Node、Role、ClusterRole、RoleBinding、ClusterRoleBinding
- 工作负载类型资源（workload）：
  - Pod: Kubernetes中最小的负载单元
  - ReplicaSet：简称RC，管理Pod的创建，通过标签控制副本数
  - Deployment：控制器，通过控制RC去创建Pod
  - StatefulSet：主要用于有状态服务
  - DaemonSet：在每个节点都运行一个Pod组件
  - Job、CronJob：为了（批）处理、在kubernetes v1.11中被废弃的 ReplicationController
- 服务发现及负载均衡资源（Service Discovery And LoadBalance）：Service、Ingress...
- 配置与存储类型：Volume（存储卷）、CSI（容器存储接口，可以扩展各种各样的第三方存储卷，现在市面上的大多数存储都是支持CSI。）
- 特殊类型的存储卷：ConfigMap（当成配置中心来使用的资源类型）、Secret（保存敏感数据）、DownwardAPI（把外部环境中的信息输出给环境，比如把运行Pod的所在Node的NodeIp传进Pod）
- 元数据(metadata)：HPA、PodTemplate、LimitRange(资源限制)


## 对象资源格式
Kubernetes API 仅接受及响应JSON格式的数据（JSON对象），同时，为了便于使用，它也允许用户提供YAML格式的POST对象，但API Server需要实现自行将其转换为JSON格式后方能提交。API Server接受和返回的所有JSON对象都遵循同一个模式，它们都具有kind和apiVersion字段，用于标识对象所属的资源类型、API群组及相关的版本。

大多数的对象或列表类型的资源提供元数据信息，如名称、隶属的名称空间和标签等；spec则用于定义用户期望的状态，不同的资源类型，其状态的意义也各有不同，例如Pod资源最为核心的功能在于运行容器；而status则记录着活动对象的当前状态信息，它由Kubernetes系统自行维护，对用户来说为只读字段。

获取对象的JSON格式的配置清单可以通过 `kubectl get TYPE/NAME -o yaml` 命令来获取。

```bash
[root@k8s-master ~]# kubectl get pod nginx-67685f79b5-8rjk7 -o yaml    #获取该pod的配置清单
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2019-08-30T07:00:30Z"
  generateName: nginx-67685f79b5-
  labels:
    pod-template-hash: 67685f79b5
    run: nginx
  name: nginx-67685f79b5-8rjk7
  namespace: default
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: nginx-67685f79b5
    uid: 6de479a9-52f6-4581-8e06-884a84dab593
  resourceVersion: "244953"
  selfLink: /api/v1/namespaces/default/pods/nginx-67685f79b5-8rjk7
  uid: 0b6f5a87-4129-4b61-897a-6020270a846e
spec:
  containers:
  - image: nginx:1.12
    imagePullPolicy: IfNotPresent
    name: nginx
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-s8mbf
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: k8s-node1
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-s8mbf
    secret:
      defaultMode: 420
      secretName: default-token-s8mbf
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2019-08-30T07:00:30Z"
```

- 创建资源的方法
  - apiserver 仅接受 JSON 格式的资源定义
  - yaml 格式提供资源配置清单，apiserver 可自动将其转为 json 格式，而后再提交。

- 大部分资源的配置清单由以下5个字段组成：

```bash
# kubectl api-versions  命令可以获取
apiVersion: 指明api资源属于哪个群组和版本，同一个组可以有多个版本 group/version

kind:       资源类别，标记创建的资源类型，k8s主要支持以下资源类别
    Pod、ReplicaSet、Deployment、StatefulSet、DaemonSet、Job、Cronjob

metadata:   用于描述对象的属性信息，主要提供以下字段：
  name:          指定当前对象的名称，其所属的名称空间的同一类型中必须唯一
  namespace:     指定当前对象隶属的名称空间，默认值为default
  labels:        设定用于标识当前对象的标签，键值数据，常被用作挑选条件
  annotations:   非标识型键值数据，用来作为挑选条件，用于labels的补充

spec:       用于描述所期望的对象应该具有的状态（disired state），资源对象中最重要的字段。

status:     用于记录对象在系统上的当前状态（current state），本字段由kubernetes自行维护
```

- kubernetes存在内嵌的格式说明，定义资源配置清单时，可以使用kubectl explain命令进行查看，如查看Pod这个资源的定义：

```bash
[root@k8s-master ~]# kubectl explain pods
KIND:     Pod
VERSION:  v1

DESCRIPTION:
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:
   apiVersion    <string>
     APIVersion defines the versioned schema of this representation of an
     object. Servers should convert recognized schemas to the latest internal
     value, and may reject unrecognized values. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#resources

   kind    <string>
     Kind is a string value representing the REST resource this object
     represents. Servers may infer this from the endpoint the client submits
     requests to. Cannot be updated. In CamelCase. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#types-kinds

   metadata    <Object>
     Standard object's metadata. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata

   spec    <Object>
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

   status    <Object>
     Most recently observed status of the pod. This data may not be up to date.
     Populated by the system. Read-only. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status
```

如果需要了解某**一级**字段表示的对象之下的**二级**对象字段时，只需要指定其**二级**字段的对象名称即可，三级和四级字段对象等的查看方式依次类推。*例如查看Pod资源的Spec对象支持嵌套使用的二级字段*:

```bash
[root@k8s-master ~]# kubectl explain pods.spec
RESOURCE: spec <Object>

DESCRIPTION:
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

     PodSpec is a description of a pod.

FIELDS:
   activeDeadlineSeconds    <integer>
     Optional duration in seconds the pod may be active on the node relative to
     StartTime before the system will actively try to mark it failed and kill
     associated containers. Value must be a positive integer.

   affinity    <Object>
     If specified, the pod's scheduling constraints

   automountServiceAccountToken    <boolean>
     AutomountServiceAccountToken indicates whether a service account token
     should be automatically mounted.
 .....
```

## 配置清单模式创建Pod

```bash
[root@k8s-master ~]# mkdir manfests 
[root@k8s-master ~]# cd manfests/
[root@k8s-master manfests]# vim pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
  - name: busybox
    image: busybox:latest
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 3600"

[root@k8s-master manfests]# kubectl create -f pod-demo.yaml 
pod/pod-demo created
[root@k8s-master manfests]#
[root@k8s-master manfests]# kubectl get pods 
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   0          15s
[root@k8s-master manfests]# kubectl describe pods pod-demo   #查看pod详细信息
[root@k8s-master manfests]# kubectl get pods -o wide 
NAME       READY   STATUS    RESTARTS   AGE    IP            NODE        NOMINATED NODE   READINESS GATES
pod-demo   2/2     Running   0          102s   10.244.1.17   k8s-node1   <none>           <none>
[root@k8s-master manfests]# 
[root@k8s-master manfests]# curl 10.244.1.17
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
[root@k8s-master manfests]# 
[root@k8s-master manfests]# kubectl logs pod-demo myapp   #查看pod-demo下myapp的日志
10.244.0.0 - - [03/Sep/2019:02:32:52 +0000] "GET / HTTP/1.1" 200 65 "-" "curl/7.29.0" "-"
[root@k8s-master manfests]# 
[root@k8s-master manfests]# kubectl exec -it pod-demo -c myapp -- /bin/sh   #进入myapp容器
/ #
```

- Pod资源spec的containers字段解析

```bash
[root@k8s-master ~]# kubectl explain pods.spec.containers
name    <string>    指定容器名称

image    <string>    指定容器所需镜像仓库及镜像名，例如ikubernetes/myapp:v1

imagePullPolicy    <string>  （可取以下三个值Always,Never,IfNotpresent）
    Always：镜像标签为“latest”时，总是去指定的仓库中获取镜像
    Never：禁止去仓库中下载镜像，即仅使用本地镜像
    IfNotpresent：如果本地没有该镜像，则去镜像仓库中下载镜像
    
ports    <[]Object>  值是一个列表，由一到多个端口对象组成。例如：(名称(可后期调用) 端口号 协议 暴露在的地址上) 暴露端口只是提供额外信息的，不能限制系统是否真的暴露
    containerPort  <integer>  指定暴露的容器端口
    name    <string>    当前端口的名称
    hostIP    <string>   主机端口要绑定的主机IP
    hostPort    <integer>   主机端口，它将接收到请求通过NAT转发至containerPort字段指定的端口
    protocol    <string>    端口的协议，默认是TCP

args    <[]string>  传递参数给command 相当于docker中的CMD

command    <[]string>  相当于docker中的ENTRYPOINT
```

- 镜像中的命令和pod中定义的命令关系说明：
  - 如果pod中没有提供command或者args，则使用docker中的CMD和ENTRYPOINT。
  - 如果pod中提供了command但不提供args，则使用提供的command，忽略docker中的Cmd和Entrypoint。
  - 如果pod中只提供了args，则args将作为参数提供给docker中的Entrypoint使用。
  - 如果pod中同时提供了command和args，则docker中的cmd和Entrypoint将会被忽略，pod中的args将最为参数给cmd使用。


## 标签和标签选择器

#### 标签

标签是 Kubernetes 极具特色的功能之一，它能够附加于 Kubernetes 的**任何**资源对象之上。简单来说，标签就是“键值”类型的数据，可以在资源创建时直接指定，也可以随时按需添加到活动对象中。而后即可由标签选择器进行匹配度检查从而完成资源挑选。一个对象可拥有不止一个标签，而同一个标签也可以被添加到至多个资源之上。

> key=value
    key：字母、数字、_、-、.  只能以字母或者数字开头
    value：可以为空，只能以字母或者数字开头及结尾，中间可以使用字母、数字、_、-、.
    在实际环境中，尽量做到见名知意，且尽可能保持简单

```bash
[root@k8s-master ~]# kubectl get pods --show-labels     #查看pod信息时，并显示对象的标签信息
NAME       READY   STATUS    RESTARTS   AGE     LABELS
pod-demo   2/2     Running   5          5h13m   app=myapp,tier=frontend

[root@k8s-master ~]# kubectl get pods -l app   #过滤包含app标签的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   5          5h20m

[root@k8s-master ~]# kubectl get pods -l app,tier    #过滤同时包含app，tier标签的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   5          5h20m

[root@k8s-master ~]# kubectl get pods -L app   #显示有app键的标签信息
NAME       READY   STATUS    RESTARTS   AGE     APP
pod-demo   2/2     Running   5          5h21m   myapp

[root@k8s-master ~]# kubectl get pods -L app,tier    #显示有app和tier键的标签信息
NAME       READY   STATUS    RESTARTS   AGE     APP     TIER
pod-demo   2/2     Running   5          5h21m   myapp   frontend
```

- 给已有的pod添加标签，通过 `kubectl label` 命令
```bash
[root@k8s-master ~]# kubectl label --help 
Usage:
  kubectl label [--overwrite] (-f FILENAME | TYPE NAME) KEY_1=VAL_1 ... KEY_N=VAL_N
[--resource-version=version] [options]


[root@k8s-master ~]# kubectl label pods/pod-demo env=production    #给pod资源pod-demo添加env标签值为production
pod/pod-demo labeled
[root@k8s-master ~]# kubectl get pods --show-labels
NAME       READY   STATUS    RESTARTS   AGE     LABELS
pod-demo   2/2     Running   5          5h32m   app=myapp,env=production,tier=frontend
```
- 修改已有的标签的值
```bash
[root@k8s-master ~]# kubectl label pods/pod-demo env=testing --overwrite   #同上面添加标签一样，只是添加--overwrite参数
pod/pod-demo labeled
[root@k8s-master ~]# 
[root@k8s-master ~]# kubectl get pods --show-labels
NAME       READY   STATUS    RESTARTS   AGE     LABELS
pod-demo   2/2     Running   5          5h39m   app=myapp,env=testing,tier=frontend
```

#### 标签选择器

标签选择器用于选择标签的查询条件或选择标准，kubernetes API目前支持**两个选择器**：基于等值关系以及基于集合关系。例如，env=production和env!=qa是基于等值关系的选择器，而tier in(frontend,backend)则是基于集合关系的选择器。使用标签选择器时还将遵循以下逻辑：

- 1 同时指定的多个选择器之间的逻辑关系为“与”操作
- 2 使用空值的标签选择器意味着每个资源对象都将被选中
- 3 空的标签选择器将无法选出任何资源。

- 等值关系标签选择器：**=**、**==**和**!=**三种，其中前两个意义相同，都表示等值关系；最后一个表示不等关系。

- 集合关系标签选择器：
  - KEY in(VALUE1,VALUE2,...)：指定的健名的值存在于给定的列表中即满足条件
  - KEY notin(VALUE1,VALUE2,...)：指定的键名的值不存在与给定的列表中即满足条件
  - KEY：所有存在此健名标签的资源。
  - !KEY：所有不存在此健名标签的资源。

- 1 等值关系示例：

```bash
[root@k8s-master ~]# kubectl get pods -l app=myapp    #过滤标签键为app值为myapp的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   6          6h11m

[root@k8s-master ~]# kubectl get pods -l app=myapp,env=testing    #过滤标签键为app值为myqpp，并且标签键为env值为testing的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   6          6h11m

[root@k8s-master ~]# kubectl get pods -l app!=my    #过滤标签键为app值不为my的所有pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   6          6h17m
```

- 2 集合关系示例：
```bash
[root@k8s-master ~]# kubectl get pods -l "app in (myapp)"    #过滤键为app值有myapp的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   6          6h51m

[root@k8s-master ~]# kubectl get pods -l "app notin (my)"    #过滤键为app值没有my的pod
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   6          6h59m
```

处此之外，kubernetes 的诸多资源对象必须以标签选择器的方式关联到pod资源对象，例如Service、Deployment和ReplicaSet类型的资源等，它们在spec字段中嵌套使用嵌套的“selector”字段，通过“matchlabels”来指定标签选择器，有的甚至还支持使用“matchExpressions”构建复杂的标签选择器机制。
    - matchLabels：通过直接给定键值对来指定标签选择器
    - matchExpressions：基于表达式指定的标签选择器列表，每个选择器都形如“{key:KEY_NAME, operator:OPERATOR, values:[VALUE1,VALUE2,...]}”

#### 节点选择器

pod节点选择器是**标签及标签选择器**的一种应用，它能够让pod对象基于集群中工作节点的标签来挑选倾向运行的目标节点。

```bash
#在定义pod资源清单时，可以通过nodeName来指定pod运行的节点，或者通过nodeSelector来挑选倾向的节点
[root@k8s-master ~]# kubectl explain pods.spec
   nodeName    <string>
     NodeName is a request to schedule this pod onto a specific node. If it is
     non-empty, the scheduler simply schedules this pod onto that node, assuming
     that it fits resource requirements.

   nodeSelector    <map[string]string>
     NodeSelector is a selector which must be true for the pod to fit on a node.
     Selector which must match a node's labels for the pod to be scheduled on
     that node. More info:
     https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
```

- 查看节点默认的标签

```bash
[root@k8s-master ~]# kubectl get nodes --show-labels
NAME         STATUS   ROLES    AGE    VERSION   LABELS
k8s-master   Ready    master   6d2h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-master,kubernetes.io/os=linux,node-role.kubernetes.io/master=
k8s-node1    Ready    <none>   6d1h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-node1,kubernetes.io/os=linux
k8s-node2    Ready    <none>   6d1h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-node2,kubernetes.io/os=linux
```

- 给节点添加标签

```bash
[root@k8s-master ~]# kubectl label nodes/k8s-node1 disktype=ssd
node/k8s-node1 labeled
[root@k8s-master ~]# kubectl get nodes --show-labels
NAME         STATUS   ROLES    AGE    VERSION   LABELS
k8s-master   Ready    master   6d2h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-master,kubernetes.io/os=linux,node-role.kubernetes.io/master=
k8s-node1    Ready    <none>   6d2h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,disktype=ssd,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-node1,kubernetes.io/os=linux
k8s-node2    Ready    <none>   6d2h   v1.15.2   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=k8s-node2,kubernetes.io/os=linux
```

- 修改yaml文件，添加节点选择器nodeSelector，然后重新创建pod

```bash
[root@k8s-master ~]# vim manfests/pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
  - name: busybox
    image: busybox:latest
    command:
    - "/bin/sh"
    - "-c"
    - "sleep 3600"
  nodeSelector: # 通过nodeSelector来挑选倾向的节点
    disktype: ssd
    
[root@k8s-master ~]# kubectl delete -f manfests/pod-demo.yaml    #删除上面创建的pod资源
pod "pod-demo" deleted
[root@k8s-master ~]# kubectl create -f manfests/pod-demo.yaml     #重新创建pod-demo资源
pod/pod-demo created
[root@k8s-master ~]# kubectl get pods -o wide     #查看pod，可以看到分配到了k8s-node1节点（也就是上面打上disktype标签的节点）
NAME       READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
pod-demo   2/2     Running   0          16s   10.244.1.19   k8s-node1   <none>           <none>

[root@k8s-master ~]# kubectl describe pods pod-demo
......
Events:
  Type    Reason     Age   From                Message
  ----    ------     ----  ----                -------
  Normal  Scheduled  58s   default-scheduler   Successfully assigned default/pod-demo to k8s-node1
......
```

## 资源注解

除了标签（label）之外，Pod与其他各种资源还能使用资源注解（annotation）。与标签类似，注解也是“键值”类型的数据，不过它不能用于标签及挑选Kubernetes对象，**仅可用于资源提供“元数据”信息**。另外，注解中的元数据不受字符数量的限制，它可大可小，可以为结构化或非结构化形式，也支持使用在标签中禁止使用的其他字符。

