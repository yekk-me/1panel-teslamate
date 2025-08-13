#!/bin/bash

# 创建数据目录
echo "正在创建数据目录..."
mkdir -p ./data

# 从环境变量生成 frpc.toml 配置文件
echo "正在生成 frpc.toml 配置文件..."

cat > ./data/frpc.toml << EOF
# frpc.toml

serverAddr = "${FRP_SERVER_ADDR}"
serverPort = ${FRP_SERVER_PORT}

[[proxies]]
name = "${PROXY_NAME}_web_${LOCAL_PORT}"
type = "${PROXY_TYPE}"
localIP = "${LOCAL_IP}"
localPort = ${LOCAL_PORT}
EOF

# 如果是 HTTP/HTTPS 类型，添加 subdomain
if [ "${PROXY_TYPE}" = "http" ] || [ "${PROXY_TYPE}" = "https" ]; then
    echo "subdomain = \"${PROXY_NAME}\"" >> ./data/frpc.toml
fi

# 设置文件权限
chmod 644 ./data/frpc.toml

echo "生成的配置文件内容："
cat ./data/frpc.toml

echo ""
echo "Mytesla Proxy (FRP 客户端) 初始化完成！"