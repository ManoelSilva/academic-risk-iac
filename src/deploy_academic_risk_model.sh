#!/bin/bash
set -e

# Usage: sudo EC2_HOST=your_EC2_HOST_here bash deploy_academic_risk_model.sh

APP_NAME=academic-risk-model
APP_DIR=/opt/$APP_NAME
REPO_URL="https://github.com/ManoelSilva/academic-risk-model"
BRANCH="${BRANCH:-main}"
PYTHON_BIN=python3.12
VENV_DIR=$APP_DIR/venv
SERVICE_FILE=/etc/systemd/system/$APP_NAME.service
MODEL_API_PORT="${MODEL_API_PORT:-5000}"

if [ -z "$EC2_HOST" ]; then
  echo "Error: EC2_HOST environment variable is not set."
  exit 1
fi

if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
fi

if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch $BRANCH $REPO_URL $APP_DIR
else
  cd $APP_DIR
  git fetch origin
  git checkout $BRANCH
  git pull origin $BRANCH
fi

chown -R ec2-user:ec2-user $APP_DIR
chmod -R u+rwX $APP_DIR

if [ ! -d "$VENV_DIR" ]; then
  $PYTHON_BIN -m venv $VENV_DIR
fi
source $VENV_DIR/bin/activate

pip install --upgrade pip
pip install -r $APP_DIR/requirements.txt

deactivate

# Replace PUBLIC_IP in swagger.yml with the actual ec2 host IP
SWAGGER_FILE=$APP_DIR/src/api/swagger.yml
if [ -f "$SWAGGER_FILE" ]; then
  sed -i "s|http://PUBLIC_IP:5000|http://$EC2_HOST:5000|g" "$SWAGGER_FILE"
fi

cat <<EOF > $SERVICE_FILE
[Unit]
Description=Academic Risk Model API
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$APP_DIR/src
Environment="PYTHONUNBUFFERED=1"
Environment="PYTHONPATH=$APP_DIR/src"
Environment="PORT=$MODEL_API_PORT"
Environment="LOG_LEVEL=INFO"
Environment="MODEL_PATH=$APP_DIR/src/models/production/model.joblib"
Environment="MLFLOW_TRACKING_URI=http://localhost:5001"
ExecStart=$VENV_DIR/bin/python3.12 $APP_DIR/src/api/main.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $APP_NAME
systemctl restart $APP_NAME
