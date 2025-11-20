# HTML存储服务 - 完整部署指南

本文档提供了在生产服务器上部署HTML存储服务的完整步骤。

## 目录

- [部署方式对比](#部署方式对比)
- [方式一：传统部署（PM2 + Nginx）](#方式一传统部署pm2--nginx)
- [方式二：Docker部署](#方式二docker部署)
- [方式三：快速部署脚本](#方式三快速部署脚本)
- [SSL证书配置](#ssl证书配置)
- [安全加固](#安全加固)
- [监控和维护](#监控和维护)

---

## 部署方式对比

| 方式 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| PM2 + Nginx | 性能好，配置灵活 | 配置复杂 | 生产环境 |
| Docker | 环境隔离，易迁移 | 需要学习Docker | 容器化部署 |
| 快速脚本 | 一键部署，简单 | 灵活性较低 | 快速上线 |

---

## 方式一：传统部署（PM2 + Nginx）

### 1. 服务器准备

#### 1.1 系统要求

- **操作系统**：Ubuntu 20.04/22.04 LTS 或 CentOS 7/8
- **最低配置**：1核CPU，1GB内存，10GB硬盘
- **推荐配置**：2核CPU，2GB内存，20GB硬盘

#### 1.2 更新系统

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 2. 安装Node.js

#### 方式1：使用NodeSource仓库（推荐）

```bash
# Ubuntu/Debian - 安装Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# CentOS/RHEL - 安装Node.js 18.x LTS
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs
```

#### 方式2：使用nvm（适合多版本管理）

```bash
# 安装nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# 安装Node.js 18 LTS
nvm install 18
nvm use 18
nvm alias default 18
```

#### 验证安装

```bash
node --version  # 应显示 v18.x.x
npm --version   # 应显示 9.x.x
```

### 3. 安装PM2进程管理器

```bash
# 全局安装PM2
sudo npm install -g pm2

# 验证安装
pm2 --version
```

### 4. 部署应用

#### 4.1 创建应用目录

```bash
# 创建应用用户（可选，推荐）
sudo useradd -m -s /bin/bash htmlapp
sudo passwd htmlapp

# 切换到应用用户
sudo su - htmlapp

# 创建应用目录
mkdir -p ~/apps
cd ~/apps
```

#### 4.2 克隆或上传代码

**方式1：使用Git**

```bash
# 克隆仓库
git clone <你的仓库地址> html-storage-service
cd html-storage-service
git checkout claude/html-storage-service-01KSAKPzzhk4rrUS6S1GSVPN
```

**方式2：使用SCP上传**

```bash
# 在本地机器上执行
scp -r /path/to/poster user@your-server:/home/htmlapp/apps/html-storage-service
```

#### 4.3 安装依赖

```bash
cd ~/apps/html-storage-service
npm install --production
```

#### 4.4 配置环境变量

```bash
# 创建环境配置文件
cat > .env << 'EOF'
PORT=3000
NODE_ENV=production
EOF
```

#### 4.5 使用PM2启动应用

```bash
# 启动应用
pm2 start server.js --name html-storage

# 查看状态
pm2 status

# 查看日志
pm2 logs html-storage

# 设置开机自启
pm2 startup
pm2 save
```

### 5. 安装和配置Nginx

#### 5.1 安装Nginx

```bash
# Ubuntu/Debian
sudo apt install -y nginx

# CentOS/RHEL
sudo yum install -y nginx

# 启动Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

#### 5.2 配置Nginx反向代理

```bash
# 创建配置文件
sudo nano /etc/nginx/sites-available/html-storage
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # 客户端最大请求体大小
    client_max_body_size 10M;

    # 访问日志
    access_log /var/log/nginx/html-storage-access.log;
    error_log /var/log/nginx/html-storage-error.log;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

#### 5.3 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/html-storage /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

### 6. 配置防火墙

#### Ubuntu (UFW)

```bash
# 允许HTTP和HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 启用防火墙
sudo ufw enable
sudo ufw status
```

#### CentOS (firewalld)

```bash
# 允许HTTP和HTTPS
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 查看状态
sudo firewall-cmd --list-all
```

### 7. 配置SSL证书（HTTPS）

#### 使用Let's Encrypt免费证书

```bash
# 安装Certbot
# Ubuntu
sudo apt install -y certbot python3-certbot-nginx

# CentOS
sudo yum install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 测试自动续期
sudo certbot renew --dry-run
```

配置完成后，Nginx配置会自动更新为HTTPS。

---

## 方式二：Docker部署

### 1. 安装Docker

```bash
# Ubuntu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo apt install -y docker-compose

# 重新登录以应用组权限
```

### 2. 使用Docker部署

使用项目中的 `docker-compose.yml` 文件：

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 方式三：快速部署脚本

使用提供的自动化部署脚本：

```bash
# 下载部署脚本
wget https://raw.githubusercontent.com/your-repo/poster/main/deploy.sh
chmod +x deploy.sh

# 执行部署
./deploy.sh
```

---

## SSL证书配置

### 选项1：Let's Encrypt（免费，推荐）

```bash
# 安装certbot
sudo apt install certbot python3-certbot-nginx

# 获取证书并自动配置
sudo certbot --nginx -d your-domain.com

# 自动续期（已自动配置cron任务）
sudo certbot renew --dry-run
```

### 选项2：自签名证书（仅测试用）

```bash
# 生成自签名证书
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx-selfsigned.key \
  -out /etc/ssl/certs/nginx-selfsigned.crt

# 在Nginx配置中使用
# ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
# ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
```

---

## 安全加固

### 1. 限制请求速率

在Nginx配置中添加：

```nginx
# 在http块中
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# 在location块中
location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    # ... 其他配置
}
```

### 2. 配置CORS（如果需要）

修改 `server.js`，添加CORS中间件：

```javascript
// 安装cors
npm install cors

// 在server.js中添加
const cors = require('cors');
app.use(cors({
  origin: ['https://your-domain.com'],
  credentials: true
}));
```

### 3. 添加访问认证（可选）

```bash
# 安装basic auth包
npm install express-basic-auth

# 在server.js中添加
const basicAuth = require('express-basic-auth');
app.use('/api/save-html', basicAuth({
  users: { 'admin': 'your-secure-password' },
  challenge: true
}));
```

### 4. 限制文件大小

已在代码中设置为10MB，可根据需要调整：

```javascript
app.use(express.json({ limit: '10mb' }));
```

### 5. 定期清理旧文件

创建清理脚本：

```bash
# 创建清理脚本
cat > ~/apps/html-storage-service/cleanup.sh << 'EOF'
#!/bin/bash
# 删除30天前的HTML文件
find ~/apps/html-storage-service/html_storage -name "*.html" -mtime +30 -delete
EOF

chmod +x ~/apps/html-storage-service/cleanup.sh

# 添加到crontab（每天凌晨2点执行）
(crontab -l 2>/dev/null; echo "0 2 * * * ~/apps/html-storage-service/cleanup.sh") | crontab -
```

---

## 监控和维护

### 1. PM2监控

```bash
# 实时监控
pm2 monit

# 查看日志
pm2 logs html-storage

# 查看详细信息
pm2 show html-storage

# 重启应用
pm2 restart html-storage

# 查看资源使用
pm2 status
```

### 2. Nginx日志

```bash
# 访问日志
sudo tail -f /var/log/nginx/html-storage-access.log

# 错误日志
sudo tail -f /var/log/nginx/html-storage-error.log

# 分析访问统计
sudo apt install goaccess
sudo goaccess /var/log/nginx/html-storage-access.log --log-format=COMBINED
```

### 3. 系统监控

```bash
# 安装监控工具
sudo apt install htop iotop nethogs

# 查看系统资源
htop

# 查看磁盘使用
df -h
du -sh ~/apps/html-storage-service/html_storage

# 查看网络连接
netstat -tlnp
```

### 4. 设置告警（可选）

使用PM2 Plus进行监控：

```bash
# 注册PM2 Plus并链接
pm2 link <secret_key> <public_key>

# 或使用开源监控方案如Prometheus + Grafana
```

---

## 常见问题排查

### 1. 应用无法启动

```bash
# 查看PM2日志
pm2 logs html-storage --lines 100

# 检查端口占用
sudo netstat -tlnp | grep 3000

# 检查文件权限
ls -la ~/apps/html-storage-service
```

### 2. Nginx 502错误

```bash
# 检查应用是否运行
pm2 status

# 检查Nginx配置
sudo nginx -t

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log
```

### 3. 磁盘空间不足

```bash
# 查看磁盘使用
df -h

# 清理旧的HTML文件
find ~/apps/html-storage-service/html_storage -mtime +30 -delete

# 清理PM2日志
pm2 flush
```

### 4. 内存不足

```bash
# 查看内存使用
free -h

# 重启应用释放内存
pm2 restart html-storage
```

---

## 备份策略

### 1. 备份脚本

```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="/backup/html-storage"
APP_DIR="$HOME/apps/html-storage-service"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份HTML文件
tar -czf $BACKUP_DIR/html_storage_$DATE.tar.gz $APP_DIR/html_storage

# 保留最近7天的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### 2. 自动备份

```bash
# 添加到crontab（每天凌晨3点备份）
(crontab -l 2>/dev/null; echo "0 3 * * * ~/apps/html-storage-service/backup.sh") | crontab -
```

---

## 更新部署

```bash
# 进入应用目录
cd ~/apps/html-storage-service

# 拉取最新代码
git pull origin claude/html-storage-service-01KSAKPzzhk4rrUS6S1GSVPN

# 安装依赖
npm install --production

# 重启应用
pm2 restart html-storage

# 查看状态
pm2 status
```

---

## 性能优化

### 1. 启用Nginx缓存

```nginx
# 在http块中
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=html_cache:10m max_size=1g inactive=60m;

# 在location块中（仅缓存GET请求）
location /view/ {
    proxy_cache html_cache;
    proxy_cache_valid 200 60m;
    proxy_cache_key $uri;
    # ... 其他配置
}
```

### 2. 启用Gzip压缩

```nginx
# 在http块中
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/html text/css application/json application/javascript;
```

### 3. PM2集群模式

```bash
# 使用所有CPU核心
pm2 start server.js -i max --name html-storage

# 或指定进程数
pm2 start server.js -i 2 --name html-storage
```

---

## 联系和支持

如有问题，请查看：
- 项目README: [README.md](README.md)
- 问题追踪: GitHub Issues

---

**祝部署顺利！** 🚀
