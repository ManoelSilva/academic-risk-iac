#!/bin/bash
set -e

# Usage: sudo EC2_HOST=your_EC2_HOST_here bash deploy_academic_risk_app.sh

APP_NAME=academic-risk-app
APP_DIR=/opt/$APP_NAME
REPO_URL="https://github.com/ManoelSilva/academic-risk-app"
BRANCH=main

if [ -z "$EC2_HOST" ]; then
  echo "Error: EC2_HOST environment variable is not set."
  exit 1
fi

if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
fi

git clone --branch $BRANCH $REPO_URL $APP_DIR

chown -R ec2-user:ec2-user $APP_DIR
chmod -R u+rwX $APP_DIR

cd $APP_DIR
sudo -u ec2-user npm install
sudo -u ec2-user npx ng build --configuration production

dnf install -y nginx

rm -rf /usr/share/nginx/html/*

cp -r $APP_DIR/dist/academic-risk-app/* /usr/share/nginx/html/

chown -R nginx:nginx /usr/share/nginx/html
chmod -R 755 /usr/share/nginx/html
chcon -R -t httpd_sys_content_t /usr/share/nginx/html || true

cp /tmp/academic-risk-app-nginx.conf /etc/nginx/conf.d/academic-risk-app.conf

SERVICE_FILE=/etc/systemd/system/$APP_NAME.service

cat <<EOF > $SERVICE_FILE
[Unit]
Description=Academic Risk App Backend API
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$APP_DIR
Environment="PORT=3000"
Environment="NODE_ENV=production"
Environment="RISK_MODEL_URL=http://localhost:5000"
ExecStart=/usr/bin/node $APP_DIR/server/index.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $APP_NAME
systemctl restart $APP_NAME

systemctl enable nginx
nginx -t
if ! systemctl is-active --quiet nginx; then
  systemctl start nginx
else
  systemctl reload nginx
fi

echo "Academic Risk App deployed and served via nginx."
