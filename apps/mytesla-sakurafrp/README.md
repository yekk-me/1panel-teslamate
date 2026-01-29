# Mytesla SakuraFrp

Sakura FRP 内网穿透接入层，用于为 mytesla-selfhost 提供外网访问。

## 使用前提

1. 已安装 `mytesla-selfhost` 应用
2. 拥有 SakuraFrp 账号

## 配置步骤

1. 登录 [SakuraFrp 面板](https://www.natfrp.com/)
2. 创建隧道：
   - 隧道类型：HTTP/HTTPS
   - 本地地址：`host.docker.internal`
   - 本地端口：`8080`（与 mytesla-selfhost 的 HTTP 端口一致）
3. 获取访问密钥和远程节点配置

## 架构说明

```
互联网 -> SakuraFrp 节点 -> SakuraFrp Tunnel -> host.docker.internal:8080 -> mytesla-selfhost
```

此应用通过 `host.docker.internal` 连接宿主机上运行的 mytesla-selfhost 服务。
