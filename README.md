# 1Panel TeslaMate 应用商店

此仓库为 [1Panel](https://1panel.cn/) 提供 TeslaMate 及相关服务的第三方应用。

## 安装方法

```sh
git clone -b main https://ghfast.top/https://github.com/yekk-me/1panel-teslamate /opt/1panel/resource/apps/local/1panel-teslamate

cp -rf /opt/1panel/resource/apps/local/1panel-teslamate/apps/* /opt/1panel/resource/apps/local/

rm -rf /opt/1panel/resource/apps/local/1panel-teslamate
```

## 可用应用

### 核心应用

| 应用 | 说明 |
|------|------|
| **mytesla** | TeslaMate 标准版（需配合外部反向代理使用） |
| **mytesla-oversea** | TeslaMate 海外版 |
| **mytesla-proxy** | TeslaMate 反向代理配置 |

### Self Host 系列（模块化架构）

从 v2.1.1 开始，Self Host 采用模块化架构设计：

| 应用 | 说明 | 使用场景 |
|------|------|----------|
| **mytesla-selfhost** | 核心 HTTP 服务 | 必装，提供所有核心功能 |
| **mytesla-cloudflared** | Cloudflare Tunnel 接入层 | 无公网 IP，使用 Cloudflare |
| **mytesla-sakurafrp** | Sakura FRP 接入层 | 无公网 IP，使用 Sakura FRP |
| **mytesla-traefik-ssl** | Traefik + Let's Encrypt 接入层 | 有公网 IP，需要 HTTPS |

### 部署方案示例

```
┌─────────────────────────────────────────────────────────────┐
│                       使用场景选择                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  仅内网访问:                                                 │
│    └── mytesla-selfhost                                     │
│                                                             │
│  有公网 IP + HTTPS:                                         │
│    ├── mytesla-selfhost                                     │
│    └── mytesla-traefik-ssl                                  │
│                                                             │
│  无公网 IP + Cloudflare:                                    │
│    ├── mytesla-selfhost                                     │
│    └── mytesla-cloudflared                                  │
│                                                             │
│  无公网 IP + Sakura FRP:                                    │
│    ├── mytesla-selfhost                                     │
│    └── mytesla-sakurafrp                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 架构说明

```
互联网
   │
   ▼
┌──────────────────────────────┐
│  接入层（按需选择一个）        │
│  - mytesla-cloudflared       │
│  - mytesla-sakurafrp         │
│  - mytesla-traefik-ssl       │
└──────────────────────────────┘
   │
   │ http://host.docker.internal:8080
   ▼
┌──────────────────────────────┐
│  mytesla-selfhost            │
│  ├── Traefik (HTTP)          │
│  ├── Auth (认证)             │
│  ├── Dash (仪表板)           │
│  ├── TeslaMate (数据采集)    │
│  ├── TeslaMateAPI            │
│  ├── Grafana (可视化)        │
│  ├── PostgreSQL              │
│  └── Mosquitto (MQTT)        │
└──────────────────────────────┘
```

## 更多信息

* [Mytesla.cc 官网](https://mytesla.cc/)
* [使用手册](https://manual.mytesla.cc/)
* [TeslaMate 官方文档](https://docs.teslamate.org/)
