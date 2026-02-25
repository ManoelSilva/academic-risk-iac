#!/bin/bash
set -e

# Usage: sudo EC2_HOST=your_EC2_HOST_here bash deploy_monitoring.sh

APP_NAME=academic-risk-monitoring
APP_DIR=/opt/$APP_NAME
REPO_URL="https://github.com/ManoelSilva/academic-risk-iac"
BRANCH=main

if [ -z "$EC2_HOST" ]; then
  echo "Error: EC2_HOST environment variable is not set."
  exit 1
fi

echo "Ensuring Docker Buildx plugin is installed..."
BUILDX_DIR=/usr/local/lib/docker/cli-plugins
mkdir -p "$BUILDX_DIR"
if ! docker buildx version &>/dev/null || \
   [ "$(docker buildx version 2>/dev/null | grep -oP 'v?\K[0-9]+\.[0-9]+')" \< "0.17" ]; then
  echo "Installing/upgrading Docker Buildx..."
  curl -SL "https://github.com/docker/buildx/releases/latest/download/buildx-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" \
    -o "$BUILDX_DIR/docker-buildx"
  chmod +x "$BUILDX_DIR/docker-buildx"
  echo "Buildx installed: $(docker buildx version)"
else
  echo "Buildx already up to date: $(docker buildx version)"
fi

if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
fi

git clone --branch $BRANCH $REPO_URL $APP_DIR

chown -R ec2-user:ec2-user $APP_DIR
chmod -R u+rwX $APP_DIR

cd $APP_DIR

echo "Stopping existing monitoring containers..."
docker compose -f docker-compose.monitoring.yml down --remove-orphans 2>/dev/null || true

echo "Starting monitoring stack..."
docker compose -f docker-compose.monitoring.yml up -d --build

echo "Waiting for services to start..."
sleep 15

echo "Checking service health..."
docker compose -f docker-compose.monitoring.yml ps

echo ""
echo "============================================"
echo " Monitoring Stack Deployed Successfully"
echo "============================================"
echo " MLflow UI:   http://$EC2_HOST:5001"
echo " Prometheus:  http://$EC2_HOST:9090"
echo " Grafana:     http://$EC2_HOST:3001"
echo "============================================"
