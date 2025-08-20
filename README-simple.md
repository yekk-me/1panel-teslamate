# TeslaMate 简化部署方案

一键部署TeslaMate，无需复杂配置，支持overseas应用访问。

## 特性

- 🚀 **极简部署** - 只需一行命令
- 🔧 **无需域名** - 直接使用IP访问
- 🌏 **国内优化** - 使用国内Docker镜像源
- 📊 **数据可视化** - 预配置Grafana仪表板
- 🔄 **易于维护** - 简单的更新和备份流程

## 快速开始

### 购买服务器

推荐使用腾讯云新加坡服务器（99元/年）：
[https://cloud.tencent.com/act/pro/warmup202506](https://cloud.tencent.com/act/pro/warmup202506)

### 一键部署

SSH登录到服务器后，执行：

```bash
bash <(curl -sSL https://raw.githubusercontent.com/your-repo/teslamate-deploy/main/install-simple.sh)
```

### 访问地址

- **TeslaMate**: `http://服务器IP:4000`
- **Grafana**: `http://服务器IP:3000`

## 使用Overseas应用

为了更好的访问体验，推荐使用overseas应用：

1. 配置服务器地址和端口
2. 使用内网穿透功能
3. 享受稳定快速的访问

## 常用命令

```bash
# 查看日志
cd /opt/teslamate && docker-compose logs -f

# 重启服务
cd /opt/teslamate && docker-compose restart

# 更新TeslaMate
cd /opt/teslamate && docker-compose pull && docker-compose up -d

# 备份数据库
cd /opt/teslamate && docker-compose exec database pg_dump -U teslamate teslamate > backup.sql
```

## 防火墙配置

确保开放以下端口：
- 4000 (TeslaMate)
- 3000 (Grafana)

## MyTesla 推荐

搭配MyTesla应用，获得完整的特斯拉体验：
- 远程控制车辆
- 实时状态查看
- 智能提醒功能

## 技术支持

遇到问题？查看[完整文档](./TeslaMate-安全部署指南.md)或提交Issue。