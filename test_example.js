/**
 * HTML存储服务测试示例
 *
 * 使用方法:
 * 1. 确保服务已启动: npm start
 * 2. 在另一个终端运行: node test_example.js
 */

const http = require('http');

// 配置
const HOST = 'localhost';
const PORT = 3000;

// 测试HTML内容
const testHtml = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>测试页面</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .container {
      background: rgba(255, 255, 255, 0.1);
      padding: 30px;
      border-radius: 10px;
      backdrop-filter: blur(10px);
    }
    h1 {
      text-align: center;
      font-size: 2.5em;
      margin-bottom: 20px;
    }
    p {
      font-size: 1.2em;
      line-height: 1.6;
    }
    .time {
      text-align: center;
      margin-top: 20px;
      font-style: italic;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🎉 HTML存储服务测试页面</h1>
    <p>这是一个通过API保存的测试HTML页面。</p>
    <p>如果你能看到这个页面，说明HTML存储服务工作正常！</p>
    <div class="time">
      生成时间: ${new Date().toLocaleString('zh-CN')}
    </div>
  </div>
</body>
</html>
`;

// 发送POST请求保存HTML
function saveHtml(htmlContent) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ html: htmlContent });

    const options = {
      hostname: HOST,
      port: PORT,
      path: '/api/save-html',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = http.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const result = JSON.parse(responseData);
          resolve(result);
        } catch (error) {
          reject(new Error('解析响应失败: ' + error.message));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error('请求失败: ' + error.message));
    });

    req.write(data);
    req.end();
  });
}

// 获取HTML列表
function getHtmlList() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: HOST,
      port: PORT,
      path: '/api/list',
      method: 'GET'
    };

    const req = http.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const result = JSON.parse(responseData);
          resolve(result);
        } catch (error) {
          reject(new Error('解析响应失败: ' + error.message));
        }
      });
    });

    req.on('error', (error) => {
      reject(new Error('请求失败: ' + error.message));
    });

    req.end();
  });
}

// 运行测试
async function runTest() {
  console.log('========================================');
  console.log('HTML存储服务测试开始');
  console.log('========================================\n');

  try {
    // 测试1: 保存HTML
    console.log('📝 测试1: 保存HTML代码...');
    const result = await saveHtml(testHtml);

    if (result.success) {
      console.log('✅ 保存成功!');
      console.log(`   ID: ${result.id}`);
      console.log(`   访问URL: ${result.url}`);
      console.log('');
    } else {
      console.log('❌ 保存失败');
      return;
    }

    // 测试2: 获取列表
    console.log('📋 测试2: 获取HTML列表...');
    const listResult = await getHtmlList();

    if (listResult.success) {
      console.log(`✅ 获取成功! 共有 ${listResult.count} 个HTML文件`);
      console.log('');
    }

    // 显示总结
    console.log('========================================');
    console.log('🎊 测试完成！');
    console.log('========================================');
    console.log(`\n在浏览器中打开以下URL查看保存的页面:`);
    console.log(`👉 ${result.url}\n`);

  } catch (error) {
    console.error('❌ 测试失败:', error.message);
    console.error('\n提示: 请确保服务已启动 (npm start)');
  }
}

// 执行测试
runTest();
