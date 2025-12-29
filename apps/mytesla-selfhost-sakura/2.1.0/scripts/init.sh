#!/bin/bash

# --- 创建必要的数据目录 ---
echo "正在创建数据目录..."
mkdir -p ./data/teslamate/import
mkdir -p ./data/grafana
mkdir -p ./data/postgres
mkdir -p ./data/mosquitto/config
mkdir -p ./data/mosquitto/data
mkdir -p ./data/teslamateapi
mkdir -p ./data/auth
mkdir -p ./data/sakurafrp
mkdir -p ./data/env-adapter

# --- 设置目录权限 ---
echo "正在设置目录权限..."
chmod -R 755 ./data
chown -R 472:472 ./data/grafana 2>/dev/null || true
chown -R 1000:1000 ./data/teslamateapi 2>/dev/null || true
# 确保 teslamateapi 目录有写入权限
chmod 777 ./data/teslamateapi 2>/dev/null || true
chmod 777 ./data/env-adapter 2>/dev/null || true

echo "Mytesla Self Host (SakuraFRP) 初始化完成！"
