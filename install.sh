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
    
    # Tesla 账号配置
    print_message $YELLOW "Tesla 账号配置:"
    read -p "$(echo -e ${BLUE}请输入您的 Tesla 账号邮箱: ${NC})" TESLA_EMAIL
    read -s -p "$(echo -e ${BLUE}请输入您的 Tesla 账号密码: ${NC})" TESLA_PASSWORD
    echo
    
    # 可选配置
    read -p "$(echo -e ${BLUE}请输入时区 (默认: Asia/Shanghai): ${NC})" TIMEZONE
    TIMEZONE=${TIMEZONE:-"Asia/Shanghai"}
    
    # 生成随机密码
    print_message $YELLOW "正在生成安全密码..."
    DB_PASSWORD=$(generate_password 20)
    SECRET_KEY=$(generate_password 32)
    ENCRYPTION_KEY=$(generate_password 32)
    
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
DOMAIN=$DOMAIN
TZ=$TIMEZONE
CHECK_ORIGIN=false

# 数据库配置
DATABASE_USER=teslamate
DATABASE_PASS=$DB_PASSWORD
DATABASE_NAME=teslamate
DATABASE_HOST=database

# 应用配置
SECRET_KEY_BASE=$SECRET_KEY
ENCRYPTION_KEY=$ENCRYPTION_KEY

# Tesla 配置
TESLA_EMAIL=$TESLA_EMAIL
TESLA_PASSWORD=$TESLA_PASSWORD

# SSL 配置
LETSENCRYPT_EMAIL=$EMAIL

# Grafana 配置
GRAFANA_PASSWD=$DB_PASSWORD
GRAFANA_USER=admin

# 可选配置
DISABLE_MQTT=false
MQTT_HOST=mosquitto
EOF

    # 创建 docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3'

services:
  teslamate:
    image: teslamate/teslamate:latest
    restart: always
    environment:
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - DATABASE_USER=${DATABASE_USER}
      - DATABASE_PASS=${DATABASE_PASS}
      - DATABASE_NAME=${DATABASE_NAME}
      - DATABASE_HOST=${DATABASE_HOST}
      - MQTT_HOST=${MQTT_HOST}
      - VIRTUAL_HOST=${DOMAIN}
      - LETSENCRYPT_HOST=${DOMAIN}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
      - TZ=${TZ}
      - CHECK_ORIGIN=${CHECK_ORIGIN}
    ports:
      - "4000:4000"
    volumes:
      - ./import:/opt/app/import
    cap_drop:
      - all

  database:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_USER=${DATABASE_USER}
      - POSTGRES_PASSWORD=${DATABASE_PASS}
      - POSTGRES_DB=${DATABASE_NAME}
    volumes:
      - teslamate-db:/var/lib/postgresql/data

  grafana:
    image: teslamate/grafana:latest
    restart: always
    environment:
      - DATABASE_USER=${DATABASE_USER}
      - DATABASE_PASS=${DATABASE_PASS}
      - DATABASE_NAME=${DATABASE_NAME}
      - DATABASE_HOST=${DATABASE_HOST}
      - GRAFANA_PASSWD=${GRAFANA_PASSWD}
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWD}
      - GF_AUTH_BASIC_ENABLED=true
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_SERVER_DOMAIN=${DOMAIN}
      - GF_SERVER_ROOT_URL=https://${DOMAIN}/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      - VIRTUAL_HOST=${DOMAIN}
      - VIRTUAL_PATH=/grafana/
      - LETSENCRYPT_HOST=${DOMAIN}
      - LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}
    ports:
      - "3000:3000"
    volumes:
      - teslamate-grafana-data:/var/lib/grafana

  mosquitto:
    image: eclipse-mosquitto:2
    restart: always
    command: mosquitto -c /mosquitto-no-auth.conf
    ports:
      - "1883:1883"
    volumes:
      - mosquitto-conf:/mosquitto/config
      - mosquitto-data:/mosquitto/data

  nginx-proxy:
    image: nginxproxy/nginx-proxy:latest
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - nginx-certs:/etc/nginx/certs
      - nginx-vhost:/etc/nginx/vhost.d
      - nginx-html:/usr/share/nginx/html

  letsencrypt:
    image: nginxproxy/acme-companion:latest
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - nginx-certs:/etc/nginx/certs
      - nginx-vhost:/etc/nginx/vhost.d
      - nginx-html:/usr/share/nginx/html
      - acme-state:/etc/acme.sh
    environment:
      - DEFAULT_EMAIL=${LETSENCRYPT_EMAIL}

volumes:
  teslamate-db:
  teslamate-grafana-data:
  mosquitto-conf:
  mosquitto-data:
  nginx-certs:
  nginx-vhost:
  nginx-html:
  acme-state:
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
• Grafana 用户名: admin
• Grafana 密码: $DB_PASSWORD

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