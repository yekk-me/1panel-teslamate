# Mytesla Traefik SSL

Traefik 反向代理 + Let's Encrypt 自动 SSL 证书，用于为 mytesla-selfhost 提供 HTTPS 访问。

## 使用前提

1. 已安装 `mytesla-selfhost` 应用
2. 拥有公网 IP
3. 拥有域名并已解析到服务器公网 IP
4. 端口 80 和 443 已在防火墙中开放

## 配置步骤

1. 将域名 A 记录指向服务器公网 IP
2. 在 1Panel 中安装此应用，填写域名和邮箱
3. 等待 Let's Encrypt 自动签发证书（通常几分钟内完成）

## 架构说明

```
互联网 -> Traefik (443/HTTPS) -> host.docker.internal:8080 -> mytesla-selfhost
                ↓
        Let's Encrypt (自动证书)
```

此应用通过 `host.docker.internal` 连接宿主机上运行的 mytesla-selfhost 服务。

## 注意事项

- Let's Encrypt 证书有效期 90 天，Traefik 会自动续期
- 首次申请证书需要端口 80 可访问（HTTP Challenge）
- 如果证书申请失败，请检查域名解析和防火墙设置
