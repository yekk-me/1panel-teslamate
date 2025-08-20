# TeslaMate Overseas代理配置指南

## 为什么需要Overseas代理？

由于网络环境的特殊性，在某些地区直接访问特斯拉API可能会遇到连接问题。通过配置overseas代理，可以确保TeslaMate稳定地与特斯拉服务器通信。

## 代理方案选择

### 方案一：使用现有的代理服务

如果您已经有可用的代理服务（如Shadowsocks、V2Ray等），可以直接在安装脚本中输入代理地址。

支持的代理格式：
- SOCKS5: `socks5://127.0.0.1:1080`
- HTTP: `http://127.0.0.1:8080`
- HTTPS: `https://127.0.0.1:8080`

### 方案二：在服务器上部署代理

如果没有现成的代理，可以在同一台服务器上部署一个轻量级的代理服务。

#### 安装V2Ray（推荐）

```bash
# 安装V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 创建配置文件
cat > /usr/local/etc/v2ray/config.json << EOF
{
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "your-proxy-server.com",
            "port": 443,
            "users": [
              {
                "id": "your-uuid",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls"
      }
    }
  ]
}
EOF

# 启动V2Ray
systemctl start v2ray
systemctl enable v2ray
```

#### 安装Shadowsocks

```bash
# 安装Shadowsocks
apt-get update
apt-get install -y shadowsocks-libev

# 创建配置文件
cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server": "your-ss-server.com",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "your-password",
    "timeout": 300,
    "method": "chacha20-ietf-poly1305"
}
EOF

# 启动Shadowsocks
systemctl start shadowsocks-libev-local@config
systemctl enable shadowsocks-libev-local@config
```

## 代理配置注意事项

### 1. 代理稳定性
- 选择稳定的代理服务器，避免频繁断连
- 建议使用付费的商业代理服务
- 定期检查代理连接状态

### 2. 安全性考虑
- 仅在本地（127.0.0.1）监听代理端口
- 不要将代理端口暴露到公网
- 使用强密码和加密方式

### 3. 性能优化
- 选择地理位置接近的代理服务器
- 使用支持UDP的代理协议
- 避免多层代理嵌套

## 验证代理配置

安装完成后，可以通过以下命令验证代理是否正常工作：

```bash
# 进入TeslaMate容器
docker exec -it teslamate_teslamate_1 /bin/sh

# 测试代理连接
curl -x socks5://127.0.0.1:1080 https://api.tesla.com/api/1/vehicles

# 如果返回401错误（需要认证），说明代理工作正常
```

## 常见问题

### Q: 代理连接失败怎么办？
A: 检查以下几点：
1. 代理服务是否正常运行
2. 防火墙是否允许代理端口
3. 代理配置是否正确

### Q: 可以不使用代理吗？
A: 如果您的服务器在海外（如新加坡），通常不需要代理即可正常访问特斯拉API。

### Q: 代理会影响数据安全吗？
A: TeslaMate与特斯拉的通信都是加密的，代理只是转发加密数据，不会影响安全性。

## 更新代理配置

如果需要修改代理设置，编辑docker-compose.yml文件：

```bash
cd /opt/teslamate
nano docker-compose.yml

# 找到teslamate服务的环境变量部分
# 修改或添加：
# - HTTP_PROXY=新的代理地址
# - HTTPS_PROXY=新的代理地址

# 重启服务
docker-compose restart teslamate
```

## 推荐的代理服务商

1. **机场服务**（付费）
   - 稳定性高
   - 多节点可选
   - 技术支持完善

2. **云服务商提供的代理**
   - AWS Global Accelerator
   - Cloudflare Warp
   - 腾讯云全球应用加速

3. **自建代理**
   - 完全掌控
   - 成本可控
   - 需要一定技术基础

选择适合您的方案，确保TeslaMate能够稳定运行！