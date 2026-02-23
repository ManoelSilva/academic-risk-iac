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

## Monitoring Stack (MLflow + Prometheus + Grafana)

This project includes a full observability stack for monitoring ML experiment metrics from MLflow.

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Docker Network                            │
│                                                                  │
│  ┌─────────────────┐    ┌──────────────────┐                     │
│  │ academic-risk-  │    │  MLflow Server   │                     │
│  │ model (Flask)   │    │  (SQLite backend)│                     │
│  │  :5000          │    │  :5001           │                     │
│  └─────────────────┘    └────────┬─────────┘                     │
│                                  │                               │
│  ┌─────────────────┐    ┌────────▼─────────┐                     │
│  │ academic-risk-  │    │ MLflow Exporter  │                     │
│  │ app (Angular +  │    │ (Python)         │                     │
│  │ Express) :3000  │    │  :8000           │                     │
│  └─────────────────┘    └────────┬─────────┘                     │
│                                  │ /metrics                      │
│                         ┌────────▼─────────┐                     │
│                         │   Prometheus     │                     │
│                         │   :9090          │                     │
│                         └────────┬─────────┘                     │
│                                  │                               │
│                         ┌────────▼─────────┐                     │
│                         │    Grafana       │                     │
│                         │    :3001         │                     │
│                         └──────────────────┘                     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Metrics Flow

1. **MLflow Server** stores experiment data (metrics, parameters, artifacts) in a SQLite database
2. **MLflow Exporter** (custom Python service) periodically queries MLflow's tracking API, converts metrics into Prometheus-compatible format, and exposes them on `:8000/metrics`
3. **Prometheus** scrapes the exporter every 30s and stores time-series data with 90-day retention
4. **Grafana** reads from Prometheus and renders pre-configured dashboards

### Exposed Prometheus Metrics

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `mlflow_run_metric` | Gauge | experiment_name, run_name, model_type, metric_name | Individual run metric values (recall, f1_score, roc_auc, cv_mean_recall, cv_std_recall) |
| `mlflow_best_score` | Gauge | experiment_name, metric_name | Best score per metric across all runs in an experiment |
| `mlflow_experiment_run_count` | Gauge | experiment_name | Number of runs per experiment |
| `mlflow_run_params` | Info | experiment_name, run_name | Run parameters (model_type, scoring, cv_folds, etc.) |

### Grafana Dashboard Panels

The auto-provisioned dashboard ("Academic Risk - MLflow Metrics") includes:

- **Overview row**: Best Recall, Best ROC-AUC, Best F1 Score, Total Experiment Runs (stat panels)
- **Metric Comparison**: Recall by Model Type, ROC-AUC by Model Type (bar charts)
- **Cross-Validation**: CV Mean Recall, CV Std Recall by Model (bar charts)
- **F1 Analysis**: F1 Score by Model Type, Experiment Run Count Over Time (time series)
- **Summary Table**: All runs with metric values in tabular format

### Running the Monitoring Stack

**Full stack (application + monitoring):**
```bash
docker-compose up -d
```

**Monitoring only:**
```bash
docker-compose -f docker-compose.monitoring.yml up -d
```

### Monitoring Stack Endpoints

- **MLflow UI**: `http://localhost:5001`
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3001` (default: admin/admin)
- **Exporter Metrics**: `http://localhost:8000/metrics`

## Files

### Terraform Files
- `src/main.tf`: EC2, security group, and IAM role setup
- `src/outputs.tf`: Outputs for instance access (public IP, DNS, and service URLs)
- `src/user_data.sh`: Bootstraps the instance with required software (Python 3.12, Node.js, Docker, Docker Compose, Git)

### Deployment Scripts
- `src/deploy_academic_risk_model.sh`: Automates deployment and service setup for academic-risk-model
- `src/deploy_academic_risk_app.sh`: Automates deployment and service setup for academic-risk-app (Angular + Express + nginx)
- `src/deploy_monitoring.sh`: Deploys the monitoring stack (MLflow, Prometheus, Grafana) via Docker Compose
- `src/academic-risk-app-nginx.conf`: Nginx configuration for serving the Angular frontend and proxying API requests

### Monitoring Configuration
- `monitoring/mlflow-exporter/exporter.py`: Custom Python exporter that bridges MLflow metrics to Prometheus
- `monitoring/mlflow-exporter/Dockerfile`: Container image for the exporter
- `monitoring/prometheus/prometheus.yml`: Prometheus scrape configuration
- `monitoring/grafana/provisioning/datasources/datasource.yml`: Auto-provisions Prometheus as Grafana data source
- `monitoring/grafana/provisioning/dashboards/dashboards.yml`: Auto-provisions dashboard from JSON
- `monitoring/grafana/dashboards/mlflow-metrics.json`: Pre-built Grafana dashboard with MLflow metrics panels

### GitHub Actions Workflows
- `.github/workflows/deploy_academic_risk_model.yml`: Manual workflow to deploy the ML model API to EC2
- `.github/workflows/deploy_academic_risk_app.yml`: Manual workflow to deploy the web application to EC2
- `.github/workflows/deploy_monitoring.yml`: Manual workflow to deploy the monitoring stack to EC2

### Docker Compose
- `docker-compose.yml`: Full stack (application + monitoring) for local development
- `docker-compose.monitoring.yml`: Monitoring-only stack (MLflow, Prometheus, Grafana)
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

### For Grafana:
```bash
export GRAFANA_ADMIN_USER=admin
export GRAFANA_ADMIN_PASSWORD=admin
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

4. **Deploy Monitoring Stack**
   ```bash
   # Via GitHub Actions (recommended) or manually on EC2:
   sudo EC2_HOST=your_ip bash deploy_monitoring.sh
   ```

## Service Endpoints

After deployment, the following services will be available:

- **Frontend (Angular)**: `http://your-ec2-ip/` (port 80, served via nginx)
- **Backend API (Express)**: `http://your-ec2-ip/api/` (proxied via nginx to port 3000)
- **Risk Model API (Flask)**: `http://your-ec2-ip:5000/`
- **MLflow UI**: `http://your-ec2-ip:5001/`
- **Prometheus**: `http://your-ec2-ip:9090/`
- **Grafana**: `http://your-ec2-ip:3001/`

## Security Considerations

- The security group allows SSH (22), HTTP (80), HTTPS (443), and application ports (3000, 5000, 5001, 9090, 3001)
- Consider restricting SSH access to your IP range in production
- Consider restricting monitoring ports (9090, 3001, 5001) to internal/VPN access in production
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
