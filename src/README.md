# Terraform Configuration

This directory contains the Terraform configuration files for provisioning the Academic Risk infrastructure on AWS.

## Files

- `main.tf` — EC2 instance, security group, IAM role, and key pair
- `outputs.tf` — Outputs for instance access (public IP and DNS)
- `user_data.sh` — EC2 bootstrap script (Python 3.12, Node.js, Docker)
- `deploy_academic_risk_model.sh` — Deployment script for the ML model API
- `deploy_academic_risk_app.sh` — Deployment script for the web application
- `academic-risk-app-nginx.conf` — Nginx configuration for serving the Angular frontend

## Usage

```bash
terraform init
terraform apply
```
