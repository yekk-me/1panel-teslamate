# Mytesla Self Host Proxy

Mytesla Self Host Proxy 是一个功能强大的特斯拉车辆数据自托管记录器，集成了 TeslaMate、Grafana 数据可视化、TeslaMateAPI 和 Dash 仪表板，支持通过 FRP Client (frpc) 进行自定义的内网穿透访问。

## 功能特性

* 📊 **数据记录**: 自动记录驾驶、充电、软件更新等数据
* 📈 **数据可视化**: 内置 Grafana 仪表板，提供丰富的数据图表
* 🎛️ **Dash 仪表板**: 现代化的 Web 仪表板界面
* 🔒 **隐私保护**: 数据完全存储在您的服务器上
* 🚗 **多车辆支持**: 支持同时记录多辆特斯拉车辆
* 📱 **Web 界面**: 提供友好的 Web 管理界面
* 🌐 **API 接口**: 提供 TeslaMateAPI RESTful 接口
* 🔐 **安全访问**: 集成 FRPC 内网穿透

## 内置组件

* TeslaMate (特斯拉数据收集器)
* PostgreSQL 数据库（内置，自动部署）
* MQTT 消息队列（内置，自动部署）
* Grafana 数据可视化（内置，自动部署）
* TeslaMateAPI RESTful 接口（内置，自动部署）
* Dash 仪表板（内置，自动部署）
* FRPC (FRP 客户端，用于内网穿透)
* Traefik 反向代理（内置，自动部署）

## 首次配置

### 1. 准备 FRP Server (frps)

在使用本应用之前，您需要有一个运行中的 FRP Server (frps)。

### 2. 配置应用

在 1Panel 应用商店中安装 Mytesla Self Host Proxy 时，您需要配置 `frpc`。

通常你需要编辑 `data/frpc/frpc.toml` 配置文件（在挂载目录中）。由于这是 Docker Compose 部署，请确保在部署前或部署后修改配置文件并重启 `frpc` 服务。

**注意**: 默认配置可能需要您根据实际情况进行调整。

### 3. Basic Auth

本版本默认移除了 `teslamateapi` 的 Basic Auth 保护（针对 `/panel` 接口），但其他服务（如 Grafana, Dash, TeslaMate）可能仍受 Basic Auth 或其自身认证保护。请参考 `mytesla-selfhost` 的相关配置说明。

## 访问地址总览

* **Dash 仪表板**: `http://<frps-ip>:<remote-port>` (取决于您的 FRP 配置)
* **TeslaMate**: `http://<frps-ip>:<remote-port>/teslamate`
* **Grafana**: `http://<frps-ip>:<remote-port>/grafana`

## 故障排除

* 查看 FRPC 日志: `docker logs <容器名>-frpc`
