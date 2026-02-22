[Leia em português](README.pt-br.md)

# Academic Risk Infrastructure (Terraform)

This Terraform configuration provisions an AWS EC2 instance to host and serve the following projects:
- [academic-risk-model](https://github.com/manoelsilva/academic-risk-model) (Python/Flask — ML Risk Prediction API)
- [academic-risk-app](https://github.com/manoelsilva/academic-risk-app) (Angular + Express.js — Web Application)

## Prerequisites

### For AWS Deployment (Terraform)
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0
- An existing EC2 Key Pair (for SSH access)
- IAM Role named `LabRole` with necessary permissions

### For Local Development (Docker Compose)
- Docker and Docker Compose installed
- Git (to clone dependency projects)

## Local Development with Docker Compose

This project includes a `docker-compose.yml` file that allows you to run the entire application stack locally in isolated Docker containers. This is useful for development and testing before deploying to AWS.

### Setup for Local Development

1. **Clone this repository**:
   ```bash
   git clone <academic-risk-iac-repo-url>
   cd academic-risk-iac
   ```

2. **Clone the dependency projects** at the same level as this directory:
   ```bash
   cd ..
   git clone https://github.com/manoelsilva/academic-risk-model.git academic-risk-model
   git clone https://github.com/manoelsilva/academic-risk-app.git academic-risk-app
   cd academic-risk-iac
   ```
   
   Your directory structure should look like:
   ```
   projects/
   ├── academic-risk-iac/
   │   └── docker-compose.yml
   ├── academic-risk-model/
   └── academic-risk-app/
   ```

3. **Ensure model files are available**: Make sure the `.joblib` model file is in `../academic-risk-model/models/production/`.

4. **Build and start all services**:
   ```bash
   docker-compose up -d
   ```

5. **Access the application**:
   - Frontend + API: `http://localhost` (port 80)
   - Risk Model API: `http://localhost:5000`

### Docker Compose Commands

- **View logs**: `docker-compose logs -f`
- **Stop services**: `docker-compose down`
- **Restart a service**: `docker-compose restart academic-risk-model`
- **Rebuild after code changes**: `docker-compose up -d --build`
- **Check service status**: `docker-compose ps`

> **Note**: The dependency project folders (`academic-risk-model`, `academic-risk-app`) are ignored by git in this repository. Each user should clone them separately at the same level as `academic-risk-iac` directory.

## AWS Deployment with Terraform

1. **Initialize Terraform**
   ```sh
   cd src
   terraform init
   ```
2. **Apply the configuration**
   ```sh
   terraform apply
   ```

3. **Access the instance**
   The public IP and DNS will be output after apply. SSH using:
   ```sh
   ssh -i /path/to/your-key.pem ec2-user@<public_ip>
   ```

4. **Deploy academic-risk-model**
   ```bash
   sudo EC2_HOST=your_ip bash /tmp/deploy_academic_risk_model.sh
   ```

5. **Deploy academic-risk-app**
   ```bash
   sudo EC2_HOST=your_ip bash /tmp/deploy_academic_risk_app.sh
   ```

## Files

### Terraform Files
- `src/main.tf`: EC2, security group, and IAM role setup
- `src/outputs.tf`: Outputs for instance access (public IP and DNS)
- `src/user_data.sh`: Bootstraps the instance with required software (Python 3.12, Node.js, Docker, Git)

### Deployment Scripts
- `src/deploy_academic_risk_model.sh`: Automates deployment and service setup for academic-risk-model
- `src/deploy_academic_risk_app.sh`: Automates deployment and service setup for academic-risk-app (Angular + Express + nginx)
- `src/academic-risk-app-nginx.conf`: Nginx configuration for serving the Angular frontend and proxying API requests

### GitHub Actions Workflows
- `.github/workflows/deploy_academic_risk_model.yml`: Manual workflow to deploy the ML model API to EC2
- `.github/workflows/deploy_academic_risk_app.yml`: Manual workflow to deploy the web application to EC2

### Docker Compose
- `docker-compose.yml`: Docker Compose configuration for local development
- `.env.example`: Example environment variables file

## Environment Variables Required

### For academic-risk-model:
The model service uses defaults that work out of the box. Optional overrides:
```bash
export PORT=5000
export LOG_LEVEL=INFO
export MODEL_PATH=models/production/model.joblib
```

### For academic-risk-app:
```bash
export RISK_MODEL_URL=http://localhost:5000   # Points to the risk model API
export PORT=3000                               # Express server port
```

### For GitHub Actions deployment:
```bash
EC2_HOST=your_ec2_public_ip_or_domain
```

## Complete Deployment Process

1. **Deploy Infrastructure**
   ```bash
   cd src
   terraform init
   terraform apply
   ```

2. **Deploy academic-risk-model**
   ```bash
   # Via GitHub Actions (recommended) or manually on EC2:
   sudo EC2_HOST=your_ip bash deploy_academic_risk_model.sh
   ```

3. **Deploy academic-risk-app**
   ```bash
   # Via GitHub Actions (recommended) or manually on EC2:
   sudo EC2_HOST=your_ip bash deploy_academic_risk_app.sh
   ```

## Service Endpoints

After deployment, the following services will be available:

- **Frontend (Angular)**: `http://your-ec2-ip/` (port 80, served via nginx)
- **Backend API (Express)**: `http://your-ec2-ip/api/` (proxied via nginx to port 3000)
- **Risk Model API (Flask)**: `http://your-ec2-ip:5000/` (Python/Flask API)

## Security Considerations

- The security group allows SSH (22), HTTP (80), HTTPS (443), and custom ports (3000, 5000)
- Consider restricting SSH access to your IP range in production
- The instance uses an IAM role (`LabRole`) for AWS service access
- All services run as the `ec2-user` with appropriate permissions

## Cost Estimation

- **EC2 Instance**: t3.large (~$0.0832/hour)
- **Storage**: 8GB gp3 EBS volume (~$0.08/month)
- **Data Transfer**: Minimal for typical usage
- **Total estimated cost**: ~$60-80/month for continuous operation

## Troubleshooting

### Common Issues

1. **Services not starting**
   ```bash
   sudo systemctl status academic-risk-model
   sudo systemctl status academic-risk-app
   
   sudo journalctl -u academic-risk-model -f
   sudo journalctl -u academic-risk-app -f
   ```

2. **Port conflicts**
   ```bash
   sudo netstat -tlnp | grep :5000
   sudo netstat -tlnp | grep :3000
   sudo netstat -tlnp | grep :80
   ```

3. **Permission issues**
   ```bash
   sudo chown -R ec2-user:ec2-user /opt/academic-risk-*
   ```

4. **Nginx issues**
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   sudo journalctl -u nginx -f
   ```

5. **Environment variables not set**
   - Check service files in `/etc/systemd/system/` for environment variables
   - Ensure `EC2_HOST` is properly set during deployment
