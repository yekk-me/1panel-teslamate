#!/bin/bash

# TeslaMate 简化部署脚本（无nginx版本）
# 支持 overseas 应用访问

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
    echo "     TeslaMate 简化部署脚本 v2.0"
    echo "     支持 overseas 应用的配置方案"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    print_info "本脚本将帮助您："
    echo "  1. 安装Docker环境"
    echo "  2. 部署TeslaMate及相关组件"
    echo "  3. 生成安全的访问凭证"
    echo ""
    read -p "按Enter键继续安装..."
}

# 收集用户输入
collect_user_input() {
    echo ""
    print_info "请提供以下信息用于配置："
    echo ""
    
    # 时区
    read -p "请输入时区（默认: Asia/Shanghai）: " TIMEZONE
    TIMEZONE=${TIMEZONE:-Asia/Shanghai}
    
    # 生成密码
    print_info "生成安全密码..."
    DB_PASSWORD=$(generate_password)
    GRAFANA_PASSWORD=$(generate_password)
    ENCRYPTION_KEY=$(generate_password)
    
    # 显示配置信息
    echo ""
    print_info "配置信息确认："
    echo "  时区: $TIMEZONE"
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
    
    mkdir -p /opt/teslamate/{import,grafana-data,postgres-data}
    
    print_success "目录创建完成"
}

# 创建docker-compose配置
create_docker_compose() {
    print_info "创建docker-compose配置..."
    
    cat > /opt/teslamate/docker-compose.yml << EOF
version: "3"

services:
  database:
    image: postgres:15
    restart: always
    environment:
      - POSTGRES_USER=teslamate
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=teslamate
    volumes:
      - ./postgres-data:/var/lib/postgresql/data

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
      - CHECK_ORIGIN=false
      - TZ=${TIMEZONE}
    ports:
      - 4000:4000
    volumes:
      - ./import:/opt/app/import
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
      - GF_AUTH_ANONYMOUS_ENABLED=false
      - GF_SERVER_ROOT_URL=%(protocol)s://%(domain)s:%(http_port)s/
      - TZ=${TIMEZONE}
    ports:
      - 3000:3000
    volumes:
      - ./grafana-data:/var/lib/grafana

  mosquitto:
    image: eclipse-mosquitto:2
    restart: always
    command: mosquitto -c /mosquitto-no-auth.conf
    volumes:
      - mosquitto-conf:/mosquitto/config
      - mosquitto-data:/mosquitto/data

volumes:
  mosquitto-conf:
  mosquitto-data:
EOF

    print_success "docker-compose配置创建完成"
}

# 配置防火墙
configure_firewall() {
    print_info "配置防火墙..."
    
    # 检查是否安装了ufw
    if command -v ufw &> /dev/null; then
        ufw allow 4000/tcp comment 'TeslaMate'
        ufw allow 3000/tcp comment 'Grafana'
        print_success "防火墙规则已添加"
    else
        print_warning "未检测到ufw防火墙，请手动配置以下端口："
        echo "  - 4000 (TeslaMate)"
        echo "  - 3000 (Grafana)"
    fi
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
    # 获取服务器IP
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}=================================================="
    echo "     TeslaMate 安装完成！"
    echo "=================================================="
    echo -e "${NC}"
    echo ""
    print_success "访问信息："
    echo ""
    echo "TeslaMate 主界面:"
    echo "  地址: http://${SERVER_IP}:4000"
    echo "  首次访问需要配置Tesla账号"
    echo ""
    echo "Grafana 数据面板:"
    echo "  地址: http://${SERVER_IP}:3000"
    echo "  用户名: admin"
    echo "  密码: ${GRAFANA_PASSWORD}"
    echo ""
    print_warning "请妥善保存以上信息！"
    echo ""
    print_info "安全提示："
    echo "  1. 建议通过overseas应用访问，确保连接稳定"
    echo "  2. 请及时修改默认密码"
    echo "  3. 定期备份数据库"
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
    print_info "重要文件位置："
    echo "  配置文件: /opt/teslamate/docker-compose.yml"
    echo "  数据目录: /opt/teslamate/"
    echo ""
    print_info "常用命令："
    echo "  查看日志: cd /opt/teslamate && docker-compose logs -f"
    echo "  重启服务: cd /opt/teslamate && docker-compose restart"
    echo "  更新服务: cd /opt/teslamate && docker-compose pull && docker-compose up -d"
    echo "  备份数据: cd /opt/teslamate && docker-compose exec database pg_dump -U teslamate teslamate > backup.sql"
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
    configure_firewall
    start_services
    show_installation_info
}

# 运行主函数
main