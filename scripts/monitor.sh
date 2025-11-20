#!/bin/bash

###############################################################################
# HTML存储服务 - 监控脚本
#
# 功能: 监控应用状态、资源使用、磁盘空间等
# 使用方法: ./scripts/monitor.sh
###############################################################################

set -e

# 配置
APP_DIR="$HOME/apps/html-storage-service"
APP_NAME="html-storage"
ALERT_EMAIL=""  # 告警邮箱（可选）

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查PM2进程状态
check_pm2_status() {
    log_info "检查PM2进程状态..."

    if ! command -v pm2 &> /dev/null; then
        log_error "PM2未安装"
        return 1
    fi

    if pm2 describe $APP_NAME &> /dev/null; then
        STATUS=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.status")

        if [[ "$STATUS" == "online" ]]; then
            log_success "应用运行正常"

            # 显示详细信息
            UPTIME=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.pm_uptime" | xargs -I {} date -d @$(echo {}/1000 | bc) "+%Y-%m-%d %H:%M:%S")
            RESTART=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .pm2_env.restart_time")
            MEMORY=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.memory" | awk '{printf "%.2f MB", $1/1024/1024}')
            CPU=$(pm2 jlist | jq -r ".[] | select(.name==\"$APP_NAME\") | .monit.cpu")

            echo "  - 启动时间: $UPTIME"
            echo "  - 重启次数: $RESTART"
            echo "  - 内存使用: $MEMORY"
            echo "  - CPU使用: ${CPU}%"
        else
            log_error "应用状态异常: $STATUS"
            return 1
        fi
    else
        log_error "应用未运行"
        return 1
    fi
}

# 检查端口监听
check_port() {
    log_info "检查端口监听..."

    PORT=3000
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        log_success "端口 $PORT 正在监听"
    else
        log_error "端口 $PORT 未监听"
        return 1
    fi
}

# 检查HTTP响应
check_http() {
    log_info "检查HTTP响应..."

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")

    if [[ "$HTTP_CODE" == "200" ]]; then
        log_success "HTTP响应正常 (200)"
    else
        log_error "HTTP响应异常 ($HTTP_CODE)"
        return 1
    fi
}

# 检查磁盘空间
check_disk() {
    log_info "检查磁盘空间..."

    DISK_USAGE=$(df -h / | tail -n 1 | awk '{print $5}' | sed 's/%//')

    if [[ $DISK_USAGE -lt 80 ]]; then
        log_success "磁盘使用率: ${DISK_USAGE}%"
    elif [[ $DISK_USAGE -lt 90 ]]; then
        log_warning "磁盘使用率较高: ${DISK_USAGE}%"
    else
        log_error "磁盘空间严重不足: ${DISK_USAGE}%"
        return 1
    fi
}

# 检查内存使用
check_memory() {
    log_info "检查内存使用..."

    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

    if [[ $MEMORY_USAGE -lt 80 ]]; then
        log_success "内存使用率: ${MEMORY_USAGE}%"
    elif [[ $MEMORY_USAGE -lt 90 ]]; then
        log_warning "内存使用率较高: ${MEMORY_USAGE}%"
    else
        log_error "内存使用率严重过高: ${MEMORY_USAGE}%"
    fi
}

# 检查Nginx状态
check_nginx() {
    log_info "检查Nginx状态..."

    if command -v nginx &> /dev/null; then
        if systemctl is-active --quiet nginx; then
            log_success "Nginx运行正常"
        else
            log_error "Nginx未运行"
            return 1
        fi
    else
        log_warning "Nginx未安装"
    fi
}

# 检查文件数量
check_files() {
    log_info "检查HTML文件..."

    STORAGE_DIR="$APP_DIR/html_storage"

    if [[ -d $STORAGE_DIR ]]; then
        FILE_COUNT=$(find $STORAGE_DIR -name "*.html" | wc -l)
        STORAGE_SIZE=$(du -sh $STORAGE_DIR | cut -f1)

        log_info "  - 文件数量: $FILE_COUNT"
        log_info "  - 存储大小: $STORAGE_SIZE"
    else
        log_warning "存储目录不存在"
    fi
}

# 检查日志错误
check_errors() {
    log_info "检查最近的错误日志..."

    LOG_FILE="$APP_DIR/logs/error.log"

    if [[ -f $LOG_FILE ]]; then
        ERROR_COUNT=$(tail -n 100 $LOG_FILE 2>/dev/null | grep -i "error" | wc -l)

        if [[ $ERROR_COUNT -eq 0 ]]; then
            log_success "未发现错误"
        else
            log_warning "发现 $ERROR_COUNT 条错误"
            echo "最近的错误:"
            tail -n 100 $LOG_FILE | grep -i "error" | tail -n 5
        fi
    else
        log_info "错误日志文件不存在"
    fi
}

# 生成报告
generate_report() {
    echo ""
    echo "=========================================="
    echo "   监控报告"
    echo "=========================================="
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

# 主程序
main() {
    generate_report

    ERRORS=0

    check_pm2_status || ((ERRORS++))
    echo ""

    check_port || ((ERRORS++))
    echo ""

    check_http || ((ERRORS++))
    echo ""

    check_disk || ((ERRORS++))
    echo ""

    check_memory
    echo ""

    check_nginx || ((ERRORS++))
    echo ""

    check_files
    echo ""

    check_errors
    echo ""

    echo "=========================================="
    if [[ $ERRORS -eq 0 ]]; then
        log_success "所有检查通过 ✓"
        exit 0
    else
        log_error "发现 $ERRORS 个问题 ✗"
        exit 1
    fi
}

main "$@"
