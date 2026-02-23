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
