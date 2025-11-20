#!/bin/bash

###############################################################################
# HTML存储服务 - 自动化部署脚本
#
# 功能: 一键部署HTML存储服务到Ubuntu/Debian服务器
# 使用方法:
#   chmod +x deploy.sh
#   ./deploy.sh
#
# 支持的系统: Ubuntu 20.04+, Debian 10+
###############################################################################

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 配置变量
APP_NAME="html-storage"
APP_DIR="$HOME/apps/html-storage-service"
NODE_VERSION="18"
DOMAIN=""

###############################################################################
# 函数定义
###############################################################################

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "建议不要使用root用户运行此脚本"
        read -p "是否继续? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 检查操作系统
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        log_info "检测到操作系统: $OS $VER"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
}

# 安装Node.js
install_nodejs() {
    log_info "检查Node.js安装..."

    if command -v node &> /dev/null; then
        CURRENT_NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $CURRENT_NODE_VERSION -ge $NODE_VERSION ]]; then
            log_success "Node.js已安装: $(node -v)"
            return 0
        fi
    fi

    log_info "安装Node.js $NODE_VERSION..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt-get install -y nodejs

    log_success "Node.js安装完成: $(node -v)"
}

# 安装PM2
install_pm2() {
    log_info "检查PM2安装..."

    if command -v pm2 &> /dev/null; then
        log_success "PM2已安装: $(pm2 -v)"
        return 0
    fi

    log_info "安装PM2..."
    sudo npm install -g pm2
    log_success "PM2安装完成"
}

# 安装Nginx
install_nginx() {
    log_info "检查Nginx安装..."

    if command -v nginx &> /dev/null; then
        log_success "Nginx已安装: $(nginx -v 2>&1 | cut -d'/' -f2)"
        return 0
    fi

    log_info "安装Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    log_success "Nginx安装完成"
}

# 部署应用
deploy_app() {
    log_info "部署应用..."

    # 创建应用目录
    mkdir -p $(dirname $APP_DIR)

    # 如果目录已存在，备份
    if [[ -d $APP_DIR ]]; then
        log_warning "应用目录已存在，创建备份..."
        BACKUP_DIR="${APP_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        mv $APP_DIR $BACKUP_DIR
        log_info "备份创建于: $BACKUP_DIR"
    fi

    # 克隆或复制代码
    if [[ -d .git ]]; then
        log_info "复制当前目录到应用目录..."
        cp -r . $APP_DIR
    else
        log_error "请在项目根目录下运行此脚本"
        exit 1
    fi

    cd $APP_DIR

    # 安装依赖
    log_info "安装Node.js依赖..."
    npm install --production

    # 创建必要的目录
    mkdir -p html_storage logs

    log_success "应用部署完成"
}

# 配置PM2
configure_pm2() {
    log_info "配置PM2..."

    cd $APP_DIR

    # 停止旧的进程
    pm2 delete $APP_NAME 2>/dev/null || true

    # 启动应用
    if [[ -f ecosystem.config.js ]]; then
        pm2 start ecosystem.config.js --env production
    else
        pm2 start server.js --name $APP_NAME
    fi

    # 保存PM2配置
    pm2 save

    # 设置开机自启
    sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $USER --hp $HOME

    log_success "PM2配置完成"
}

# 配置Nginx
configure_nginx() {
    log_info "配置Nginx..."

    # 询问域名
    read -p "请输入域名（留空使用服务器IP）: " DOMAIN

    if [[ -z "$DOMAIN" ]]; then
        DOMAIN=$(curl -s ifconfig.me)
        log_info "使用服务器IP: $DOMAIN"
    fi

    # 创建Nginx配置
    NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"

    sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    # 启用配置
    sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/

    # 删除默认配置
    sudo rm -f /etc/nginx/sites-enabled/default

    # 测试配置
    sudo nginx -t

    # 重启Nginx
    sudo systemctl reload nginx

    log_success "Nginx配置完成"
}

# 配置防火墙
configure_firewall() {
    log_info "配置防火墙..."

    if command -v ufw &> /dev/null; then
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw --force enable
        log_success "UFW防火墙配置完成"
    else
        log_warning "未检测到UFW防火墙"
    fi
}

# 安装SSL证书（可选）
install_ssl() {
    if [[ -z "$DOMAIN" ]] || [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_warning "跳过SSL配置（需要域名）"
        return 0
    fi

    read -p "是否安装SSL证书（Let's Encrypt）? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi

    log_info "安装Certbot..."
    sudo apt-get install -y certbot python3-certbot-nginx

    log_info "获取SSL证书..."
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email

    log_success "SSL证书安装完成"
}

# 显示部署信息
show_info() {
    echo ""
    echo "=========================================="
    echo "   部署完成！"
    echo "=========================================="
    echo ""
    echo "应用信息:"
    echo "  - 应用目录: $APP_DIR"
    echo "  - 访问地址: http://$DOMAIN"
    echo ""
    echo "常用命令:"
    echo "  - 查看状态: pm2 status"
    echo "  - 查看日志: pm2 logs $APP_NAME"
    echo "  - 重启应用: pm2 restart $APP_NAME"
    echo "  - 停止应用: pm2 stop $APP_NAME"
    echo ""
    echo "Nginx:"
    echo "  - 配置文件: /etc/nginx/sites-available/$APP_NAME"
    echo "  - 重启Nginx: sudo systemctl reload nginx"
    echo "  - 查看日志: sudo tail -f /var/log/nginx/access.log"
    echo ""
    echo "测试API:"
    echo "  curl -X POST http://$DOMAIN/api/save-html \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -d '{\"html\":\"<html><body>Hello</body></html>\"}'"
    echo ""
    echo "=========================================="
}

###############################################################################
# 主程序
###############################################################################

main() {
    echo "=========================================="
    echo "   HTML存储服务 - 自动化部署"
    echo "=========================================="
    echo ""

    # 检查
    check_root
    check_os

    # 安装依赖
    install_nodejs
    install_pm2
    install_nginx

    # 部署应用
    deploy_app
    configure_pm2
    configure_nginx
    configure_firewall

    # 可选的SSL
    install_ssl

    # 显示信息
    show_info

    log_success "部署完成！"
}

# 运行主程序
main "$@"
