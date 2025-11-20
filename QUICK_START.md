# 快速开始指南

## 本地开发

### 1. 安装依赖
```bash
npm install
```

### 2. 启动服务
```bash
npm start
```

### 3. 测试
```bash
# 在另一个终端运行
node test_example.js

# 或使用curl
curl -X POST http://localhost:3000/api/save-html \
  -H "Content-Type: application/json" \
  -d '{"html":"<html><body><h1>Hello World</h1></body></html>"}'
```

---

## 服务器部署（三种方式）

### 方式1: 一键自动部署（推荐）

```bash
# 1. 下载代码
git clone <your-repo> html-storage-service
cd html-storage-service

# 2. 执行自动部署脚本
chmod +x deploy.sh
./deploy.sh
```

脚本会自动完成:
- ✅ 安装Node.js
- ✅ 安装PM2
- ✅ 安装Nginx
- ✅ 部署应用
- ✅ 配置防火墙
- ✅ （可选）安装SSL证书

### 方式2: Docker部署

```bash
# 1. 安装Docker
curl -fsSL https://get.docker.com | sh

# 2. 启动服务
docker-compose up -d

# 3. 查看状态
docker-compose ps
docker-compose logs -f
```

### 方式3: 手动部署

#### 第1步: 安装Node.js
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

#### 第2步: 安装PM2
```bash
sudo npm install -g pm2
```

#### 第3步: 部署代码
```bash
mkdir -p ~/apps
cd ~/apps
git clone <your-repo> html-storage-service
cd html-storage-service
npm install --production
```

#### 第4步: 启动应用
```bash
# 使用PM2配置文件启动
pm2 start ecosystem.config.js --env production

# 保存PM2配置
pm2 save

# 设置开机自启
pm2 startup
```

#### 第5步: 安装Nginx
```bash
sudo apt install -y nginx
```

#### 第6步: 配置Nginx
```bash
# 复制配置文件
sudo cp deployment/nginx.conf /etc/nginx/sites-available/html-storage

# 修改域名（替换your-domain.com为你的域名）
sudo nano /etc/nginx/sites-available/html-storage

# 启用配置
sudo ln -s /etc/nginx/sites-available/html-storage /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

#### 第7步: 配置防火墙
```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

#### 第8步: 安装SSL证书（可选）
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 定时任务设置

```bash
# 安装定时任务脚本
chmod +x scripts/*.sh
./scripts/install-cron.sh
```

这会配置：
- 每天凌晨2点清理过期文件
- 每天凌晨3点自动备份

---

## 常用命令

### PM2命令
```bash
pm2 status              # 查看状态
pm2 logs html-storage   # 查看日志
pm2 restart html-storage # 重启应用
pm2 stop html-storage   # 停止应用
pm2 monit              # 实时监控
```

### 维护脚本
```bash
# 监控检查
./scripts/monitor.sh

# 手动清理
./scripts/cleanup.sh

# 手动备份
./scripts/backup.sh

# 更新代码
./scripts/update.sh
```

### Docker命令
```bash
docker-compose up -d      # 启动
docker-compose down       # 停止
docker-compose logs -f    # 查看日志
docker-compose restart    # 重启
```

---

## API使用

### 保存HTML
```bash
curl -X POST http://your-domain.com/api/save-html \
  -H "Content-Type: application/json" \
  -d '{"html":"<html><body><h1>Hello</h1></body></html>"}'
```

响应:
```json
{
  "success": true,
  "id": "abc-123",
  "url": "http://your-domain.com/view/abc-123"
}
```

### 访问HTML
```bash
# 浏览器访问
http://your-domain.com/view/abc-123

# 或使用curl
curl http://your-domain.com/view/abc-123
```

### 获取列表
```bash
curl http://your-domain.com/api/list
```

---

## 故障排查

### 应用无法启动
```bash
# 查看PM2日志
pm2 logs html-storage --lines 50

# 检查端口占用
sudo netstat -tlnp | grep 3000

# 手动启动测试
cd ~/apps/html-storage-service
node server.js
```

### Nginx 502错误
```bash
# 检查应用是否运行
pm2 status

# 检查Nginx配置
sudo nginx -t

# 查看Nginx错误日志
sudo tail -f /var/log/nginx/error.log
```

### 磁盘空间不足
```bash
# 查看磁盘使用
df -h

# 手动清理
./scripts/cleanup.sh

# 查看大文件
du -sh ~/apps/html-storage-service/*
```

---

## 更新部署

```bash
cd ~/apps/html-storage-service
./scripts/update.sh
```

---

## 获取帮助

- 📖 完整文档: [DEPLOYMENT.md](DEPLOYMENT.md)
- 📖 项目README: [README.md](README.md)
- 🐛 问题反馈: GitHub Issues

---

**祝使用愉快！** 🚀
