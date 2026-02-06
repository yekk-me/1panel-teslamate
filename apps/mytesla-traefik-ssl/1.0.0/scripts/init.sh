#!/bin/bash

# --- 加载 .env 文件中的环境变量 ---
if [ -f .env ]; then
    echo "正在加载环境变量..."
    set -a
    source .env
    set +a
else
    echo "错误：找不到 .env 文件"
    exit 1
fi

# --- 检查必需的环境变量 ---
if [ -z "${DOMAIN}" ]; then
    echo "错误：DOMAIN 环境变量未设置！"
    echo "请在 1Panel 应用配置中设置域名。"
    exit 1
fi

if [ -z "${UPSTREAM_PORT}" ]; then
    echo "警告：UPSTREAM_PORT 未设置，使用默认值 8080"
    UPSTREAM_PORT=8080
fi

echo "配置信息："
echo "  域名: ${DOMAIN}"
echo "  上游端口: ${UPSTREAM_PORT}"
echo ""

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
