---
keywords:
- 抠腚Coding笔记
- Kubernetes 集群搭建
- Kubernetes 快速搭建
title: "30分钟搭建一个单主 Kubernetes 集群"
subtitle: ""
description:
date: 2020-02-27T20:30:49+08:00
draft: false
toc: true
categories: "kubernetes"
tags: ["kubernetes"]
img: "http://q67bf0oit.bkt.clouddn.com/blog/kubernetesfdfdf.jpeg"
bigimg: [{src: "http://q67bf0oit.bkt.clouddn.com/blog/kubernetesfdfdf.jpeg", desc: "Kubernetes"}]
---


本文安装的 Kubernets 版本为 ***v1.17.2***

## 环境准备

考虑到后面要在上面跑很多东西，所以我我通过虚拟机创建了四台 **CentOS 7.6 版本**的机器，一台做Master节点，其它三台做Worker节点。具体详情如下：

| 主机名  |  IP地址   |
| --- | --- |
|  master-01 |  172.16.60.110   |
|   worker-01  |  172.16.60.121   |
|   worker-02  |  172.16.60.122   |
|   worker-02  |  172.16.60.122   |

需要注意的是，四台机器之间能够相互 Ping 通，且时间同步、主机名不能重复。

- 时间同步可以在每台机器上面执行命令：`ntpdate -u cn.ntp.org.cn`
- 主机名设置可以通过命令，例如设置 **master-01** 主机名：`hostnamectl set-hostname master-01`，你可以通过 `cat /etc/redhat-release` 进行检查。且注意，不要使用 **localhost** 作为主机名。

除此之外，为了避免错误，机器需要满足以下要求：CPU 内核数量不能低于 2，不支持 arm 架构，你可以通过执行 `lscpu` 命令进行核对。

准备工作做完之后，我们就开始正式安装吧～

## 开始安装

- 对 **master-01** 节点机器初始化

```bash
# 只在 master 节点执行
# 替换 172.16.60.110 为 master 节点实际 IP（请使用内网 IP）
# export 命令只在当前 shell 会话中有效，开启新的 shell 窗口后，如果要继续安装过程，请重新执行此处的 export 命令
export MASTER_IP=172.16.60.110
# 替换 k8s.jared-says.cn 为 您想要的 dnsName
export APISERVER_NAME=k8s.jared-says.cn
# Kubernetes 容器组所在的网段，该网段安装完成后，由 kubernetes 创建，事先并不存在于您的物理网络中
export POD_SUBNET=10.100.0.1/16
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts
curl -sSL https://kuboard.cn/install-script/v1.17.x/init_master.sh | sh -s 1.17.2
```

执行完之后，我们来检查一下对 **master-01** 执行的结果：

```bash
# 执行如下命令，等待 3-10 分钟，直到所有的容器组处于 Running 状态
watch kubectl get pod -n kube-system -o wide

# 查看 master 节点初始化结果
kubectl get nodes -o wide
```

- 对 **worker-01** 节点机器初始化

上一步已经将 **master-01** 节点初始化好了，因此，我们要将三台Worker节点都接入到Master节点。那么我们需要获得一个类似密钥的东西，获得接入的权限。怎么获取呢？只需要在上一步的 **master-01** 节点中执行如下命令就好了：

```bash
kubeadm token create --print-join-command
```

你可能会得到如下的结果，注意，这个结果我们马上就会用到哦～

```bash
# kubeadm token create 命令的输出
kubeadm join k8s.jared-says.cn:6443 --token mpfjma.4vjjg8flqihor4vt     --discovery-token-ca-cert-hash sha256:6f7a8e40a810323672de5eee6f4d19aa2dbdb38411845a1bf5dd63485c43d303
```

另外，该 token 的有效时间为 2 个小时，2小时内，您可以使用此 token 初始化任意数量的 worker 节点。

接下里，就**依次！** **依次！** **依次！** 在三台 Worker 节点机器上执行上面得到的命令：

```bash
# 替换 172.16.60.110 为 master 节点的内网 IP
export MASTER_IP=172.16.60.110
# 替换 k8s.jared-says.cn 为初始化 master 节点时所使用的 APISERVER_NAME
export APISERVER_NAME=k8s.jared-says.cn
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts

kubeadm join k8s.jared-says.cn:6443 --token mpfjma.4vjjg8flqihor4vt     --discovery-token-ca-cert-hash sha256:6f7a8e40a810323672de5eee6f4d19aa2dbdb38411845a1bf5dd63485c43d303
```

- 然后我们去 Master 节点上面检查一下是否接入进来了

```bash
kubectl get nodes -o wide
```
![k8s-nodes](http://q67bf0oit.bkt.clouddn.com/blog/k8s-nodes.png)

看到这样的结果呢，其实我们的Kubernetes集群就已经搭建好了，只不过，我们的直观映像是这应该有个操作界面吧，不然我怎么玩呀？

对的，我们就开始来安装Web UI界面吧～

我并没有安装官方的 UI 界面，而是安装了一个社区我觉得还挺不错的一个界面。但是，我还是把官方界面的截图放一下给大家看看，后面我就开始安装我比较喜欢的 *kuboard* 界面了。

官方的UI长这个样子：

![ui-dashboard](http://q67bf0oit.bkt.clouddn.com/blog/ui-dashboard.png)

我选择 **kuboard**：https://kuboard.cn/

首先为了能够让虚拟机里面的Kubernetes 能够被本地电脑访问到，我们需要安装一个叫 **Ingress Controller** 的东西，这是 Kubernetes 流量的入口。在 Master 节点执行这条命令即可安装：

```bash
kubectl apply -f https://kuboard.cn/install-script/v1.17.x/nginx-ingress.yaml
```

如果你不想要了，你可以随时卸载，就是这么任性，这么简单：

```bash
kubectl delete -f https://kuboard.cn/install-script/v1.17.x/nginx-ingress.yaml
```

然后，我们需要在本地电脑（/etc/hosts文件，Windows读者自己去翻翻在哪里该，我不太记得了:-P）上面添加一条DNS解析记录,你可以将域名 *.*.yourdomain.com 解析到 worker 节点任意一个IP，以我的域名为例：

![hosts](http://q67bf0oit.bkt.clouddn.com/blog/hosts.png)

然后我通过本地浏览器访问 **dashboard.k8s.jared-says.cn**，会得到 **404** 界面，这是正常的，因为我们还没部署 UI。安装 Kuboard UI很简单，和官方UI安装方式一样，只需要在Master节点执行如下命令即可：

```bash
kubectl apply -f https://kuboard.cn/install-script/kuboard.yaml
kubectl apply -f https://addons.kuboard.cn/metrics-server/0.3.6/metrics-server.yaml
```

当然，你随时想卸载也可以，依然任性、简单：

```bash
kubectl delete -f https://kuboard.cn/install-script/kuboard.yaml
kubectl delete -f https://addons.kuboard.cn/metrics-server/0.3.6/metrics-server.yaml
```

好了，我们检查一下UI安装情况：

```bash
kubectl get pods -l k8s.eip.work/name=kuboard -n kube-system
```

如果得到如下结果：

![](http://q67bf0oit.bkt.clouddn.com/blog/WX20200227-220632@2x.png)

你就可以通过本地浏览器访问：**http://任意一个Worker节点的IP地址:32567/** 查看界面了。

![](http://q67bf0oit.bkt.clouddn.com/blog/WX20200227-220814@2x.png)

这里需要我们输入TOKEN 认证，在哪里获取呢？

只需要在 Master 节点执行如下命令即可：

```bash
kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep kuboard-user | awk '{print $1}') -o go-template='{{.data.token}}' | base64 -d
```

你会得到这样的结果：

![](http://q67bf0oit.bkt.clouddn.com/blog/WX20200227-221120@2x.png)

复制红框中的 Token 值就好了。之后就可以进入 Kubernetes 管理界面啦～

![](http://q67bf0oit.bkt.clouddn.com/blog/WX20200227-221253@2x.png)

可以开始尽情的折腾了。


###### 参考
- kubernetes 官网：https://kubernetes.io/
- 国内社区很棒的Kubernetes UI：https://kuboard.cn/