#!/bin/bash

# TeslaMate 管理脚本
# 快速管理 TeslaMate 服务和查看信息

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="/opt/teslamate"

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

# 检查安装
check_installation() {
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        print_message $RED "错误: 未找到 TeslaMate 安装"
        print_message $YELLOW "请先运行安装脚本进行安装"
        exit 1
    fi
}

# 显示安装信息和密码
show_info() {
    check_installation
    
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

$(print_message $PURPLE "📱 Mytesla UI推荐:")
• 使用 Mytesla UI 获得更好的使用体验
• 支持实时监控、数据分析、电池健康度查询、峰谷用电自动计费、提醒等功能
• https://portal.mytesla.cc
• https://xhslink.com/m/3iNZ8St7x9J

$(print_message $GREEN "🚗 现在您可以访问 https://$DOMAIN 开始使用 TeslaMate！")
EOF
}

# 显示服务状态
show_status() {
    check_installation
    
    print_title "TeslaMate 服务状态"
    
    cd $PROJECT_DIR
    docker compose ps
    
    echo
    print_message $CYAN "如需查看详细日志，请运行："
    print_message $YELLOW "cd $PROJECT_DIR && docker compose logs -f"
}

# 重启服务
restart_services() {
    check_installation
    
    print_title "重启 TeslaMate 服务"
    
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
    check_installation
    
    print_title "停止 TeslaMate 服务"
    
    cd $PROJECT_DIR
    
    print_message $YELLOW "正在停止所有服务..."
    docker compose stop
    
    print_message $GREEN "服务已停止！"
    
    # 显示服务状态
    print_message $CYAN "当前服务状态:"
    docker compose ps
}

# 启动服务
start_services() {
    check_installation
    
    print_title "启动 TeslaMate 服务"
    
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

# 查看日志
show_logs() {
    check_installation
    
    print_title "TeslaMate 服务日志"
    
    cd $PROJECT_DIR
    
    print_message $CYAN "选择要查看的服务日志:"
    print_message $BLUE "1) 所有服务"
    print_message $BLUE "2) TeslaMate"
    print_message $BLUE "3) Grafana"
    print_message $BLUE "4) 数据库"
    print_message $BLUE "5) Traefik"
    printf "%b" "${BLUE}请选择 [1-5]: ${NC}"
    read -n 1 -r choice
    echo
    
    case $choice in
        1)
            print_message $YELLOW "显示所有服务日志 (按 Ctrl+C 退出):"
            docker compose logs -f
            ;;
        2)
            print_message $YELLOW "显示 TeslaMate 日志 (按 Ctrl+C 退出):"
            docker compose logs -f teslamate
            ;;
        3)
            print_message $YELLOW "显示 Grafana 日志 (按 Ctrl+C 退出):"
            docker compose logs -f grafana
            ;;
        4)
            print_message $YELLOW "显示数据库日志 (按 Ctrl+C 退出):"
            docker compose logs -f database
            ;;
        5)
            print_message $YELLOW "显示 Traefik 日志 (按 Ctrl+C 退出):"
            docker compose logs -f traefik
            ;;
        *)
            print_message $RED "无效选择"
            exit 1
            ;;
    esac
}

# 显示菜单
show_menu() {
    print_title "TeslaMate 管理菜单"
    
    printf "%b" "${BLUE}选择操作:${NC}\n"
    printf "%b" "${BLUE}1) 显示安装信息和密码${NC}\n"
    printf "%b" "${BLUE}2) 查看服务状态${NC}\n"
    printf "%b" "${BLUE}3) 启动服务${NC}\n"
    printf "%b" "${BLUE}4) 停止服务${NC}\n"
    printf "%b" "${BLUE}5) 重启服务${NC}\n"
    printf "%b" "${BLUE}6) 查看日志${NC}\n"
    printf "%b" "${BLUE}7) 退出${NC}\n"
    printf "%b" "${BLUE}请选择 [1-7]: ${NC}"
    read -n 1 -r choice
    echo
    
    case $choice in
        1)
            show_info
            ;;
        2)
            show_status
            ;;
        3)
            start_services
            ;;
        4)
            stop_services
            ;;
        5)
            restart_services
            ;;
        6)
            show_logs
            ;;
        7)
            print_message $YELLOW "退出管理器"
            exit 0
            ;;
        *)
            print_message $RED "无效选择"
            exit 1
            ;;
    esac
}

# 显示帮助信息
show_help() {
    cat << EOF
TeslaMate 管理脚本

用法:
  $0                显示交互式菜单
  $0 info           显示安装信息和密码
  $0 status         查看服务状态
  $0 start          启动服务
  $0 stop           停止服务
  $0 restart        重启服务
  $0 logs           查看日志
  $0 help           显示此帮助信息

示例:
  $0                # 显示交互式菜单
  $0 info           # 快速查看密码和访问信息
  $0 restart        # 快速重启服务
  $0 logs           # 查看服务日志
EOF
}

# 主函数
main() {
    case "${1:-}" in
        info)
            show_info
            ;;
        status)
            show_status
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        logs)
            show_logs
            ;;
        help)
            show_help
            ;;
        "")
            show_menu
            ;;
        *)
            print_message $RED "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"