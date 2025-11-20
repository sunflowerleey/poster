#!/bin/bash

###############################################################################
# HTML存储服务 - 更新脚本
#
# 功能: 更新应用代码并重启服务
# 使用方法: ./scripts/update.sh [branch]
###############################################################################

set -e

# 配置
APP_DIR="$HOME/apps/html-storage-service"
APP_NAME="html-storage"
BRANCH="${1:-claude/html-storage-service-01KSAKPzzhk4rrUS6S1GSVPN}"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 切换到应用目录
cd $APP_DIR

log_info "=========================================="
log_info "开始更新应用"
log_info "=========================================="

# 检查Git仓库
if [[ ! -d .git ]]; then
    log_warning "不是Git仓库，跳过代码更新"
    exit 1
fi

# 显示当前版本
CURRENT_COMMIT=$(git rev-parse --short HEAD)
log_info "当前版本: $CURRENT_COMMIT"

# 备份当前版本
log_info "创建备份..."
BACKUP_DIR="${APP_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
cp -r $APP_DIR $BACKUP_DIR
log_success "备份创建于: $BACKUP_DIR"

# 拉取最新代码
log_info "拉取最新代码 (分支: $BRANCH)..."
git fetch origin $BRANCH
git reset --hard origin/$BRANCH

NEW_COMMIT=$(git rev-parse --short HEAD)
log_info "新版本: $NEW_COMMIT"

# 检查是否有更新
if [[ "$CURRENT_COMMIT" == "$NEW_COMMIT" ]]; then
    log_info "代码已是最新版本，无需更新"
else
    log_info "代码已更新: $CURRENT_COMMIT -> $NEW_COMMIT"

    # 显示变更
    log_info "变更列表:"
    git log --oneline $CURRENT_COMMIT..$NEW_COMMIT | head -n 10
fi

# 安装依赖
log_info "安装依赖..."
npm install --production

# 重启应用
log_info "重启应用..."
if command -v pm2 &> /dev/null; then
    pm2 restart $APP_NAME
    sleep 2
    pm2 status $APP_NAME
    log_success "应用已重启"
else
    log_warning "PM2未安装，请手动重启应用"
fi

# 验证更新
log_info "验证应用状态..."
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
    log_success "应用运行正常"

    # 删除备份（可选）
    read -p "更新成功，是否删除备份? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf $BACKUP_DIR
        log_info "备份已删除"
    else
        log_info "备份保留于: $BACKUP_DIR"
    fi
else
    log_warning "应用响应异常 (HTTP $HTTP_CODE)"
    log_warning "如需回滚，请执行: ./scripts/rollback.sh $BACKUP_DIR"
fi

log_success "=========================================="
log_success "更新完成"
log_success "=========================================="
