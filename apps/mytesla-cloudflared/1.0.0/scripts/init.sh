#!/bin/bash

echo "Mytesla Cloudflared 初始化完成！"
echo ""
echo "使用说明："
echo "1. 确保已安装 mytesla-selfhost 应用"
echo "2. 在 Cloudflare Zero Trust 面板中配置 Tunnel"
echo "3. 将 Tunnel 的上游地址设置为: http://host.docker.internal:${UPSTREAM_PORT:-8080}"
echo ""
