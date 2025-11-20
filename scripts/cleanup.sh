#!/bin/bash

###############################################################################
# HTML存储服务 - 清理脚本
#
# 功能: 清理过期的HTML文件和日志
# 使用方法: ./scripts/cleanup.sh
# 定时任务: 0 2 * * * /path/to/cleanup.sh
###############################################################################

set -e

# 配置
APP_DIR="$HOME/apps/html-storage-service"
STORAGE_DIR="$APP_DIR/html_storage"
LOG_DIR="$APP_DIR/logs"
HTML_RETENTION_DAYS=30  # HTML文件保留天数
LOG_RETENTION_DAYS=7    # 日志保留天数

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warning() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 清理HTML文件
cleanup_html() {
    log_info "清理${HTML_RETENTION_DAYS}天前的HTML文件..."

    if [[ ! -d $STORAGE_DIR ]]; then
        log_warning "存储目录不存在: $STORAGE_DIR"
        return
    fi

    BEFORE_COUNT=$(find $STORAGE_DIR -name "*.html" | wc -l)
    BEFORE_SIZE=$(du -sh $STORAGE_DIR 2>/dev/null | cut -f1 || echo "0")

    # 删除旧文件
    find $STORAGE_DIR -name "*.html" -mtime +$HTML_RETENTION_DAYS -delete

    AFTER_COUNT=$(find $STORAGE_DIR -name "*.html" | wc -l)
    AFTER_SIZE=$(du -sh $STORAGE_DIR 2>/dev/null | cut -f1 || echo "0")
    DELETED_COUNT=$((BEFORE_COUNT - AFTER_COUNT))

    log_success "HTML文件清理完成"
    log_info "  删除文件: $DELETED_COUNT"
    log_info "  剩余文件: $AFTER_COUNT"
    log_info "  磁盘空间: $BEFORE_SIZE -> $AFTER_SIZE"
}

# 清理日志文件
cleanup_logs() {
    log_info "清理${LOG_RETENTION_DAYS}天前的日志文件..."

    if [[ ! -d $LOG_DIR ]]; then
        log_warning "日志目录不存在: $LOG_DIR"
        return
    fi

    BEFORE_SIZE=$(du -sh $LOG_DIR 2>/dev/null | cut -f1 || echo "0")

    # 删除旧日志
    find $LOG_DIR -name "*.log" -mtime +$LOG_RETENTION_DAYS -delete

    AFTER_SIZE=$(du -sh $LOG_DIR 2>/dev/null | cut -f1 || echo "0")

    log_success "日志清理完成"
    log_info "  磁盘空间: $BEFORE_SIZE -> $AFTER_SIZE"
}

# 清理PM2日志
cleanup_pm2_logs() {
    log_info "清理PM2日志..."

    if command -v pm2 &> /dev/null; then
        pm2 flush
        log_success "PM2日志已清理"
    else
        log_warning "PM2未安装"
    fi
}

# 显示磁盘使用情况
show_disk_usage() {
    log_info "磁盘使用情况:"
    df -h / | tail -n 1 | awk '{print "  总空间: "$2", 已用: "$3", 可用: "$4", 使用率: "$5}'
}

# 主程序
main() {
    log_info "=========================================="
    log_info "开始清理任务"
    log_info "=========================================="

    show_disk_usage
    cleanup_html
    cleanup_logs
    cleanup_pm2_logs
    show_disk_usage

    log_success "=========================================="
    log_success "清理任务完成"
    log_success "=========================================="
}

main "$@"
