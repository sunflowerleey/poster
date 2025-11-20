#!/bin/bash

###############################################################################
# HTML存储服务 - 备份脚本
#
# 功能: 备份HTML文件到指定目录
# 使用方法: ./scripts/backup.sh
# 定时任务: 0 3 * * * /path/to/backup.sh
###############################################################################

set -e

# 配置
APP_DIR="$HOME/apps/html-storage-service"
BACKUP_ROOT="/backup/html-storage"
STORAGE_DIR="$APP_DIR/html_storage"
RETENTION_DAYS=30  # 保留天数

# 日期
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/backup_$DATE"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 创建备份目录
mkdir -p $BACKUP_ROOT

log_info "开始备份..."

# 备份HTML文件
if [[ -d $STORAGE_DIR ]]; then
    FILE_COUNT=$(find $STORAGE_DIR -name "*.html" | wc -l)
    STORAGE_SIZE=$(du -sh $STORAGE_DIR | cut -f1)

    log_info "文件数量: $FILE_COUNT"
    log_info "存储大小: $STORAGE_SIZE"

    # 创建压缩备份
    tar -czf "${BACKUP_DIR}.tar.gz" -C $(dirname $STORAGE_DIR) $(basename $STORAGE_DIR)

    BACKUP_SIZE=$(du -sh "${BACKUP_DIR}.tar.gz" | cut -f1)
    log_success "备份完成: ${BACKUP_DIR}.tar.gz ($BACKUP_SIZE)"
else
    log_info "存储目录不存在，跳过备份"
    exit 0
fi

# 清理旧备份
log_info "清理${RETENTION_DAYS}天前的备份..."
find $BACKUP_ROOT -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

REMAINING_BACKUPS=$(find $BACKUP_ROOT -name "backup_*.tar.gz" | wc -l)
log_success "当前备份数量: $REMAINING_BACKUPS"

log_success "备份任务完成"
