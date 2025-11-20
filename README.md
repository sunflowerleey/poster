# HTML存储服务

一个简单的HTML代码存储和访问服务，支持保存HTML代码并返回可访问的URL。

## 功能特性

- ✅ 接收HTML代码并保存到服务器
- ✅ 为每个HTML生成唯一的访问URL
- ✅ 通过URL直接访问保存的HTML页面
- ✅ 查看所有已保存的HTML列表
- ✅ 支持JSON和纯HTML两种提交格式

## 快速开始

### 安装依赖

```bash
npm install
```

### 启动服务

```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm start
```

服务默认运行在 `http://localhost:3000`

## API接口文档

### 1. 保存HTML代码

**接口地址：** `POST /api/save-html`

**请求方式1：JSON格式**

```bash
curl -X POST http://localhost:3000/api/save-html \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<html><body><h1>Hello World</h1></body></html>"
  }'
```

**请求方式2：纯HTML格式**

```bash
curl -X POST http://localhost:3000/api/save-html \
  -H "Content-Type: text/html" \
  -d '<html><body><h1>Hello World</h1></body></html>'
```

**成功响应：**

```json
{
  "success": true,
  "message": "HTML保存成功",
  "id": "abc123-def456-ghi789",
  "url": "http://localhost:3000/view/abc123-def456-ghi789"
}
```

**错误响应：**

```json
{
  "error": "HTML内容不能为空"
}
```

### 2. 访问HTML页面

**接口地址：** `GET /view/:id`

直接在浏览器中打开返回的URL，或使用curl：

```bash
curl http://localhost:3000/view/abc123-def456-ghi789
```

### 3. 获取HTML列表

**接口地址：** `GET /api/list`

```bash
curl http://localhost:3000/api/list
```

**响应示例：**

```json
{
  "success": true,
  "count": 2,
  "files": [
    {
      "id": "abc123-def456",
      "url": "http://localhost:3000/view/abc123-def456",
      "createdAt": "2025-11-20T06:20:00.000Z",
      "size": 1024
    }
  ]
}
```

## 使用示例

### JavaScript/Node.js

```javascript
// 使用 fetch API
const htmlContent = '<html><body><h1>测试页面</h1></body></html>';

fetch('http://localhost:3000/api/save-html', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ html: htmlContent })
})
  .then(res => res.json())
  .then(data => {
    console.log('访问URL:', data.url);
  });
```

### Python

```python
import requests

html_content = '<html><body><h1>测试页面</h1></body></html>'

response = requests.post(
    'http://localhost:3000/api/save-html',
    json={'html': html_content}
)

result = response.json()
print(f"访问URL: {result['url']}")
```

### 使用测试脚本

```bash
node test_example.js
```

## 技术栈

- **Node.js** - 运行环境
- **Express** - Web框架
- **UUID** - 生成唯一标识符
- **File System (fs)** - 文件存储

## 配置

### 端口配置

通过环境变量设置端口：

```bash
PORT=8080 npm start
```

### 存储目录

HTML文件默认存储在 `./html_storage/` 目录下，会自动创建。

## 安全注意事项

- 当前版本没有文件大小限制（默认10MB）
- 没有访问权限控制
- 没有HTML内容验证和清理
- 建议在生产环境中添加：
  - 身份验证
  - 速率限制
  - HTML清理（防XSS）
  - 文件数量限制
  - 定期清理过期文件

## 项目结构

```
poster/
├── server.js           # 主服务器文件
├── package.json        # 项目配置
├── test_example.js     # 测试示例
├── .gitignore         # Git忽略文件
├── README.md          # 说明文档
└── html_storage/      # HTML存储目录（自动创建）
```

## 许可证

ISC
