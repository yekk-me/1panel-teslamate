#!/bin/bash

# 加载 .env 文件中的环境变量
if [ -f .env ]; then
    echo "正在加载环境变量..."
    set -a
    source .env
    set +a
else
    echo "错误：找不到 .env 文件"
    exit 1
fi

# 创建数据目录
echo "正在创建配置目录..."
mkdir -p ./data/frpc

# 从环境变量生成 frpc.toml 配置文件
echo "正在生成 frpc.toml 配置文件..."

cat > ./data/frpc/frpc.toml << EOF
# frpc.toml

serverAddr = "${FRP_SERVER_ADDR}"
serverPort = ${FRP_SERVER_PORT}

[[proxies]]
name = "${PROXY_NAME}"
type = "${PROXY_TYPE}"
localIP = "${LOCAL_IP}"
localPort = ${LOCAL_PORT}
EOF

# 如果是 HTTP/HTTPS 类型，添加 subdomain
if [ "${PROXY_TYPE}" = "http" ] || [ "${PROXY_TYPE}" = "https" ]; then
    echo "subdomain = \"${PROXY_NAME}\"" >> ./data/frpc/frpc.toml
fi

# 设置文件权限
chmod 644 ./data/frpc/frpc.toml

echo "生成的配置文件内容："
cat ./data/frpc/frpc.toml

echo ""
echo "Mytesla Self Host Proxy 初始化完成！"
