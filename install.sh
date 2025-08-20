#!/bin/bash

# TeslaMate 一键安装脚本
# 适用于腾讯云海外服务器
# 作者: AI Assistant
# 版本: 1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印标题
print_title() {
    echo
    print_message $CYAN "=================================================="
    print_message $CYAN "  $1"
    print_message $CYAN "=================================================="
    echo
}

# 生成随机密码
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message $RED "错误: 请使用 root 用户运行此脚本"
        print_message $YELLOW "请使用: sudo su - 切换到 root 用户"
        exit 1
    fi
}

# 检查系统兼容性
check_system() {
    if ! command -v curl &> /dev/null; then
        print_message $YELLOW "正在安装 curl..."
        apt update && apt install -y curl
    fi
    
    if ! command -v openssl &> /dev/null; then
        print_message $YELLOW "正在安装 openssl..."
        apt update && apt install -y openssl
    fi
}

# 安装 Docker
install_docker() {
    print_title "安装 Docker"
    
    if command -v docker &> /dev/null; then
        print_message $GREEN "Docker 已安装，跳过安装步骤"
        return
    fi
    
    print_message $YELLOW "正在安装 Docker..."
    bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
    
    # 启动 Docker 服务
    systemctl enable docker
    systemctl start docker
    
    print_message $GREEN "Docker 安装完成！"
}

# 收集用户输入
collect_user_input() {
    print_title "配置环境变量"
    
    # 域名配置
    while true; do
        read -p "$(echo -e ${BLUE}请输入您的域名 (例如: teslamate.example.com): ${NC})" DOMAIN
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_message $RED "请输入有效的域名格式"
        fi
    done
    
    # 邮箱配置
    while true; do
        read -p "$(echo -e ${BLUE}请输入您的邮箱 (用于 SSL 证书申请): ${NC})" EMAIL
        if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_message $RED "请输入有效的邮箱格式"
        fi
    done
    
    # 基础认证配置
    print_message $YELLOW "基础认证配置:"
    read -p "$(echo -e ${BLUE}请输入 TeslaMate 用户名 (默认: admin): ${NC})" BASIC_AUTH_USER
    BASIC_AUTH_USER=${BASIC_AUTH_USER:-"admin"}
    read -s -p "$(echo -e ${BLUE}请输入 TeslaMate 密码 (留空自动生成): ${NC})" BASIC_AUTH_PASS
    echo
    if [[ -z "$BASIC_AUTH_PASS" ]]; then
        BASIC_AUTH_PASS=$(generate_password 16)
        print_message $GREEN "已自动生成密码: $BASIC_AUTH_PASS"
    fi
    
    # 可选配置
    read -p "$(echo -e ${BLUE}请输入时区 (默认: Asia/Shanghai): ${NC})" TIMEZONE
    TIMEZONE=${TIMEZONE:-"Asia/Shanghai"}
    
    # 生成随机密码
    print_message $YELLOW "正在生成安全密码..."
    TM_DB_PASS=$(generate_password 20)
    TM_ENCRYPTION_KEY=$(generate_password 32)
    API_TOKEN=$(generate_password 32)
    GRAFANA_PW=$(generate_password 16)
    
    # 可选的百度地图配置
    print_message $YELLOW "百度地图配置 (可选，用于更精确的位置信息):"
    read -p "$(echo -e ${BLUE}百度地图 AK (留空跳过): ${NC})" BD_MAP_AK
    if [[ -n "$BD_MAP_AK" ]]; then
        read -p "$(echo -e ${BLUE}百度地图 SK: ${NC})" BD_MAP_SK
    fi
    
    print_message $GREEN "环境变量配置完成！"
}

# 创建项目目录和文件
setup_project() {
    print_title "创建项目文件"
    
    # 创建项目目录
    PROJECT_DIR="/opt/teslamate"
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # 创建 .env 文件
    cat > .env << EOF
# 基础配置
CONTAINER_NAME=teslamate
DOMAIN=$DOMAIN
TZ=$TIMEZONE

# 基础认证
BASIC_AUTH_USER=$BASIC_AUTH_USER
BASIC_AUTH_PASS=$BASIC_AUTH_PASS

# 数据库配置
TM_DB_USER=teslamate
TM_DB_PASS=$TM_DB_PASS
TM_DB_NAME=teslamate

# 应用配置
TM_ENCRYPTION_KEY=$TM_ENCRYPTION_KEY
API_TOKEN=$API_TOKEN

# SSL 配置
LETSENCRYPT_EMAIL=$EMAIL

# Grafana 配置
GRAFANA_USER=admin
GRAFANA_PW=$GRAFANA_PW

# 百度地图配置 (可选)
BD_MAP_AK=$BD_MAP_AK
BD_MAP_SK=$BD_MAP_SK
EOF

    # 创建 docker-compose.yml (基于 MyTesla-oversea 配置)
    cat > docker-compose.yml << 'EOF'
version: "3"

services:
  auth-generator:
    image: httpd:2.4
    container_name: ${CONTAINER_NAME}-auth-generator
    restart: "unless-stopped"
    volumes:
      - ./data/auth:/auth
    environment:
      - BASIC_AUTH_USER=${BASIC_AUTH_USER}
      - BASIC_AUTH_PASS=${BASIC_AUTH_PASS}
    command: >
      sh -c '
        if [ -n "$$BASIC_AUTH_USER" ] && [ -n "$$BASIC_AUTH_PASS" ]; then
          htpasswd -cb /auth/.htpasswd $$BASIC_AUTH_USER $$BASIC_AUTH_PASS;
          echo "Basic Auth file created/updated.";
        else
          echo "Warning: BASIC_AUTH_USER or BASIC_AUTH_PASS not set. Skipping .htpasswd creation.";
        fi
        echo "Initialization complete. Staying alive for the panel...";
        tail -f /dev/null
      '

  # Traefik as unified gateway
  traefik:
    image: traefik:v3.5.0
    container_name: ${CONTAINER_NAME}-traefik
    restart: unless-stopped
    command:
      - "--global.sendAnonymousUsage=false"
      - "--providers.docker"
      - "--providers.docker.exposedByDefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.tmhttpchallenge.acme.httpchallenge=true"
      - "--certificatesresolvers.tmhttpchallenge.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.tmhttpchallenge.acme.email=${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.tmhttpchallenge.acme.storage=/etc/acme/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data/auth:/auth
      - ./data/acme:/etc/acme
    labels:
      - "traefik.enable=true"
    depends_on:
      - auth-generator

  teslamate:
    image: mytesla/teslamate:v2.1
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    depends_on:
      - database
      - mosquitto
    environment:
      - DATABASE_USER=${TM_DB_USER}
      - DATABASE_PASS=${TM_DB_PASS}
      - DATABASE_NAME=${TM_DB_NAME}
      - DATABASE_HOST=database
      - MQTT_HOST=mosquitto
      - VIRTUAL_HOST=${DOMAIN}
      - ENCRYPTION_KEY=${TM_ENCRYPTION_KEY}
      - TZ=${TZ}
      - CHECK_ORIGIN=true
      - BD_MAP_AK=${BD_MAP_AK}
      - BD_MAP_SK=${BD_MAP_SK}
    volumes:
      - ./data/teslamate:/opt/app/import
    labels:
      traefik.enable: "true"
      traefik.port: "4000"
      traefik.http.middlewares.redirect.redirectscheme.scheme: "https"
      traefik.http.middlewares.teslamate-auth.basicauth.realm: "teslamate"
      traefik.http.middlewares.teslamate-auth.basicauth.usersfile: "/auth/.htpasswd"
      traefik.http.routers.teslamate-insecure.rule: "Host(`${DOMAIN}`)"
      traefik.http.routers.teslamate-insecure.middlewares: "redirect"
      traefik.http.routers.teslamate-ws.rule: "Host(`${DOMAIN}`) && Path(`/live/websocket`)"
      traefik.http.routers.teslamate-ws.entrypoints: "websecure"
      traefik.http.routers.teslamate-ws.tls: ""
      traefik.http.routers.teslamate.rule: "Host(`${DOMAIN}`)"
      traefik.http.routers.teslamate.middlewares: "teslamate-auth"
      traefik.http.routers.teslamate.entrypoints: "websecure"
      traefik.http.routers.teslamate.tls.certresolver: "tmhttpchallenge"

  grafana:
    image: mytesla/grafana:v2.1
    container_name: ${CONTAINER_NAME}-grafana
    restart: unless-stopped
    depends_on:
      - database
    environment:
      - DATABASE_USER=${TM_DB_USER}
      - DATABASE_PASS=${TM_DB_PASS}
      - DATABASE_NAME=${TM_DB_NAME}
      - DATABASE_HOST=database
      - GRAFANA_PASSWD=${GRAFANA_PW}
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PW}
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_USERS_DEFAULT_LANGUAGE=zh-CN
      - GF_SERVER_DOMAIN=${DOMAIN}
      - GF_SERVER_ROOT_URL=https://${DOMAIN}/grafana
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
    volumes:
      - ./data/grafana:/var/lib/grafana
    labels:
      traefik.enable: "true"
      traefik.port: "3000"
      traefik.http.middlewares.redirect.redirectscheme.scheme: "https"
      traefik.http.routers.grafana-insecure.rule: "Host(`${DOMAIN}`)"
      traefik.http.routers.grafana-insecure.middlewares: "redirect"
      traefik.http.routers.grafana.rule: "Host(`${DOMAIN}`) && (Path(`/grafana`) || PathPrefix(`/grafana/`))"
      traefik.http.routers.grafana.entrypoints: "websecure"
      traefik.http.routers.grafana.tls.certresolver: "tmhttpchallenge"

  teslamateapi:
    image: mytesla/teslamateapi:latest
    container_name: ${CONTAINER_NAME}-teslamateapi
    restart: unless-stopped
    depends_on:
      - database
    environment:
      - DATABASE_USER=${TM_DB_USER}
      - DATABASE_PASS=${TM_DB_PASS}
      - DATABASE_NAME=${TM_DB_NAME}
      - DATABASE_HOST=database
      - ENCRYPTION_KEY=${TM_ENCRYPTION_KEY}
      - MQTT_HOST=mosquitto
      - API_TOKEN=${API_TOKEN}
    volumes:
      - ./data/teslamateapi:/opt/app/data
    labels:
      traefik.enable: "true"
      traefik.port: "8080"
      traefik.http.middlewares.redirect.redirectscheme.scheme: "https"
      traefik.http.routers.teslamateapi-insecure.rule: "Host(`${DOMAIN}`)"
      traefik.http.routers.teslamateapi-insecure.middlewares: "redirect"
      traefik.http.routers.teslamateapi.rule: "Host(`${DOMAIN}`) && PathPrefix(`/api`)"
      traefik.http.routers.teslamateapi.entrypoints: "websecure"
      traefik.http.routers.teslamateapi.tls.certresolver: "tmhttpchallenge"

  database:
    image: postgres:17
    container_name: ${CONTAINER_NAME}-database
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${TM_DB_USER}
      - POSTGRES_PASSWORD=${TM_DB_PASS}
      - POSTGRES_DB=${TM_DB_NAME}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data

  mosquitto:
    image: eclipse-mosquitto:2
    container_name: ${CONTAINER_NAME}-mosquitto
    restart: unless-stopped
    command: mosquitto -c /mosquitto-no-auth.conf
    volumes:
      - ./data/mosquitto/config:/mosquitto/config
      - ./data/mosquitto/data:/mosquitto/data

networks:
  default:
    name: ${CONTAINER_NAME}-network
EOF

    print_message $GREEN "项目文件创建完成！"
}

# 配置防火墙
setup_firewall() {
    print_title "配置防火墙"
    
    # 安装 UFW
    if ! command -v ufw &> /dev/null; then
        apt update && apt install -y ufw
    fi
    
    # 配置防火墙规则
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # 允许必要端口
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    
    # 启用防火墙
    ufw --force enable
    
    print_message $GREEN "防火墙配置完成！"
}

# 启动服务
start_services() {
    print_title "启动 TeslaMate 服务"
    
    cd $PROJECT_DIR
    
    # 拉取镜像
    print_message $YELLOW "正在拉取 Docker 镜像..."
    docker-compose pull
    
    # 启动服务
    print_message $YELLOW "正在启动服务..."
    docker-compose up -d
    
    print_message $GREEN "服务启动完成！"
}

# 等待服务就绪
wait_for_services() {
    print_title "等待服务启动"
    
    print_message $YELLOW "正在等待服务启动..."
    sleep 30
    
    # 检查服务状态
    cd $PROJECT_DIR
    if docker-compose ps | grep -q "Up"; then
        print_message $GREEN "服务启动成功！"
    else
        print_message $RED "服务启动可能有问题，请检查日志："
        print_message $YELLOW "docker-compose logs"
    fi
}

# 显示部署信息
show_deployment_info() {
    print_title "部署完成"
    
    cat << EOF
$(print_message $GREEN "🎉 TeslaMate 部署成功！")

$(print_message $CYAN "📋 部署信息:")
• 域名: https://$DOMAIN
• Grafana: https://$DOMAIN/grafana/
• 项目目录: $PROJECT_DIR

$(print_message $CYAN "🔐 登录信息:")
• TeslaMate 用户名: $BASIC_AUTH_USER
• TeslaMate 密码: $BASIC_AUTH_PASS
• Grafana 用户名: admin
• Grafana 密码: $GRAFANA_PW

$(print_message $CYAN "🛠️ 常用命令:")
• 查看服务状态: cd $PROJECT_DIR && docker-compose ps
• 查看日志: cd $PROJECT_DIR && docker-compose logs -f
• 重启服务: cd $PROJECT_DIR && docker-compose restart
• 停止服务: cd $PROJECT_DIR && docker-compose down

$(print_message $YELLOW "⚠️ 重要提示:")
1. 请保存好上述登录信息
2. SSL 证书申请需要 2-5 分钟，请耐心等待
3. 首次访问可能需要等待 5-10 分钟服务完全启动

$(print_message $PURPLE "📱 MyTesla 应用推荐:")
• 下载 MyTesla 移动应用获得更好的使用体验
• 支持实时监控、数据分析、智能提醒等功能
• iOS/Android 应用商店搜索 "MyTesla"

$(print_message $GREEN "🚗 现在您可以访问 https://$DOMAIN 开始使用 TeslaMate！")
EOF
}

# 主函数
main() {
    print_title "TeslaMate 一键部署脚本"
    
    print_message $CYAN "欢迎使用 TeslaMate 一键部署脚本！"
    print_message $YELLOW "本脚本将帮助您在腾讯云服务器上安全部署 TeslaMate"
    echo
    
    # 确认继续
    read -p "$(echo -e ${BLUE}是否继续安装? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message $YELLOW "安装已取消"
        exit 0
    fi
    
    # 执行安装步骤
    check_root
    check_system
    install_docker
    collect_user_input
    setup_project
    setup_firewall
    start_services
    wait_for_services
    show_deployment_info
    
    print_message $GREEN "🎉 安装完成！感谢使用！"
}

# 错误处理
trap 'print_message $RED "安装过程中出现错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"