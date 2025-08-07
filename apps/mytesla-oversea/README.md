# Mytesla Oversea

Mytesla Oversea 是一个功能强大的特斯拉车辆数据自托管记录器，集成了 TeslaMate、Grafana 数据可视化和 TeslaMateAPI， 适合有海外服务器公网IP的朋友使用。

## 功能特性

* 📊 **数据记录**: 自动记录驾驶、充电、软件更新等数据
* 📈 **数据可视化**: 内置 Grafana 仪表板，提供丰富的数据图表
* 🔒 **隐私保护**: 数据完全存储在您的服务器上
* 🚗 **多车辆支持**: 支持同时记录多辆特斯拉车辆
* 📱 **Web 界面**: 提供友好的 Web 管理界面
* 🌐 **API 接口**: 提供 TeslaMateAPI RESTful 接口
* 🔐 **安全访问**: 支持 Basic Auth 认证

## 安装要求

### 内置组件

* TeslaMate (特斯拉数据收集器)
* PostgreSQL 数据库（内置，自动部署）
* MQTT 消息队列（内置，自动部署）
* Grafana 数据可视化（内置，自动部署）
* TeslaMateAPI RESTful 接口（内置，自动部署）
* Traefik 反向代理（内置，自动部署）

### 端口说明

* **Traefik HTTP**: 默认端口 80，统一处理所有 HTTP 服务

### 安装应用

在 1Panel 应用商店中找到 Mytesla，点击安装并填写以下必要配置：

#### DOMAIN 配置

* **Domain**: 您配置的域名 (例如: `mytesla.example.com`)

#### LETSENCRYPT_EMAIL 配置

* **Let's Encrypt Email**: 用于 SSL 证书的邮箱

#### Basic Auth 配置

* **Basic Auth Username**: 访问 TeslaMate 的用户名
* **Basic Auth Password**: 访问 TeslaMate 的密码

#### API 安全配置

* **API Token**: 系统会自动生成，用于 TeslaMateAPI 安全认证

#### 其他配置

* 数据库配置：系统会自动生成安全的随机密码
* Grafana 管理员账号：设置 Grafana 的登录密码

### 3. 配置 TeslaMate

安装完成后：

1. **通过域名访问**: 访问 `https://您的域名` 进入 TeslaMate 管理界面
2. 输入 Basic Auth 用户名和密码
3. 按照界面提示进行特斯拉账号授权
4. 添加您的特斯拉车辆

### 4. 访问 Grafana 仪表板

1. **通过域名访问**: 访问 `https://您的域名/grafana`
2. 使用安装时设置的管理员账号登录
3. 浏览预配置的仪表板查看车辆数据

## 访问地址总览

安装完成后，请记录以下访问地址，这些信息在配置 Mytesla.cc 时会用到：

### 🌐 通过域名访问 (推荐)

* **TeslaMate 主界面**: `https://您的域名` (需要 Basic Auth)
* **Grafana 仪表板**: `https://您的域名/grafana`
* **API 接口**: `https://您的域名/api`
* **API 测试**: `https://您的域名/api/ping`

### 🏠 本地网络访问

* **所有服务**: `http://服务器IP:80` (通过 Traefik 统一访问)

## 在 Mytesla.cc 中配置

完成部署后，您可以在 [Mytesla.cc](https://mytesla.cc) 中配置远程访问：

1. 访问 [https://mytesla.cc](https://mytesla.cc)
2. 进入 Settings → TeslaMate 配置
3. 填写以下信息：
   - **API 地址**: `https://您的域名`

   - **API Token**: 安装时生成的 API Token (在应用详情中可查看)
4. 点击测试连接验证配置
5. 配置成功后即可在 Mytesla.cc 中查看和管理您的特斯拉数据

## 百度地图配置（可选）

### 🗺️ 获取更精准的位置信息

Mytesla 支持配置百度地图 API，以获得更精准的车辆位置信息：

* **默认精度**: 只能获取到街道级别的位置信息
* **配置后精度**: 可精确到小区、商城、停车场等具体位置

### 配置步骤

1. **申请百度地图 API 密钥**
   - 访问 [百度地图开放平台个人认证页面](https://lbsyun.baidu.com/apiconsole/userflow/authpersonal)
   - 完成个人认证后，创建应用：
     - **应用类型**: 选择「服务端」
     - **启动服务**: 建议全部勾选（包括定位服务、地址解析、逆地址解析等）
     - **请求校验方式**: 选择「SN 校验方式」
   - 创建成功后，获取 AK (Access Key) 和 SK (Secret Key)

2. **在应用配置中填入密钥**
   - **百度地图 AK**: 填入您申请的 Access Key
   - **百度地图 SK**: 填入您申请的 Secret Key

3. **注意事项**
   - 这两个参数为可选配置，不填写不影响基础功能使用
   - 配置后支持随时修改
   - 使用 SN 校验方式可以提供更高的安全性
   - 请妥善保管您的 SK，避免泄露

## 数据安全

* ✅ 所有数据都存储在您的本地服务器上
* ✅ 支持数据加密存储
* ✅ API 接口使用 Token 进行安全认证
* ✅ TeslaMate 支持 Basic Auth 认证保护
* ✅ Cloudflare Tunnel 提供安全的内网穿透
* ✅ 建议定期备份 PostgreSQL 数据库

## 故障排除

### 常见问题

1. **Basic Auth 认证失败**
   - 检查用户名和密码是否正确
   - 确认 .htpasswd 文件生成成功
   - 查看 Traefik 日志获取详细错误信息

2. **无法连接特斯拉账号**
   - 检查网络连接
   - 确认特斯拉账号和密码正确
   - 查看 TeslaMate 日志获取详细错误信息

3. **Grafana 无法显示数据**
   - 确认数据库连接正常
   - 检查 TeslaMate 是否成功收集到数据
   - 验证 Grafana 数据源配置

4. **API 接口无法访问**
   - 检查 TeslaMateAPI 服务状态
   - 验证 API Token 配置正确
   - 测试 API 连通性：访问 `/api/ping` 端点

5. **服务启动失败**
   - 检查端口是否被占用
   - 确认数据库服务正常运行
   - 查看容器日志排查具体问题

### 日志查看

```bash
# 查看所有服务状态
docker ps

# 查看特定服务日志
docker logs mytesla                    # TeslaMate
docker logs mytesla-grafana           # Grafana
docker logs mytesla-teslamateapi      # TeslaMateAPI
docker logs mytesla-traefik           # Traefik
```

## 更多信息

* [TeslaMate 官方文档](https://docs.teslamate.org/)
* [Grafana 官方文档](https://grafana.com/docs/)
* [Mytesla.cc 官网](https://mytesla.cc/)

## 注意事项

* 首次启动可能需要几分钟时间初始化数据库
* 建议在稳定的网络环境下运行
* 妥善保管 API Token
