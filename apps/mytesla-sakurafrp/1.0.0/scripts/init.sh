#!/bin/bash

echo "Mytesla SakuraFrp 初始化完成！"
echo ""
echo "使用说明："
echo "1. 确保已安装 mytesla-selfhost 应用"
echo "2. 在 SakuraFrp 面板中创建隧道"
echo "3. 配置隧道的本地地址为: host.docker.internal:${UPSTREAM_PORT:-8080}"
echo ""
