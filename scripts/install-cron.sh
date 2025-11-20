#!/bin/bash

###############################################################################
# HTML存储服务 - 安装定时任务
#
# 功能: 自动配置crontab定时任务
# 使用方法: ./scripts/install-cron.sh
###############################################################################

set -e

APP_DIR="$HOME/apps/html-storage-service"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_info "配置定时任务..."

# 确保脚本有执行权限
chmod +x $APP_DIR/scripts/*.sh

# 备份现有的crontab
crontab -l > /tmp/crontab.bak 2>/dev/null || true

# 删除旧的相关任务
crontab -l 2>/dev/null | grep -v "html-storage" > /tmp/crontab.new || true

# 添加新任务
cat >> /tmp/crontab.new << EOF

# HTML存储服务定时任务
# 每天凌晨2点执行清理任务
0 2 * * * $APP_DIR/scripts/cleanup.sh >> $APP_DIR/logs/cleanup.log 2>&1

# 每天凌晨3点执行备份任务
0 3 * * * $APP_DIR/scripts/backup.sh >> $APP_DIR/logs/backup.log 2>&1

# 每5分钟执行一次监控（可选）
# */5 * * * * $APP_DIR/scripts/monitor.sh >> $APP_DIR/logs/monitor.log 2>&1

EOF

# 安装新的crontab
crontab /tmp/crontab.new

log_success "定时任务配置完成"
echo ""
echo "已配置的任务:"
crontab -l | grep "html-storage" -A 3

echo ""
log_info "查看定时任务: crontab -l"
log_info "编辑定时任务: crontab -e"
log_info "查看日志: tail -f $APP_DIR/logs/cleanup.log"
