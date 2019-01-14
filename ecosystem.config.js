module.exports = {
  apps : [{
    name: 'Ria',
    script: 'server.js',

    "cron_restart"     : "0 */4 * * *",
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production'
    }
  }],

  deploy : {
    production : {
      user : 'ec2-user',
      host : '13.231.129.244',
      ref  : 'origin/master',
      repo : 'git@github.com:yuyuvn/hubot-facebook-bot.git',
      path : '/home/ec2-user/production',
      'post-deploy' : 'ln -s /home/ec2-user/.env /var/www/production/.env && npm install && pm2 reload ecosystem.config.js --env production'
    }
  }
};
