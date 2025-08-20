# TeslaMate 安全部署方案

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen.svg)](https://www.docker.com/)
[![TeslaMate](https://img.shields.io/badge/TeslaMate-compatible-green.svg)](https://github.com/adriankumpf/teslamate)

一键部署TeslaMate，支持overseas代理，自动配置SSL证书，安全可靠。

## 特性

- 🚀 **一键部署** - 仅需一行命令即可完成全部配置
- 🔒 **安全加密** - 自动配置SSL证书，支持HTTPS访问
- 🌏 **Overseas支持** - 内置代理配置，确保API访问稳定
- 🔐 **访问控制** - 自动生成安全密码，支持Basic Auth认证
- 📊 **数据可视化** - 预配置Grafana仪表板
- 🔄 **自动更新** - 支持Docker镜像自动更新

## 快速开始

### 系统要求

- Ubuntu 20.04/22.04 或 Debian 10/11
- 至少1GB内存
- 10GB可用磁盘空间
- 已配置域名DNS解析

### 一键部署

登录到您的服务器，执行以下命令：

```bash
bash <(curl -sSL https://raw.githubusercontent.com/your-repo/teslamate-deploy/main/install.sh)
```

### 部署过程

1. 脚本会自动安装Docker环境
2. 根据提示输入邮箱、域名等信息
3. 自动申请并配置SSL证书
4. 部署TeslaMate及相关组件
5. 显示访问地址和密码

## 配置说明

### 必需信息

- **邮箱地址**：用于Let's Encrypt SSL证书申请
- **域名**：您的TeslaMate访问域名
- **时区**：数据记录的时区设置

### 可选配置

- **Overseas代理**：如需稳定访问特斯拉API，可配置代理
- **自定义端口**：可修改默认的访问端口

## 访问地址

部署完成后，您可以通过以下地址访问：

- **TeslaMate**: `https://您的域名`
- **Grafana**: `https://您的域名/grafana`

## 更新维护

### 更新TeslaMate

```bash
cd /opt/teslamate
docker-compose pull
docker-compose up -d
```

### 备份数据

```bash
cd /opt/teslamate
docker-compose exec database pg_dump -U teslamate teslamate > backup.sql
```

### 查看日志

```bash
cd /opt/teslamate
docker-compose logs -f teslamate
```

## MyTesla 推荐

[MyTesla](https://mytesla.com) 是一款优秀的特斯拉第三方应用，与TeslaMate完美配合：

- 📱 精美的移动端界面
- 🚗 完整的车辆控制功能
- 📊 丰富的数据统计
- 🔔 智能提醒通知

## 故障排除

### 常见问题

1. **无法访问网站**
   - 检查域名DNS是否正确解析
   - 确认防火墙开放了80和443端口

2. **SSL证书申请失败**
   - 确保域名已正确解析到服务器IP
   - 检查80端口是否被占用

3. **无法连接特斯拉**
   - 检查代理配置是否正确
   - 确认特斯拉账号密码正确

### 获取帮助

- [GitHub Issues](https://github.com/your-repo/teslamate-deploy/issues)
- [TeslaMate官方文档](https://docs.teslamate.org/)
- [社区论坛](https://community.teslamate.org/)

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- [TeslaMate](https://github.com/adriankumpf/teslamate) - 优秀的特斯拉数据记录工具
- [MyTesla](https://mytesla.com) - 便捷的特斯拉控制应用
- 所有贡献者和用户

---

**免责声明**：本项目与特斯拉公司无关。使用本工具需遵守特斯拉的服务条款。