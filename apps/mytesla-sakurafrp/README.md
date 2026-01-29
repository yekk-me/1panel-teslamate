# Mytesla SakuraFrp

Sakura FRP 内网穿透接入层，用于为 mytesla-selfhost 提供外网访问。

## 使用前提

1. 已安装 `mytesla-selfhost` 应用
2. 拥有 [SakuraFrp](https://www.natfrp.com/) 账号

## 配置步骤

### 1. 获取访问密钥

1. 登录 [SakuraFrp 面板](https://www.natfrp.com/user/)
2. 进入「用户信息」页面
3. 复制「访问密钥」

### 2. 安装应用

在 1Panel 中安装此应用，填写访问密钥。

### 3. 创建隧道

1. 安装完成后，访问 `http://服务器IP:7102` 打开启动器管理面板
2. 在 SakuraFrp 官网创建隧道：
   - 隧道类型：HTTP(S)
   - 本地地址：`localhost` 或 `127.0.0.1`
   - 本地端口：`8080`（与 mytesla-selfhost 的 HTTP 端口一致）
3. 在启动器管理面板中启用该隧道

## 架构说明

```
互联网 -> SakuraFrp 节点 -> 启动器 -> localhost:8080 -> mytesla-selfhost
```

## 注意事项

- 启动器 Web 面板默认端口 7102
- 使用 host 网络模式，直接通过 `localhost` 访问宿主机上的 mytesla-selfhost 服务
- 隧道配置在 SakuraFrp 官网进行，启动器负责连接
