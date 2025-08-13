# Mytesla Proxy (FRP Client)

## 简介

Mytesla Proxy 是一个基于 FRP (Fast Reverse Proxy) 的客户端应用，专门用于为 Mytesla 服务提供内网穿透功能。通过这个应用，您可以将本地的 Mytesla 服务安全地暴露到公网。

## 功能特点

* 🚀 支持 HTTP/HTTPS/TCP/UDP 多种代理类型
* 🔧 通过环境变量灵活配置
* 🐳 基于 Docker 容器化部署
* 🔒 安全的内网穿透方案
* 📝 自动生成 frpc.toml 配置文件

## 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| FRP_SERVER_ADDR | frp.moreve.net | FRP 服务器地址 |
| FRP_SERVER_PORT | 7000 | FRP 服务器端口 |
| PROXY_NAME | example | 代理名称（子域名前缀） |
| LOCAL_IP | 127.0.0.1 | 本地服务 IP 地址 |
| LOCAL_PORT | 8080 | 本地服务端口 |
| PROXY_TYPE | http | 代理类型 (http/https/tcp/udp) |

## 配置示例

### HTTP 代理配置

默认配置会生成如下的 frpc.toml：

```toml
# frpc.toml

serverAddr = "frp.moreve.net"
serverPort = 7000

[[proxies]]
name = "example_web_8080"
type = "http"
localIP = "127.0.0.1"
localPort = 8080
subdomain = "example"
```

访问地址： `http://example.moreve.net`

### TCP 代理配置

如果选择 TCP 类型，配置会是：

```toml
# frpc.toml

serverAddr = "frp.moreve.net"
serverPort = 7000

[[proxies]]
name = "example_web_8080"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
```

## 使用说明

1. **安装应用**
   - 在 1Panel 应用商店中找到 "Mytesla Proxy"
   - 点击安装并配置相关参数

2. **配置参数**
   - FRP 服务器地址：输入您的 FRP 服务器地址
   - FRP 服务器端口：默认 7000
   - 代理名称：设置您的子域名前缀（例如：example）
   - 本地 IP：通常保持默认 127.0.0.1
   - 本地端口：您的 Mytesla 服务运行的端口（默认 8080）
   - 代理类型：根据需求选择 HTTP/HTTPS/TCP/UDP

3. **启动服务**
   - 配置完成后，点击确认安装
   - 服务会自动启动并连接到 FRP 服务器

4. **验证连接**
   - 查看容器日志确认连接状态
   - 对于 HTTP/HTTPS 类型，访问 `http://[代理名称].[FRP服务器域名]`

## 注意事项

1. **网络模式**：使用 host 网络模式以访问宿主机服务
2. **安全性**：请确保 FRP 服务器的安全性，避免敏感服务暴露
3. **防火墙**：确保服务器防火墙允许相应端口访问
4. **域名解析**：HTTP/HTTPS 模式需要正确的域名解析

## 故障排除

### 连接失败

* 检查 FRP 服务器地址和端口是否正确
* 确认网络连接正常
* 查看容器日志了解详细错误信息

### 无法访问服务

* 确认本地服务正在运行
* 检查本地 IP 和端口配置是否正确
* 验证代理类型是否匹配服务类型

### 子域名无法访问

* 确认 FRP 服务器支持子域名功能
* 检查域名解析是否正确
* 验证代理名称是否唯一

## 相关链接

* [FRP 官方文档](https://gofrp.org/docs/)
* [FRP GitHub](https://github.com/fatedier/frp)
* [Docker Hub - snowdreamtech/frpc](https://hub.docker.com/r/snowdreamtech/frpc)
