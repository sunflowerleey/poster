const express = require('express');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;
const STORAGE_DIR = path.join(__dirname, 'html_storage');

// 中间件：解析JSON请求体
app.use(express.json({ limit: '10mb' }));
app.use(express.text({ type: 'text/html', limit: '10mb' }));

// 确保存储目录存在
if (!fs.existsSync(STORAGE_DIR)) {
  fs.mkdirSync(STORAGE_DIR, { recursive: true });
}

// API接口：保存HTML代码
app.post('/api/save-html', (req, res) => {
  try {
    // 从请求体获取HTML代码
    let htmlContent;

    if (req.is('application/json')) {
      // 如果是JSON格式，期望 { "html": "..." }
      htmlContent = req.body.html;
    } else if (req.is('text/html')) {
      // 如果是纯HTML文本
      htmlContent = req.body;
    } else {
      return res.status(400).json({
        error: '不支持的内容类型。请使用 application/json 或 text/html'
      });
    }

    // 验证HTML内容
    if (!htmlContent || typeof htmlContent !== 'string') {
      return res.status(400).json({
        error: 'HTML内容不能为空'
      });
    }

    // 生成唯一ID
    const fileId = uuidv4();
    const fileName = `${fileId}.html`;
    const filePath = path.join(STORAGE_DIR, fileName);

    // 保存HTML文件
    fs.writeFileSync(filePath, htmlContent, 'utf8');

    // 构造访问URL
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const accessUrl = `${baseUrl}/view/${fileId}`;

    // 返回成功响应
    res.status(201).json({
      success: true,
      message: 'HTML保存成功',
      id: fileId,
      url: accessUrl
    });

  } catch (error) {
    console.error('保存HTML时出错:', error);
    res.status(500).json({
      error: '服务器内部错误',
      message: error.message
    });
  }
});

// API接口：通过URL访问HTML
app.get('/view/:id', (req, res) => {
  try {
    const fileId = req.params.id;
    const fileName = `${fileId}.html`;
    const filePath = path.join(STORAGE_DIR, fileName);

    // 检查文件是否存在
    if (!fs.existsSync(filePath)) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>页面不存在</title>
          <style>
            body {
              font-family: Arial, sans-serif;
              text-align: center;
              padding: 50px;
              background: #f5f5f5;
            }
            h1 { color: #e74c3c; }
          </style>
        </head>
        <body>
          <h1>404 - 页面不存在</h1>
          <p>请求的HTML页面不存在。</p>
        </body>
        </html>
      `);
    }

    // 读取并返回HTML文件
    const htmlContent = fs.readFileSync(filePath, 'utf8');
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.send(htmlContent);

  } catch (error) {
    console.error('读取HTML时出错:', error);
    res.status(500).send('服务器内部错误');
  }
});

// API接口：获取已保存的HTML列表
app.get('/api/list', (req, res) => {
  try {
    const files = fs.readdirSync(STORAGE_DIR);
    const htmlFiles = files
      .filter(file => file.endsWith('.html'))
      .map(file => {
        const fileId = file.replace('.html', '');
        const filePath = path.join(STORAGE_DIR, file);
        const stats = fs.statSync(filePath);
        const baseUrl = `${req.protocol}://${req.get('host')}`;

        return {
          id: fileId,
          url: `${baseUrl}/view/${fileId}`,
          createdAt: stats.birthtime,
          size: stats.size
        };
      });

    res.json({
      success: true,
      count: htmlFiles.length,
      files: htmlFiles
    });

  } catch (error) {
    console.error('获取文件列表时出错:', error);
    res.status(500).json({
      error: '服务器内部错误',
      message: error.message
    });
  }
});

// 根路径：显示使用说明
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>HTML存储服务</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          max-width: 900px;
          margin: 50px auto;
          padding: 20px;
          background: #f8f9fa;
        }
        .container {
          background: white;
          padding: 30px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
          color: #2c3e50;
          border-bottom: 3px solid #3498db;
          padding-bottom: 10px;
        }
        h2 {
          color: #34495e;
          margin-top: 30px;
        }
        code {
          background: #f4f4f4;
          padding: 2px 6px;
          border-radius: 3px;
          font-family: 'Courier New', monospace;
        }
        pre {
          background: #2c3e50;
          color: #ecf0f1;
          padding: 15px;
          border-radius: 5px;
          overflow-x: auto;
        }
        .endpoint {
          background: #e8f4f8;
          padding: 15px;
          margin: 15px 0;
          border-left: 4px solid #3498db;
          border-radius: 4px;
        }
        .method {
          display: inline-block;
          padding: 4px 8px;
          border-radius: 3px;
          font-weight: bold;
          margin-right: 10px;
        }
        .post { background: #27ae60; color: white; }
        .get { background: #3498db; color: white; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>📄 HTML存储服务</h1>
        <p>这是一个简单的HTML存储和访问服务。你可以通过API保存HTML代码并获得一个访问URL。</p>

        <h2>🚀 API接口说明</h2>

        <div class="endpoint">
          <p><span class="method post">POST</span> <code>/api/save-html</code></p>
          <p><strong>功能：</strong>保存HTML代码</p>
          <p><strong>请求格式1（JSON）：</strong></p>
          <pre>{
  "html": "&lt;html&gt;&lt;body&gt;Hello World&lt;/body&gt;&lt;/html&gt;"
}</pre>
          <p><strong>请求格式2（纯HTML）：</strong></p>
          <pre>Content-Type: text/html

&lt;html&gt;&lt;body&gt;Hello World&lt;/body&gt;&lt;/html&gt;</pre>
          <p><strong>返回示例：</strong></p>
          <pre>{
  "success": true,
  "message": "HTML保存成功",
  "id": "uuid",
  "url": "http://localhost:3000/view/uuid"
}</pre>
        </div>

        <div class="endpoint">
          <p><span class="method get">GET</span> <code>/view/:id</code></p>
          <p><strong>功能：</strong>访问已保存的HTML页面</p>
          <p><strong>示例：</strong><code>GET /view/abc123-def456</code></p>
        </div>

        <div class="endpoint">
          <p><span class="method get">GET</span> <code>/api/list</code></p>
          <p><strong>功能：</strong>获取所有已保存的HTML列表</p>
        </div>

        <h2>💡 使用示例</h2>
        <pre>
# 方式1: 使用JSON格式
curl -X POST http://localhost:${PORT}/api/save-html \\
  -H "Content-Type: application/json" \\
  -d '{"html":"&lt;html&gt;&lt;body&gt;&lt;h1&gt;Hello World&lt;/h1&gt;&lt;/body&gt;&lt;/html&gt;"}'

# 方式2: 直接发送HTML
curl -X POST http://localhost:${PORT}/api/save-html \\
  -H "Content-Type: text/html" \\
  -d '&lt;html&gt;&lt;body&gt;&lt;h1&gt;Hello World&lt;/h1&gt;&lt;/body&gt;&lt;/html&gt;'

# 查看列表
curl http://localhost:${PORT}/api/list
        </pre>

        <h2>📊 服务状态</h2>
        <p>✅ 服务运行中</p>
        <p>🔗 端口: ${PORT}</p>
      </div>
    </body>
    </html>
  `);
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════════╗
  ║   HTML存储服务已启动                          ║
  ╠═══════════════════════════════════════════════╣
  ║   🌐 服务地址: http://localhost:${PORT}       ║
  ║   📁 存储目录: ${STORAGE_DIR}
  ║   📝 API文档: http://localhost:${PORT}        ║
  ╚═══════════════════════════════════════════════╝
  `);
});
