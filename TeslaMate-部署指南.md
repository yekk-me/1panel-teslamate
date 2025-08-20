# TeslaMate 安全部署指南

## 概述

TeslaMate 是一个功能强大的 Tesla 车辆数据记录和分析平台。本指南将帮助您在腾讯云服务器上安全部署 TeslaMate，包括域名购买、服务器配置、SSL 证书配置等完整流程。

## 📋 准备工作

### 1. 购买腾讯云服务器

推荐购买腾讯云新加坡轻量应用服务器：
- **配置**: 1核2GB，99元/年
- **地区**: 新加坡（海外节点，访问 Tesla API 更稳定）
- **购买链接**: [腾讯云新春活动](https://cloud.tencent.com/act/pro/warmup202506)

**服务器规格建议**:
- CPU: 1核心以上
- 内存: 2GB 以上
- 存储: 40GB 以上
- 带宽: 1Mbps 以上

### 2. 购买域名

在腾讯云购买域名：
1. 进入腾讯云控制台
2. 选择"域名注册"
3. 搜索并购买一个便宜的域名（如 .top、.xyz 等后缀）
4. 完成实名认证

### 3. 配置 DNS 解析

#### 3.1 添加 A 记录
在腾讯云 DNS 解析控制台：

1. **主机记录**: `teslamate`（或您喜欢的子域名）
2. **记录类型**: `A`
3. **记录值**: 您的服务器公网 IP
4. **TTL**: `600`

#### 3.2 添加 CNAME 记录（可选）
如果需要 www 访问：

1. **主机记录**: `www`
2. **记录类型**: `CNAME`
3. **记录值**: `teslamate.yourdomain.com`
4. **TTL**: `600`

> 📝 **注意**: DNS 解析生效需要 10-30 分钟，请耐心等待

## 🚀 一键部署脚本

我们提供了一个交互式安装脚本，可以自动完成所有配置：

```bash
bash <(curl -sSL https://raw.githubusercontent.com/your-repo/teslamate-deploy/main/install.sh)
```

### 脚本功能特性

- ✅ 自动安装 Docker 和 Docker Compose
- ✅ 交互式配置环境变量
- ✅ 自动生成安全密码
- ✅ 配置 SSL 证书（Let's Encrypt）
- ✅ 设置防火墙规则
- ✅ 自动启动服务

## 📋 手动部署步骤

如果您希望手动部署，请按照以下步骤：

### 1. 连接服务器

```bash
ssh root@your-server-ip
```

### 2. 更新系统

```bash
apt update && apt upgrade -y
```

### 3. 安装 Docker

```bash
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
```

### 4. 创建项目目录

```bash
mkdir -p /opt/teslamate
cd /opt/teslamate
```

### 5. 创建 Docker Compose 配置

创建 `docker-compose.yml` 文件（使用我们的安装脚本会自动生成）。

### 6. 配置环境变量

创建 `.env` 文件并配置必要的环境变量。

### 7. 启动服务

```bash
docker-compose up -d
```

## 🔐 安全配置

### 1. 防火墙设置

```bash
# 安装 UFW
apt install ufw -y

# 允许 SSH
ufw allow 22

# 允许 HTTP 和 HTTPS
ufw allow 80
ufw allow 443

# 启用防火墙
ufw --force enable
```

### 2. SSL 证书

使用 Let's Encrypt 自动配置 SSL 证书，确保数据传输安全。

### 3. 数据库安全

- 自动生成强密码
- 限制数据库访问权限
- 定期备份数据

## 📊 服务监控

### 1. 检查服务状态

```bash
docker-compose ps
```

### 2. 查看日志

```bash
docker-compose logs -f teslamate
```

### 3. 重启服务

```bash
docker-compose restart
```

## 🔧 故障排除

### 常见问题

1. **无法访问网站**
   - 检查域名解析是否生效
   - 确认防火墙端口开放
   - 检查 Docker 服务状态

2. **SSL 证书问题**
   - 确认域名解析正确
   - 检查 80 端口是否开放
   - 重新申请证书

3. **Tesla API 连接问题**
   - 检查网络连接
   - 确认 Tesla 账号信息正确
   - 查看应用日志

## 📱 MyTesla 应用推荐

在成功部署 TeslaMate 后，强烈推荐您使用 **MyTesla** 移动应用：

### MyTesla 特色功能

🚗 **实时车辆监控**
- 电池状态实时显示
- 充电进度跟踪
- 位置信息监控

📊 **数据分析**
- 详细的行驶数据分析
- 能耗统计报告
- 充电效率分析

🔔 **智能提醒**
- 充电完成通知
- 异常状态警报
- 维护提醒

🌍 **多平台支持**
- iOS 和 Android 原生应用
- 网页版本
- 完美适配 TeslaMate 数据

### 下载 MyTesla

- **iOS**: App Store 搜索 "MyTesla"
- **Android**: Google Play 或应用商店搜索 "MyTesla"
- **网页版**: 通过您的 TeslaMate 域名访问

## 💡 使用建议

1. **定期备份**: 建议每周备份一次数据库
2. **监控资源**: 关注服务器 CPU 和内存使用情况
3. **更新维护**: 定期更新 TeslaMate 到最新版本
4. **安全审计**: 定期检查访问日志和安全设置

## 📞 技术支持

如果在部署过程中遇到问题，可以：

1. 查看 TeslaMate 官方文档
2. 访问 GitHub Issues
3. 加入社区讨论群

---

**祝您使用愉快！🎉**

通过本指南，您将拥有一个安全、稳定的 TeslaMate 部署环境，配合 MyTesla 应用，让您的 Tesla 使用体验更上一层楼！