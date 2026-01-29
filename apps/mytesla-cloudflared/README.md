# Mytesla Cloudflared

Cloudflare Tunnel 内网穿透接入层，用于为 mytesla-selfhost 提供 HTTPS 访问。

## 使用前提

1. 已安装 `mytesla-selfhost` 应用
2. 拥有 Cloudflare 账号和域名

## 配置步骤

1. 登录 [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. 进入 Networks -> Tunnels
3. 创建新的 Tunnel，获取 Token
4. 配置 Tunnel 的 Public Hostname：
   - Domain: 你的域名
   - Service: `http://localhost:8080`（端口与 mytesla-selfhost 的 HTTP 端口一致）

## 架构说明

```
互联网 -> Cloudflare Edge -> Cloudflare Tunnel -> localhost:8080 -> mytesla-selfhost
```

此应用使用 host 网络模式，直接通过 `localhost` 访问宿主机上运行的 mytesla-selfhost 服务。
