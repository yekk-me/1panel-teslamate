#!/bin/bash

# --- 创建必要的数据目录 ---
echo "正在创建数据目录..."
mkdir -p ./data/traefik/letsencrypt

# --- 创建 Traefik 动态配置文件 ---
echo "正在创建 Traefik 动态配置..."

cat > ./data/traefik/dynamic.yml << EOF
http:
  routers:
    mytesla:
      rule: "Host(\`${DOMAIN}\`)"
      entryPoints:
        - websecure
      service: mytesla-backend
      tls:
        certResolver: letsencrypt

  services:
    mytesla-backend:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:${UPSTREAM_PORT:-8080}"
EOF

# --- 设置权限 ---
chmod 600 ./data/traefik/letsencrypt 2>/dev/null || true

echo "Mytesla Traefik SSL 初始化完成！"
echo ""
echo "使用说明："
echo "1. 确保已安装 mytesla-selfhost 应用"
echo "2. 确保域名 ${DOMAIN} 已解析到本服务器的公网 IP"
echo "3. 确保端口 80 和 443 已在防火墙中开放"
echo ""
