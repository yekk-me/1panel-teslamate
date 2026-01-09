# Mytesla Self Host (Traefik HTTPS)

Mytesla Self Host 是一个功能强大的特斯拉车辆数据自托管记录器，集成了 TeslaMate、Grafana 数据可视化、TeslaMateAPI 和 Dash 仪表板，支持通过 Traefik + Let's Encrypt 提供 HTTPS 访问。

## 功能特性

* 📊 **数据记录**: 自动记录驾驶、充电、软件更新等数据
* 📈 **数据可视化**: 内置 Grafana 仪表板，提供丰富的数据图表
* 🎛️ **Dash 仪表板**: 现代化的 Web 仪表板界面
* 🔒 **隐私保护**: 数据完全存储在您的服务器上
* 🚗 **多车辆支持**: 支持同时记录多辆特斯拉车辆
* 📱 **Web 界面**: 提供友好的 Web 管理界面
* 🌐 **API 接口**: 提供 TeslaMateAPI RESTful 接口
* 🔐 **HTTPS 加密**: 自动申请和续期 Let's Encrypt SSL 证书

## 内置组件

* TeslaMate (特斯拉数据收集器)
* PostgreSQL 数据库（内置，自动部署）
* MQTT 消息队列（内置，自动部署）
* Grafana 数据可视化（内置，自动部署）
* TeslaMateAPI RESTful 接口（内置，自动部署）
* Dash 仪表板（内置，自动部署）
* Traefik 反向代理 + Let's Encrypt（内置，自动部署）

## 首次配置

### 1. 准备域名和 DNS

在安装应用之前，您需要准备域名配置：

1. **准备一个域名**
   - 购买或使用已有的域名
   - 确保您可以管理该域名的 DNS 记录

2. **配置 DNS 解析**
   - 将域名（例如 `mytesla.example.com`）的 A 记录指向您服务器的公网 IP
   - 等待 DNS 生效（通常几分钟到几小时）

3. **确保端口可访问**
   - 服务器需要开放 80 端口（HTTP，用于 Let's Encrypt 验证）
   - 服务器需要开放 443 端口（HTTPS）
   - 如需修改端口，可在安装时配置 `PANEL_APP_PORT_HTTP` 和 `PANEL_APP_PORT_HTTPS`

### 2. 安装应用

在 1Panel 应用商店中找到 Mytesla Self Host (Traefik)，点击安装并填写以下必要配置：

#### 域名和证书配置

* **Domain**: 您配置的域名 (例如: `mytesla.example.com`)
* **Let's Encrypt Email**: 用于接收证书通知的邮箱

#### Basic Auth 配置

* **Basic Auth Username**: 访问 TeslaMate 和 Dash 的用户名
* **Basic Auth Password**: 访问 TeslaMate 和 Dash 的密码

#### 其他配置

* 数据库配置：系统会自动生成安全的随机密码
* Grafana 管理员账号：设置 Grafana 的登录密码
* 高德地图 Key：可选，用于 Dash 地图显示

### 3. 配置 TeslaMate

安装完成后：

1. **通过域名访问**: 访问 `https://您的域名/teslamate` 进入 TeslaMate 管理界面
2. 输入 Basic Auth 用户名和密码
3. 按照界面提示进行特斯拉账号授权
4. 添加您的特斯拉车辆

### 4. 访问 Dash 仪表板

1. **通过域名访问**: 访问 `https://您的域名`
2. 输入 Basic Auth 用户名和密码
3. 查看现代化的仪表板界面

### 5. 访问 Grafana 仪表板

1. **通过域名访问**: 访问 `https://您的域名/grafana`
2. 使用安装时设置的管理员账号登录
3. 浏览预配置的仪表板查看车辆数据

## 访问地址总览

安装完成后，请记录以下访问地址：

### 🌐 通过域名访问 (推荐)

* **Dash 仪表板**: `https://您的域名` (需要 Basic Auth)
* **TeslaMate 主界面**: `https://您的域名/teslamate` (需要 Basic Auth)
* **Grafana 仪表板**: `https://您的域名/grafana`

## 数据安全

* ✅ 所有数据都存储在您的本地服务器上
* ✅ 支持数据加密存储
* ✅ TeslaMate 和 Dash 支持 Basic Auth 认证保护
* ✅ Traefik 自动管理 Let's Encrypt SSL 证书
* ✅ 建议定期备份 PostgreSQL 数据库

## 故障排除

### 常见问题

1. **SSL 证书申请失败**
   - 确认 DNS 已正确解析到服务器 IP
   - 确认 80 端口可从公网访问（Let's Encrypt 需要验证）
   - 查看 Traefik 日志：`docker logs <容器名>-traefik`
   - 证书申请可能需要等待几分钟

2. **无法通过域名访问服务**
   - 检查 DNS 解析是否生效：`dig 您的域名`
   - 检查防火墙是否开放 80/443 端口
   - 检查 Traefik 服务是否正常运行

3. **Basic Auth 认证失败**
   - 检查用户名和密码是否正确
   - 查看 Auth 服务日志：`docker logs <容器名>-auth`

4. **无法连接特斯拉账号**
   - 检查网络连接
   - 确认特斯拉账号和密码正确
   - 查看 TeslaMate 日志获取详细错误信息

5. **Grafana 无法显示数据**
   - 确认数据库连接正常
   - 检查 TeslaMate 是否成功收集到数据
   - 验证 Grafana 数据源配置

## 更多信息

* [TeslaMate 官方文档](https://docs.teslamate.org/)
* [Grafana 官方文档](https://grafana.com/docs/)
* [Traefik 官方文档](https://doc.traefik.io/traefik/)
* [Let's Encrypt 官方文档](https://letsencrypt.org/docs/)
* [Mytesla.cc 官网](https://mytesla.cc/)

## 注意事项

* 首次启动可能需要几分钟时间初始化数据库和申请 SSL 证书
* 建议在稳定的网络环境下运行
* Let's Encrypt 证书有效期 90 天，Traefik 会自动续期
* 确保服务器时钟准确，否则可能影响证书验证
