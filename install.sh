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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message $RED "错误: 请使用 root 用户运行此脚本"
        print_message $YELLOW "请使用: sudo 执行该脚本"
        exit 1
    fi
}

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

# 显示现有安装信息
show_existing_info() {
    PROJECT_DIR="/opt/teslamate"
    
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_message $RED "未找到现有安装"
        return 1
    fi
    
    print_title "TeslaMate 安装信息"
    
    # 读取配置信息
    source "$PROJECT_DIR/.env"
    
    cat << EOF
$(print_message $GREEN "🎉 TeslaMate 已安装！")

$(print_message $CYAN "📋 部署信息:")
• 域名: https://$DOMAIN
• Grafana: https://$DOMAIN/grafana/
• 项目目录: $PROJECT_DIR

$(print_message $CYAN "🔐 登录信息:")
• TeslaMate 用户名: $BASIC_AUTH_USER
• TeslaMate 密码: $BASIC_AUTH_PASS
• Grafana 用户名: $GRAFANA_USER
• Grafana 密码: $GRAFANA_PW

$(print_message $CYAN "🚗 Mytesla UI 登录信息:")
• 访问地址设置：https://$DOMAIN
• 访问令牌: $API_TOKEN

$(print_message $CYAN "🛠️ 常用命令:")
• 查看服务状态: cd $PROJECT_DIR && docker compose ps
• 查看日志: cd $PROJECT_DIR && docker compose logs -f
• 重启服务: $0 --restart
• 停止服务: $0 --stop
• 启动服务: $0 --start

$(print_message $CYAN "💾 备份和恢复命令:")
• 备份数据: $0 --backup
• 恢复数据: $0 --restore

$(print_message $PURPLE "📱 Mytesla UI推荐:")
• 使用 Mytesla UI 获得更好的使用体验
• 支持实时监控、数据分析、电池健康度查询、峰谷用电自动计费、提醒等功能
• https://portal.mytesla.cc
• https://xhslink.com/m/3iNZ8St7x9J

$(print_message $GREEN "🚗 现在您可以访问 https://$DOMAIN 开始使用 TeslaMate！")
EOF
}

# 检查现有安装
check_existing_installation() {
    PROJECT_DIR="/opt/teslamate"
    
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        print_message $YELLOW "检测到现有的 TeslaMate 安装"
        print_message $CYAN "项目目录: $PROJECT_DIR"
        
        # 显示现有配置信息
        if [[ -f "$PROJECT_DIR/.env" ]]; then
            EXISTING_DOMAIN=$(grep "^DOMAIN=" "$PROJECT_DIR/.env" | cut -d'=' -f2)
            EXISTING_USER=$(grep "^BASIC_AUTH_USER=" "$PROJECT_DIR/.env" | cut -d'=' -f2)
            print_message $CYAN "现有域名: $EXISTING_DOMAIN"
            print_message $CYAN "现有用户: $EXISTING_USER"
        fi
        
        echo
        printf "%b" "${BLUE}选择操作:${NC}\n"
        printf "%b" "${BLUE}1) 显示安装信息和密码${NC}\n"
        printf "%b" "${BLUE}2) 重新安装 (会清除所有数据)${NC}\n"
        printf "%b" "${BLUE}3) 备份数据${NC}\n"
        printf "%b" "${BLUE}4) 恢复数据${NC}\n"
        printf "%b" "${BLUE}5) 重启服务${NC}\n"
        printf "%b" "${BLUE}6) 停止服务${NC}\n"
        printf "%b" "${BLUE}7) 启动服务${NC}\n"
        printf "%b" "${BLUE}8) 退出${NC}\n"
        printf "%b" "${BLUE}请选择 [1-8]: ${NC}"
        read -n 1 -r choice
        echo
        
        case $choice in
            1)
                show_existing_info
                exit 0
                ;;
            2)
                print_message $YELLOW "您选择了重新安装"
                printf "%b" "${RED}警告: 这将删除所有现有数据！${NC}\n"
                printf "%b" "${BLUE}是否继续? [y/N]: ${NC}"
                read -n 1 -r confirm
                echo
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    backup_before_reinstall
                    return 0  # 继续重新安装
                else
                    print_message $YELLOW "取消重新安装"
                    exit 0
                fi
                ;;
            3)
                backup_data
                exit 0
                ;;
            4)
                restore_data
                exit 0
                ;;
            5)
                restart_services
                exit 0
                ;;
            6)
                stop_services
                exit 0
                ;;
            7)
                start_services_only
                exit 0
                ;;
            8)
                print_message $YELLOW "退出"
                exit 0
                ;;
            *)
                print_message $RED "无效选择"
                exit 1
                ;;
        esac
    fi
}

# 重新安装前备份
backup_before_reinstall() {
    print_message $YELLOW "正在创建重新安装前的备份..."
    
    cd $PROJECT_DIR
    
    # 检查服务是否运行
    if docker compose ps | grep -q "Up"; then
        print_message $YELLOW "正在备份数据库..."
        BACKUP_FILE="./teslamate_backup_$(date +%Y%m%d_%H%M%S).bck"
        docker compose exec -T database pg_dump -U teslamate teslamate > "$BACKUP_FILE"
        print_message $GREEN "数据库备份完成: $BACKUP_FILE"
        
        # 移动备份文件到安全位置
        BACKUP_DIR="/opt/teslamate_backups"
        mkdir -p "$BACKUP_DIR"
        mv "$BACKUP_FILE" "$BACKUP_DIR/"
        print_message $GREEN "备份文件已移动到: $BACKUP_DIR/$(basename $BACKUP_FILE)"
    fi
    
    # 停止并删除服务
    print_message $YELLOW "正在停止服务..."
    docker compose down -v
    
    # 清理数据目录
    print_message $YELLOW "正在清理数据目录..."
    rm -rf data/
    
    print_message $GREEN "清理完成，准备重新安装"
}

# 备份数据
backup_data() {
    print_title "备份 TeslaMate 数据"
    
    cd $PROJECT_DIR
    
    # 检查服务是否运行
    if ! docker compose ps | grep -q "Up"; then
        print_message $RED "TeslaMate 服务未运行，请先启动服务"
        printf "%b" "${BLUE}是否启动服务? [y/N]: ${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose up -d
            print_message $YELLOW "等待服务启动..."
            sleep 30
        else
            exit 1
        fi
    fi
    
    BACKUP_FILE="teslamate_backup_$(date +%Y%m%d_%H%M%S).bck"
    print_message $YELLOW "正在创建备份: $BACKUP_FILE"
    
    docker compose exec -T database pg_dump -U teslamate teslamate > "$BACKUP_FILE"
    
    # 创建备份目录并移动文件
    BACKUP_DIR="/opt/teslamate_backups"
    mkdir -p "$BACKUP_DIR"
    mv "$BACKUP_FILE" "$BACKUP_DIR/"
    
    print_message $GREEN "备份完成！"
    print_message $CYAN "备份文件位置: $BACKUP_DIR/$BACKUP_FILE"
    print_message $YELLOW "请将备份文件复制到安全的位置保存"
}

# 重启服务
restart_services() {
    print_title "重启 TeslaMate 服务"
    
    PROJECT_DIR="/opt/teslamate"
    
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_message $RED "未找到 TeslaMate 安装"
        exit 1
    fi
    
    cd $PROJECT_DIR
    
    print_message $YELLOW "正在重启所有服务..."
    docker compose restart
    
    print_message $GREEN "服务重启完成！"
    
    # 显示服务状态
    print_message $CYAN "当前服务状态:"
    docker compose ps
}

# 停止服务
stop_services() {
    print_title "停止 TeslaMate 服务"
    
    PROJECT_DIR="/opt/teslamate"
    
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_message $RED "未找到 TeslaMate 安装"
        exit 1
    fi
    
    cd $PROJECT_DIR
    
    print_message $YELLOW "正在停止所有服务..."
    docker compose stop
    
    print_message $GREEN "服务已停止！"
    
    # 显示服务状态
    print_message $CYAN "当前服务状态:"
    docker compose ps
}

# 启动服务（仅启动，不重新安装）
start_services_only() {
    print_title "启动 TeslaMate 服务"
    
    PROJECT_DIR="/opt/teslamate"
    
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_message $RED "未找到 TeslaMate 安装"
        exit 1
    fi
    
    cd $PROJECT_DIR
    
    print_message $YELLOW "正在启动所有服务..."
    docker compose up -d
    
    print_message $GREEN "服务启动完成！"
    
    # 显示服务状态
    print_message $CYAN "当前服务状态:"
    docker compose ps
    
    # 显示访问信息
    source "$PROJECT_DIR/.env"
    echo
    print_message $GREEN "🚗 您可以访问 https://$DOMAIN 使用 TeslaMate！"
}

# 恢复数据
restore_data() {
    print_title "恢复 TeslaMate 数据"
    
    cd $PROJECT_DIR
    
    BACKUP_DIR="/opt/teslamate_backups"
    
    # 列出可用的备份文件
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]]; then
        print_message $RED "未找到备份文件"
        printf "%b" "${BLUE}请输入备份文件的完整路径: ${NC}"
        read BACKUP_FILE
        if [[ ! -f "$BACKUP_FILE" ]]; then
            print_message $RED "备份文件不存在: $BACKUP_FILE"
            exit 1
        fi
    else
        print_message $CYAN "可用的备份文件:"
        ls -la "$BACKUP_DIR"
        echo
        printf "%b" "${BLUE}请输入要恢复的备份文件名: ${NC}"
        read BACKUP_NAME
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"
        
        if [[ ! -f "$BACKUP_FILE" ]]; then
            print_message $RED "备份文件不存在: $BACKUP_FILE"
            exit 1
        fi
    fi
    
    print_message $YELLOW "将要恢复的备份文件: $BACKUP_FILE"
    printf "%b" "${RED}警告: 这将覆盖现有的所有数据！${NC}\n"
    printf "%b" "${BLUE}是否继续? [y/N]: ${NC}"
    read -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message $YELLOW "取消恢复操作"
        exit 0
    fi
    
    # 停止 teslamate 服务
    print_message $YELLOW "正在停止 TeslaMate 服务..."
    docker compose stop teslamate
    
    # 删除现有数据并重新初始化
    print_message $YELLOW "正在重新初始化数据库..."
    docker compose exec -T database psql -U teslamate teslamate << 'SQL'
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
CREATE EXTENSION cube WITH SCHEMA public;
CREATE EXTENSION earthdistance WITH SCHEMA public;
SQL
    
    # 恢复数据
    print_message $YELLOW "正在恢复数据..."
    docker compose exec -T database psql -U teslamate -d teslamate < "$BACKUP_FILE"
    
    # 重启 teslamate 服务
    print_message $YELLOW "正在重启 TeslaMate 服务..."
    docker compose start teslamate
    
    print_message $GREEN "数据恢复完成！"
}

# 收集用户输入
collect_user_input() {
    print_title "配置环境变量"
    
    # 域名配置
    while true; do
        printf "%b" "${BLUE}请输入您的域名 (例如: teslamate.example.com): ${NC}"
        read DOMAIN
        if [[ -n "$DOMAIN" && "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_message $RED "请输入有效的域名格式"
        fi
    done
    
    # 邮箱配置
    while true; do
        printf "%b" "${BLUE}请输入您的邮箱 (用于 SSL 证书申请): ${NC}"
        read EMAIL
        if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_message $RED "请输入有效的邮箱格式"
        fi
    done
    
    # 基础认证配置
    print_message $YELLOW "基础认证配置:"
    printf "%b" "${BLUE}请输入 TeslaMate 用户名 (默认: admin): ${NC}"
    read BASIC_AUTH_USER
    BASIC_AUTH_USER=${BASIC_AUTH_USER:-"admin"}
    printf "%b" "${BLUE}请输入 TeslaMate 密码 (留空自动生成): ${NC}"
    read -s BASIC_AUTH_PASS
    echo
    if [[ -z "$BASIC_AUTH_PASS" ]]; then
        BASIC_AUTH_PASS=$(generate_password 16)
        print_message $GREEN "已自动生成密码: $BASIC_AUTH_PASS"
    fi
    
    # 可选配置
    printf "%b" "${BLUE}请输入时区 (默认: Asia/Shanghai): ${NC}"
    read TIMEZONE
    TIMEZONE=${TIMEZONE:-"Asia/Shanghai"}
    
    # 生成随机密码
    print_message $YELLOW "正在生成安全密码..."
    TM_DB_PASS=$(generate_password 20)
    TM_ENCRYPTION_KEY=$(generate_password 32)
    API_TOKEN=$(generate_password 32)
    GRAFANA_PW=$(generate_password 16)
    
    # 可选的百度地图配置
    print_message $YELLOW "百度地图配置 (可选，用于更精确的位置信息):"
    printf "%b" "${BLUE}百度地图 AK (留空跳过): ${NC}"
    read BD_MAP_AK
    if [[ -n "$BD_MAP_AK" ]]; then
        printf "%b" "${BLUE}百度地图 SK: ${NC}"
        read BD_MAP_SK
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

    cat > docker-compose.yml << 'EOF'
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

# 启动服务
start_services() {
    print_title "启动 TeslaMate 服务"
    
    cd $PROJECT_DIR
    
    # 拉取镜像
    print_message $YELLOW "正在拉取 Docker 镜像..."
    docker compose pull
    
    # 启动服务
    print_message $YELLOW "正在启动服务..."
    docker compose up -d
    
    print_message $GREEN "服务启动完成！"
}

# 等待服务就绪
wait_for_services() {
    print_title "等待服务启动"
    
    print_message $YELLOW "正在等待服务启动..."
    sleep 30
    
    # 检查服务状态
    cd $PROJECT_DIR
    if docker compose ps | grep -q "Up"; then
        print_message $GREEN "服务启动成功！"
    else
        print_message $RED "服务启动可能有问题，请检查日志："
        print_message $YELLOW "docker compose logs"
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

$(print_message $CYAN "🚗 Mytesla UI 登录信息:")
• 访问地址设置：https://$DOMAIN
• 访问令牌: $API_TOKEN

$(print_message $CYAN "🛠️ 常用命令:")
• 查看服务状态: cd $PROJECT_DIR && docker compose ps
• 查看日志: cd $PROJECT_DIR && docker compose logs -f
• 重启服务: cd $PROJECT_DIR && docker compose restart
• 停止服务: cd $PROJECT_DIR && docker compose down

$(print_message $CYAN "💾 备份和恢复命令:")
• 备份数据: $0 --backup
• 恢复数据: $0 --restore
• 手动备份: cd $PROJECT_DIR && docker compose exec -T database pg_dump -U teslamate teslamate > teslamate_backup_\$(date +%Y%m%d_%H%M%S).bck

$(print_message $YELLOW "⚠️ 重要提示:")
1. 请保存好上述登录信息
2. SSL 证书申请需要 2-5 分钟，请耐心等待
3. 首次访问可能需要等待 5-10 分钟服务完全启动
4. 建议定期备份数据，备份文件将保存在 /opt/teslamate_backups/

$(print_message $PURPLE "📱 Mytesla UI推荐:")
• 使用 Mytesla UI 获得更好的使用体验
• 支持实时监控、数据分析、电池健康度查询、峰谷用电自动计费、提醒等功能
• https://portal.mytesla.cc
• https://xhslink.com/m/3iNZ8St7x9J

$(print_message $GREEN "🚗 现在您可以访问 https://$DOMAIN 开始使用 TeslaMate！")
EOF
}

# 显示帮助信息
show_help() {
    cat << EOF
TeslaMate 一键部署脚本

用法:
  $0                安装或重新安装 TeslaMate
  $0 --info         显示安装信息和密码
  $0 --backup       备份现有数据
  $0 --restore      恢复数据
  $0 --restart      重启服务
  $0 --stop         停止服务
  $0 --start        启动服务
  $0 --help         显示此帮助信息

选项:
  --info            显示安装信息、密码和访问地址
  --backup          创建数据库备份
  --restore         从备份恢复数据
  --restart         重启所有服务
  --stop            停止所有服务
  --start           启动所有服务
  --help            显示帮助信息

示例:
  sudo $0                    # 全新安装或管理现有安装
  sudo $0 --info             # 显示密码和访问信息
  sudo $0 --backup           # 备份数据
  sudo $0 --restore          # 恢复数据
  sudo $0 --restart          # 重启服务
  sudo $0 --stop             # 停止服务
  sudo $0 --start            # 启动服务

注意:
  - 脚本需要 root 权限运行
  - 备份文件保存在 /opt/teslamate_backups/
  - 重新安装前会自动创建备份
EOF
}

# 主函数
main() {
    # 处理命令行参数
    case "${1:-}" in
        --info)
            check_root
            show_existing_info
            exit 0
            ;;
        --backup)
            check_root
            backup_data
            exit 0
            ;;
        --restore)
            check_root
            restore_data
            exit 0
            ;;
        --restart)
            check_root
            restart_services
            exit 0
            ;;
        --stop)
            check_root
            stop_services
            exit 0
            ;;
        --start)
            check_root
            start_services_only
            exit 0
            ;;
        --help)
            show_help
            exit 0
            ;;
        "")
            # 正常安装流程
            ;;
        *)
            print_message $RED "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
    
    print_title "TeslaMate 一键部署脚本"
    
    print_message $CYAN "欢迎使用 TeslaMate 一键部署脚本！"
    print_message $YELLOW "本脚本将帮助您在腾讯云服务器上安全部署 TeslaMate"
    echo
    
    # 检查现有安装
    check_existing_installation
    
    # 确认继续
    printf "%b" "${BLUE}是否继续安装? [y/N]: ${NC}"
    read -n 1 -r
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
    start_services
    wait_for_services
    show_deployment_info
    
    print_message $GREEN "🎉 安装完成！感谢使用！"
}

# 错误处理
trap 'print_message $RED "安装过程中出现错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@"