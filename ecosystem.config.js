/**
 * PM2 配置文件
 *
 * 使用方法:
 * pm2 start ecosystem.config.js
 * pm2 start ecosystem.config.js --env production
 */

module.exports = {
  apps: [
    {
      name: 'html-storage',
      script: './server.js',

      // 实例数量
      instances: 'max', // 使用所有CPU核心，或指定数字如: 2
      exec_mode: 'cluster', // cluster模式可以利用多核CPU

      // 环境变量
      env: {
        NODE_ENV: 'development',
        PORT: 3000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },

      // 日志配置
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: './logs/error.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',

      // 日志轮转
      max_memory_restart: '500M', // 超过500M内存自动重启

      // 监听文件变化（开发环境使用）
      watch: false, // 生产环境设为false
      ignore_watch: [
        'node_modules',
        'logs',
        'html_storage',
        '.git'
      ],

      // 自动重启配置
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',

      // 优雅关闭
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 3000,

      // 合并日志
      merge_logs: true,

      // 时间相关
      time: true,

      // 启动延迟
      restart_delay: 4000,

      // 错误重启间隔
      exp_backoff_restart_delay: 100
    }
  ],

  /**
   * 部署配置（可选）
   */
  deploy: {
    production: {
      user: 'htmlapp',
      host: 'your-server.com',
      ref: 'origin/claude/html-storage-service-01KSAKPzzhk4rrUS6S1GSVPN',
      repo: 'git@github.com:your-repo/poster.git',
      path: '/home/htmlapp/apps/html-storage-service',
      'post-deploy': 'npm install --production && pm2 reload ecosystem.config.js --env production'
    }
  }
};
