# Mytesla 应用使用手册

## 目录

1. [系统简介](#系统简介)
2. [系统架构](#系统架构)
3. [初始安装与配置](#初始安装与配置)
4. [密码修改指南](#密码修改指南)
5. [应用升级指南](#应用升级指南)
6. [故障排除与重启](#故障排除与重启)
7. [常见问题解答](#常见问题解答)

---

## 系统简介

Mytesla 是一个功能强大的特斯拉车辆数据自托管记录器，专为 1Panel 平台设计。它能够自动记录您的特斯拉车辆数据，并提供美观的数据可视化界面，让您完全掌控自己的车辆数据。

### 主要特点

- 🔒 **数据隐私**: 所有数据存储在您自己的服务器上，完全由您控制
- 📊 **实时监控**: 实时记录车辆状态、驾驶数据、充电信息等
- 📈 **数据可视化**: 内置专业的 Grafana 仪表板，直观展示车辆数据
- 🌐 **远程访问**: 支持通过 Cloudflare Tunnel 安全远程访问
- 📱 **多端支持**: 支持通过 Web 端、Mytesla.cc 小程序等多种方式访问

---

## 系统架构

Mytesla 应用采用多层架构设计，包含以下核心组件：

### 系统组件说明

#### 1. **前端访问层**
- **Traefik 反向代理**: 统一入口，处理所有 HTTP 请求
- **Cloudflare Tunnel**: 提供安全的内网穿透服务
- **Basic Auth**: 基础认证保护，确保访问安全

#### 2. **核心服务层**
- **TeslaMate**: 特斯拉数据收集核心服务
- **TeslaMateAPI**: RESTful API 接口服务
- **Grafana**: 数据可视化平台

#### 3. **数据存储层**
- **PostgreSQL**: 主数据库，存储所有车辆数据
- **MQTT (Mosquitto)**: 消息队列，实时数据传输

### 访问端点

系统提供多个访问端点，适应不同的使用场景：

![系统架构图](./images/system-architecture.png)
*[预留图片位置：系统架构示意图]*

1. **Web 管理端** (`https://您的域名`)
   - TeslaMate 主界面
   - 车辆配置管理
   - 数据记录设置

2. **数据可视化端** (`https://您的域名/grafana`)
   - Grafana 仪表板
   - 数据图表展示
   - 自定义报表

3. **API 接口端** (`https://您的域名/api`)
   - RESTful API
   - 供第三方应用调用
   - 支持 Mytesla.cc 小程序

4. **本地访问端** (`http://服务器IP:80`)
   - 局域网内直接访问
   - 无需外网连接

---

## 初始安装与配置

### 安装前准备

在 1Panel 中安装 Mytesla 应用前，您需要准备以下信息：

#### 1. Cloudflare 账号准备

1. 访问 [Cloudflare 官网](https://cloudflare.com/) 注册账号
2. 添加您的域名到 Cloudflare

![Cloudflare 注册](./images/cloudflare-register.png)
*[预留图片位置：Cloudflare 注册页面]*

#### 2. 创建 Cloudflare Tunnel

1. 登录 [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. 导航到 `网络` → `隧道`
3. 点击 `创建隧道`

![创建隧道](./images/create-tunnel.png)
*[预留图片位置：Cloudflare 创建隧道界面]*

4. 输入隧道名称（例如：mytesla-tunnel）
5. 复制生成的 Tunnel Token

![复制 Token](./images/copy-token.png)
*[预留图片位置：Token 复制界面]*

#### 3. 配置公共主机名

1. 进入创建的隧道设置
2. 点击 `公共主机名` → `添加公共主机名`
3. 配置域名信息：
   - 子域：`mytesla`（或您喜欢的名称）
   - 域：选择您的域名
   - 服务类型：`HTTP`
   - URL：`http://traefik:80`

![配置主机名](./images/hostname-config.png)
*[预留图片位置：主机名配置界面]*

### 在 1Panel 中安装

1. 打开 1Panel 管理面板
2. 进入 `应用商店`
3. 搜索 `Mytesla`
4. 点击 `安装`

![1Panel 应用商店](./images/1panel-appstore.png)
*[预留图片位置：1Panel 应用商店界面]*

### 配置参数说明

安装时需要填写以下参数：

![安装配置](./images/install-config.png)
*[预留图片位置：安装配置界面]*

#### 必填参数

1. **Cloudflare Tunnel Token**
   - 从 Cloudflare 获取的隧道令牌
   - 格式：一长串字符

2. **域名 (Domain)**
   - 您配置的完整域名
   - 例如：`mytesla.example.com`

3. **Basic Auth 用户名**
   - 用于保护 TeslaMate 访问
   - 建议使用复杂用户名

4. **Basic Auth 密码**
   - 访问 TeslaMate 的密码
   - 建议使用强密码

5. **Grafana 管理员密码**
   - Grafana 的 admin 账户密码
   - 用于登录数据可视化界面

#### 可选参数

1. **百度地图 AK/SK**
   - 用于获取更精准的位置信息
   - 可以后续在应用中配置

### 安装后配置

1. **配置特斯拉账号**

   访问 `https://您的域名`，输入 Basic Auth 认证后：

   ![TeslaMate 登录](./images/teslamate-login.png)
   *[预留图片位置：TeslaMate 登录界面]*

   - 点击 `Sign in`
   - 选择登录方式
   - 授权特斯拉账号

2. **添加车辆**

   ![添加车辆](./images/add-vehicle.png)
   *[预留图片位置：添加车辆界面]*

   - 输入车辆名称
   - 配置数据记录选项
   - 保存设置

---

## 密码修改指南

系统中有多个密码需要管理，以下是各密码的修改方法：

### 1. Basic Auth 密码修改

Basic Auth 用于保护 TeslaMate 主界面访问。

**修改步骤：**

1. 进入 1Panel → 应用 → 已安装
2. 找到 Mytesla 应用，点击 `设置`

![应用设置](./images/app-settings.png)
*[预留图片位置：应用设置入口]*

3. 在参数配置中修改：
   - `Basic Auth 用户名`
   - `Basic Auth 密码`

![修改 Basic Auth](./images/modify-basic-auth.png)
*[预留图片位置：Basic Auth 修改界面]*

4. 点击 `保存` 并 `重建应用`

### 2. Grafana 管理员密码修改

**方法一：通过 1Panel 修改**

1. 在应用参数中修改 `Grafana 管理员密码`
2. 保存并重建应用

**方法二：通过 Grafana 界面修改**

1. 访问 `https://您的域名/grafana`
2. 使用当前密码登录
3. 点击左侧菜单 → 用户头像 → `Change Password`

![Grafana 修改密码](./images/grafana-change-password.png)
*[预留图片位置：Grafana 密码修改界面]*

### 3. API Token 重置

API Token 用于第三方应用（如 Mytesla.cc）访问。

1. 在 1Panel 应用设置中查看当前 Token
2. 如需重置，修改 `API Token` 参数
3. 保存并重建应用
4. 更新所有使用该 Token 的第三方应用配置

![API Token 管理](./images/api-token-management.png)
*[预留图片位置：API Token 管理界面]*

### 4. 数据库密码修改

⚠️ **注意：修改数据库密码需要谨慎操作**

1. 在应用参数中修改数据库相关密码
2. 确保所有密码字段同步修改
3. 重建应用使配置生效

---

## 应用升级指南

### 自动升级

1Panel 支持应用的自动升级功能：

1. 进入 `应用` → `已安装`
2. 找到 Mytesla 应用
3. 如有新版本，会显示 `升级` 按钮

![应用升级](./images/app-upgrade.png)
*[预留图片位置：应用升级提示]*

4. 点击 `升级` → `确认升级`

### 升级前准备

1. **备份数据**
   - 进入应用详情
   - 点击 `备份` 创建备份

![数据备份](./images/data-backup.png)
*[预留图片位置：数据备份界面]*

2. **记录配置**
   - 截图保存当前配置参数
   - 特别是各类 Token 和密码

### 升级后检查

1. 访问各端点确认服务正常
2. 检查数据是否完整
3. 验证 API 连接是否正常

---

## 故障排除与重启

### 服务状态检查

1. **通过 1Panel 查看**

   进入应用详情，查看各容器状态：

![容器状态](./images/container-status.png)
*[预留图片位置：容器状态界面]*

2. **查看服务日志**

   点击容器名称 → `日志` 查看详细信息：

![查看日志](./images/view-logs.png)
*[预留图片位置：日志查看界面]*

### 常见问题处理

#### 1. 无法访问域名

**检查步骤：**

1. 检查 Cloudflare Tunnel 状态
   - 查看 `cloudflared` 容器日志
   - 确认 Token 配置正确

![Cloudflare 日志](./images/cloudflare-logs.png)
*[预留图片位置：Cloudflare 日志界面]*

2. 验证域名解析
   - 在 Cloudflare 面板检查隧道状态
   - 确认公共主机名配置正确

#### 2. 数据不更新

**解决方法：**

1. 重启 TeslaMate 服务
   - 在容器列表找到 `mytesla` 容器
   - 点击 `重启`

![重启服务](./images/restart-service.png)
*[预留图片位置：重启服务界面]*

2. 检查特斯拉账号连接
   - 访问 TeslaMate 界面
   - 查看账号状态

#### 3. Grafana 无法显示数据

1. 检查数据库连接
2. 重启 Grafana 服务
3. 验证数据源配置

### 应用重建

当遇到严重问题时，可以尝试重建应用：

1. 进入应用设置
2. 点击 `重建`
3. 等待重建完成

![应用重建](./images/app-rebuild.png)
*[预留图片位置：应用重建界面]*

⚠️ **注意：重建不会丢失数据，但建议先备份**

### 完全重启

如需完全重启所有服务：

1. 在 1Panel 中停止应用
2. 等待所有容器停止
3. 启动应用

![停止和启动](./images/stop-and-start.png)
*[预留图片位置：停止和启动界面]*

---

## 常见问题解答

### Q1: 为什么无法连接特斯拉账号？

**A:** 可能的原因：
- 网络连接问题
- 特斯拉服务器维护
- 账号密码错误
- 需要进行二次验证

**解决方法：**
1. 检查服务器网络连接
2. 尝试使用 Token 方式登录
3. 查看 TeslaMate 日志获取详细错误

### Q2: 如何配置百度地图获取精准位置？

**A:** 步骤如下：
1. 访问[百度地图开放平台](https://lbsyun.baidu.com/)
2. 完成个人认证
3. 创建服务端应用
4. 获取 AK 和 SK
5. 在应用参数中配置

![百度地图配置](./images/baidu-map-config.png)
*[预留图片位置：百度地图配置界面]*

### Q3: 数据会占用多少存储空间？

**A:** 存储占用取决于：
- 车辆数量
- 使用频率
- 数据保留时长

一般情况下：
- 单车每月约 100-500MB
- 建议预留 10GB+ 空间

### Q4: 如何在 Mytesla.cc 小程序中使用？

**A:** 配置步骤：
1. 获取 API 地址：`https://您的域名`
2. 获取 API Token（在应用参数中查看）
3. 在小程序设置中填入
4. 测试连接

![小程序配置](./images/miniapp-config.png)
*[预留图片位置：小程序配置界面]*

### Q5: 如何自定义 Grafana 仪表板？

**A:** 
1. 登录 Grafana
2. 点击 `+` → `Create Dashboard`
3. 添加面板和查询
4. 保存仪表板

### Q6: 备份和恢复数据？

**A:** 
- **备份**：使用 1Panel 的备份功能
- **恢复**：在备份列表中选择恢复
- **建议**：定期自动备份

---

## 技术支持

如遇到本手册未涵盖的问题，可通过以下方式获取帮助：

1. **官方文档**
   - [TeslaMate 文档](https://docs.teslamate.org/)
   - [Mytesla.cc 帮助](https://mytesla.cc/help)

2. **社区支持**
   - 1Panel 社区论坛
   - Mytesla 用户群组

3. **问题反馈**
   - 在应用页面提交反馈
   - 附上详细的错误日志

---

*本手册版本：v1.0*  
*更新日期：2024年*