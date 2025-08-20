#!/bin/bash

# TeslaMate 自动化部署脚本
# 支持海外API访问的安全部署方案

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        print_info "请使用: sudo $0"
        exit 1
    fi
}

# 生成随机密码
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${GREEN}"
    echo "=================================================="
    echo "     TeslaMate 安全部署脚本 v1.0"
    echo "     支持overseas代理的一键部署方案"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    print_info "本脚本将帮助您："
    echo "  1. 安装Docker环境"
    echo "  2. 配置SSL证书（自动续期）"
    echo "  3. 部署TeslaMate及相关组件"
    echo "  4. 配置overseas代理支持"
    echo "  5. 生成安全的访问凭证"
    echo ""
    read -p "按Enter键继续安装..."
}

# 收集用户输入
collect_user_input() {
    echo ""
    print_info "请提供以下信息用于配置："
    echo ""
    
    # 邮箱
    while true; do
        read -p "请输入您的邮箱地址（用于SSL证书）: " USER_EMAIL
        if [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "邮箱格式不正确，请重新输入"
        fi
    done
    
    # 域名
    while true; do
        read -p "请输入您的域名（如: teslamate.example.com）: " DOMAIN
        if [[ "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "域名格式不正确，请重新输入"
        fi
    done
    
    # 时区
    read -p "请输入时区（默认: Asia/Shanghai）: " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Shanghai}
    
    # overseas代理配置
    echo ""
    print_info "配置overseas代理（用于访问特斯拉API）"
    read -p "是否需要配置overseas代理？[Y/n]: " USE_PROXY
    USE_PROXY=${USE_PROXY:-Y}
    
    if [[ "$USE_PROXY" =~ ^[Yy]$ ]]; then
        read -p "请输入代理地址（默认: socks5://127.0.0.1:1080）: " PROXY_URL
        PROXY_URL=${PROXY_URL:-socks5://127.0.0.1:1080}
    fi
    
    # 生成密码
    print_info "生成安全密码..."
    DB_PASSWORD=$(generate_password)
    GRAFANA_PASSWORD=$(generate_password)
    WEB_PASSWORD=$(generate_password)
    ENCRYPTION_KEY=$(generate_password)
    
    # 显示配置信息
    echo ""
    print_info "配置信息确认："
    echo "  邮箱: $USER_EMAIL"
    echo "  域名: $DOMAIN"
    echo "  时区: $TIMEZONE"
    if [[ "$USE_PROXY" =~ ^[Yy]$ ]]; then
        echo "  代理: $PROXY_URL"
    fi
    echo ""
    read -p "确认以上信息正确？[Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-Y}
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_error "安装已取消"
        exit 1
    fi
}

# 安装Docker
install_docker() {
    print_info "检查Docker安装状态..."
    
    if command -v docker &> /dev/null; then
        print_success "Docker已安装"
        return
    fi
    
    print_info "安装Docker..."
    bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
    
    # 启动Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    print_info "检查Docker Compose安装状态..."
    
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose已安装"
        return
    fi
    
    print_info "安装Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose安装完成"
}

# 创建目录结构
create_directories() {
    print_info "创建目录结构..."
    
    mkdir -p /opt/teslamate/{import,grafana/dashboards,postgres}
    mkdir -p /opt/teslamate/nginx/{conf.d,ssl}
    
    print_success "目录创建完成"
}

# 创建docker-compose配置
create_docker_compose() {
    print_info "创建docker-compose配置..."
    
    cat > /opt/teslamate/docker-compose.yml << EOF
version: '3.8'

services:
  database:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_USER=teslamate
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=teslamate
    volumes:
      - ./postgres:/var/lib/postgresql/data
    networks:
      - teslamate

  teslamate:
    image: teslamate/teslamate:latest
    restart: always
    depends_on:
      - database
    environment:
      - ENCRYPTION_KEY=${ENCRYPTION_KEY}
      - DATABASE_USER=teslamate
      - DATABASE_PASS=${DB_PASSWORD}
      - DATABASE_NAME=teslamate
      - DATABASE_HOST=database
      - MQTT_HOST=mosquitto
      - VIRTUAL_HOST=${DOMAIN}
      - CHECK_ORIGIN=true
      - TZ=${TIMEZONE}
EOF

    # 添加代理配置
    if [[ "$USE_PROXY" =~ ^[Yy]$ ]]; then
        cat >> /opt/teslamate/docker-compose.yml << EOF
      - HTTP_PROXY=${PROXY_URL}
      - HTTPS_PROXY=${PROXY_URL}
      - NO_PROXY=localhost,127.0.0.1,database,grafana,mosquitto
EOF
    fi

    cat >> /opt/teslamate/docker-compose.yml << EOF
    ports:
      - 4000:4000
    volumes:
      - ./import:/opt/app/import
    networks:
      - teslamate
    cap_drop:
      - all

  grafana:
    image: teslamate/grafana:latest
    restart: always
    environment:
      - DATABASE_USER=teslamate
      - DATABASE_PASS=${DB_PASSWORD}
      - DATABASE_NAME=teslamate
      - DATABASE_HOST=database
      - GRAFANA_PASSWD=${GRAFANA_PASSWORD}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_SECURITY_ADMIN_USER=admin
      - GF_AUTH_BASIC_ENABLED=true
      - GF_SECURITY_DISABLE_GRAVATAR=true
      - GF_SECURITY_ALLOW_EMBEDDING=false
      - TZ=${TIMEZONE}
    ports:
      - 3000:3000
    volumes:
      - teslamate-grafana-data:/var/lib/grafana
    networks:
      - teslamate

  mosquitto:
    image: eclipse-mosquitto:2
    restart: always
    ports:
      - 1883:1883
    volumes:
      - mosquitto-conf:/mosquitto/config
      - mosquitto-data:/mosquitto/data
    networks:
      - teslamate

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
      - ./nginx/auth:/etc/nginx/auth
    depends_on:
      - teslamate
      - grafana
    networks:
      - teslamate

networks:
  teslamate:

volumes:
  teslamate-grafana-data:
  mosquitto-conf:
  mosquitto-data:
EOF

    print_success "docker-compose配置创建完成"
}

# 创建Nginx配置
create_nginx_config() {
    print_info "创建Nginx配置..."
    
    # 生成htpasswd文件
    echo -n 'admin:' > /opt/teslamate/nginx/auth/.htpasswd
    openssl passwd -apr1 "$WEB_PASSWORD" >> /opt/teslamate/nginx/auth/.htpasswd
    
    cat > /opt/teslamate/nginx/conf.d/teslamate.conf << EOF
upstream teslamate {
    server teslamate:4000;
}

upstream grafana {
    server grafana:3000;
}

server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # TeslaMate
    location / {
        proxy_pass http://teslamate;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # 基础认证
        auth_basic "TeslaMate";
        auth_basic_user_file /etc/nginx/auth/.htpasswd;
    }

    # Grafana
    location /grafana/ {
        proxy_pass http://grafana/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    print_success "Nginx配置创建完成"
}

# 配置SSL证书
setup_ssl() {
    print_info "配置SSL证书..."
    
    # 安装certbot
    apt-get update
    apt-get install -y certbot
    
    # 停止可能占用80端口的服务
    systemctl stop nginx 2>/dev/null || true
    systemctl stop apache2 2>/dev/null || true
    
    # 获取证书
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email "$USER_EMAIL" \
        -d "$DOMAIN"
    
    # 复制证书
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/teslamate/nginx/ssl/
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/teslamate/nginx/ssl/
    chmod 644 /opt/teslamate/nginx/ssl/*
    
    # 设置自动续期
    cat > /etc/cron.d/certbot-renew << EOF
0 2 * * * root certbot renew --quiet --post-hook "cp /etc/letsencrypt/live/$DOMAIN/*.pem /opt/teslamate/nginx/ssl/ && docker-compose -f /opt/teslamate/docker-compose.yml restart nginx"
EOF
    
    print_success "SSL证书配置完成"
}

# 启动服务
start_services() {
    print_info "启动服务..."
    
    cd /opt/teslamate
    docker-compose up -d
    
    # 等待服务启动
    print_info "等待服务启动..."
    sleep 30
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        print_success "所有服务启动成功"
    else
        print_error "部分服务启动失败，请检查日志"
        docker-compose logs
    fi
}

# 显示安装信息
show_installation_info() {
    echo ""
    echo -e "${GREEN}=================================================="
    echo "     TeslaMate 安装完成！"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    print_success "访问信息："
    echo ""
    echo "TeslaMate 主界面:"
    echo "  地址: https://${DOMAIN}"
    echo "  用户名: admin"
    echo "  密码: ${WEB_PASSWORD}"
    echo ""
    echo "Grafana 数据面板:"
    echo "  地址: https://${DOMAIN}/grafana"
    echo "  用户名: admin"
    echo "  密码: ${GRAFANA_PASSWORD}"
    echo ""
    print_warning "请妥善保存以上信息！"
    echo ""
    echo -e "${BLUE}=================================================="
    echo "     MyTesla - 您的特斯拉好帮手"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    echo "MyTesla 是一款功能强大的特斯拉第三方应用："
    echo ""
    echo "  🚗 实时查看车辆状态"
    echo "  🔒 远程控制车辆"
    echo "  📊 详细的数据统计"
    echo "  🗺️ 位置追踪和轨迹回放"
    echo "  ⚡ 智能充电管理"
    echo "  🔔 贴心的提醒功能"
    echo ""
    echo "立即下载 MyTesla，开启智能用车新体验！"
    echo ""
    echo "  iOS: App Store 搜索 'MyTesla'"
    echo "  Android: Google Play 搜索 'MyTesla'"
    echo ""
    print_info "配置文件位置: /opt/teslamate/"
    print_info "查看日志: cd /opt/teslamate && docker-compose logs -f"
    echo ""
}

# 主函数
main() {
    check_root
    show_welcome
    collect_user_input
    install_docker
    install_docker_compose
    create_directories
    create_docker_compose
    create_nginx_config
    setup_ssl
    start_services
    show_installation_info
}

# 运行主函数
main