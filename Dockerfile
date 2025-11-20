# HTML存储服务 - Docker镜像
# 使用多阶段构建优化镜像大小

# 阶段1: 基础镜像
FROM node:18-alpine AS base

# 设置工作目录
WORKDIR /app

# 安装生产依赖
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# 阶段2: 生产镜像
FROM node:18-alpine AS production

# 设置环境变量
ENV NODE_ENV=production \
    PORT=3000

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 设置工作目录
WORKDIR /app

# 从base阶段复制依赖
COPY --from=base --chown=nodejs:nodejs /app/node_modules ./node_modules

# 复制应用代码
COPY --chown=nodejs:nodejs server.js ./
COPY --chown=nodejs:nodejs package*.json ./

# 创建存储目录
RUN mkdir -p html_storage && chown -R nodejs:nodejs html_storage

# 创建日志目录
RUN mkdir -p logs && chown -R nodejs:nodejs logs

# 切换到非root用户
USER nodejs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# 启动应用
CMD ["node", "server.js"]
