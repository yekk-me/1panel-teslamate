# Mytesla Self Host

Mytesla Self Host 是一个功能强大的特斯拉车辆数据自托管记录器，集成了 TeslaMate、Grafana 数据可视化、TeslaMateAPI 和 Dash 仪表板。

## 架构说明

从 v2.1.1 开始，我们采用了模块化架构设计：

- **mytesla-selfhost**（本应用）：提供核心 HTTP 服务
- **接入层应用**（按需安装）：提供 HTTPS/内网穿透能力
  - `mytesla-cloudflared`：Cloudflare Tunnel 内网穿透
  - `mytesla-sakurafrp`：Sakura FRP 内网穿透
  - `mytesla-traefik-ssl`：Traefik + Let's Encrypt SSL（需要公网 IP）

## 功能特性

* 📊 **数据记录**: 自动记录驾驶、充电、软件更新等数据
* 📈 **数据可视化**: 内置 Grafana 仪表板，提供丰富的数据图表
* 🎛️ **Dash 仪表板**: 现代化的 Web 仪表板界面
* 🔒 **隐私保护**: 数据完全存储在您的服务器上
* 🚗 **多车辆支持**: 支持同时记录多辆特斯拉车辆
* 📱 **Web 界面**: 提供友好的 Web 管理界面
* 🌐 **API 接口**: 提供 TeslaMateAPI RESTful 接口
* 🔐 **安全访问**: 内置 Cookie 认证保护

## 内置组件

* TeslaMate (特斯拉数据收集器)
* PostgreSQL 数据库
* MQTT 消息队列
* Grafana 数据可视化
* TeslaMateAPI RESTful 接口
* Dash 仪表板
* Traefik 反向代理（仅 HTTP）
* Auth 认证服务

## 使用场景

### 场景 A：仅内网访问

只安装 `mytesla-selfhost`，通过 `http://服务器IP:8080` 访问。

### 场景 B：有公网 IP + 需要 HTTPS

1. 安装 `mytesla-selfhost`（HTTP 端口设为 8080）
2. 安装 `mytesla-traefik-ssl`（自动申请 Let's Encrypt 证书）
3. 通过 `https://你的域名` 访问

### 场景 C：无公网 IP + Cloudflare Tunnel

1. 安装 `mytesla-selfhost`（HTTP 端口设为 8080）
2. 安装 `mytesla-cloudflared`
3. 在 Cloudflare Zero Trust 面板配置 Tunnel
4. 通过 Cloudflare 分配的域名访问

### 场景 D：无公网 IP + Sakura FRP

1. 安装 `mytesla-selfhost`（HTTP 端口设为 8080）
2. 安装 `mytesla-sakurafrp`
3. 在 Sakura FRP 面板配置隧道
4. 通过 Sakura FRP 分配的地址访问

## 首次配置

### 1. 安装应用

在 1Panel 应用商店中找到 Mytesla Self Host，点击安装并填写配置：

* **HTTP 端口**: 服务暴露的端口（默认 8080）
* **Mytesla 用户名/密码**: 访问面板的认证凭据
* **数据库配置**: 系统会自动生成安全的随机密码
* **Grafana 管理员账号**: 设置 Grafana 的登录密码
* **高德地图 Key**: 可选，用于 Dash 地图显示

### 2. 配置 TeslaMate

安装完成后：

1. 访问 `http://服务器IP:8080/teslamate` 进入 TeslaMate 管理界面
2. 输入用户名和密码
3. 按照界面提示进行特斯拉账号授权
4. 添加您的特斯拉车辆

### 3. 访问 Dash 仪表板

1. 访问 `http://服务器IP:8080`
2. 输入用户名和密码
3. 查看现代化的仪表板界面

### 4. 访问 Grafana 仪表板

1. 访问 `http://服务器IP:8080/grafana`
2. 使用安装时设置的管理员账号登录
3. 浏览预配置的仪表板查看车辆数据

## 访问地址总览

| 服务 | 地址 | 说明 |
|------|------|------|
| Dash 仪表板 | `http://IP:端口` | 需要认证 |
| TeslaMate | `http://IP:端口/teslamate` | 需要认证 |
| Grafana | `http://IP:端口/grafana` | 单独的 Grafana 认证 |

## 数据安全

* ✅ 所有数据都存储在您的本地服务器上
* ✅ 支持数据加密存储
* ✅ 内置 Cookie 认证保护
* ✅ 建议定期备份 PostgreSQL 数据库
* ✅ 建议配合接入层应用使用 HTTPS

## 故障排除

### 常见问题

1. **无法访问服务**
   - 检查防火墙是否开放了配置的 HTTP 端口
   - 确认 Docker 容器正常运行

2. **认证失败**
   - 检查用户名和密码是否正确
   - 清除浏览器 Cookie 后重试

3. **无法连接特斯拉账号**
   - 检查网络连接
   - 确认特斯拉账号和密码正确
   - 查看 TeslaMate 日志获取详细错误信息

4. **Grafana 无法显示数据**
   - 确认数据库连接正常
   - 检查 TeslaMate 是否成功收集到数据
   - 验证 Grafana 数据源配置

## 更多信息

* [TeslaMate 官方文档](https://docs.teslamate.org/)
* [Grafana 官方文档](https://grafana.com/docs/)
* [Mytesla.cc 官网](https://mytesla.cc/)

## 注意事项

* 首次启动可能需要几分钟时间初始化数据库
* 建议在稳定的网络环境下运行
* 如需外网访问，请安装对应的接入层应用
