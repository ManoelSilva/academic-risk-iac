[Leia em português](DOCKER_SETUP.pt-br.md)

# Docker Compose Setup Guide

This guide explains how to set up and run the Academic Risk application stack locally using Docker Compose.

## Overview

The `docker-compose.yml` file orchestrates two services:
- **academic-risk-model**: ML risk prediction API service (port 5000)
- **academic-risk-app**: Angular web frontend + Express.js backend API (port 80)

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone dependency projects)

## Initial Setup

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

3. **Ensure model files are available**: 
   Make sure the `.joblib` production model file is in `../academic-risk-model/models/production/`. This will be mounted as a read-only volume into the container.

## Running the Services

### Start all services:
```bash
docker-compose up -d
```

### View logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f academic-risk-model
docker-compose logs -f academic-risk-app
```

### Stop all services:
```bash
docker-compose down
```

### Restart a specific service:
```bash
docker-compose restart academic-risk-model
```

### Rebuild services after code changes:
```bash
docker-compose up -d --build
```

## Accessing the Services

After starting the services, you can access:

- **Frontend (Angular) + Backend API**: `http://localhost`
- **Risk Model API**: `http://localhost:5000`

The web application automatically routes API requests:
- `/api/*` requests are handled by the Express.js backend (port 3000 inside the container)
- The Express backend communicates with the risk model API via Docker service names

## Service Details

### academic-risk-model
- **Port**: 5000
- **Health Check**: `http://localhost:5000/health`
- **Model Files**: Mounted from `../academic-risk-model/models` (read-only)
- **Data Files**: Mounted from `../academic-risk-model/data` (read-only)
- **Environment Variables**: 
  - `PORT=5000`: API port
  - `LOG_LEVEL=INFO`: Logging level
  - `MODEL_PATH=models/production/model.joblib`: Path to the production model

### academic-risk-app
- **Port**: 80 (mapped to internal port 3000)
- **Health Check**: `http://localhost/api/health`
- **Dependencies**: Waits for academic-risk-model to be ready
- **Environment Variables**: 
  - `RISK_MODEL_URL=http://academic-risk-model:5000`: Points to the risk model service via Docker network

## Network

All services communicate through a Docker bridge network (`academic-risk-network`), allowing them to reference each other by service name (e.g., `academic-risk-model:5000`).

## Troubleshooting

### Check service health:
```bash
docker-compose ps
```

### View service logs for errors:
```bash
docker-compose logs academic-risk-model
docker-compose logs academic-risk-app
```

### Restart all services:
```bash
docker-compose restart
```

### Remove all containers and networks:
```bash
docker-compose down -v
```

### Check if ports are already in use:
```bash
# Windows
netstat -ano | findstr :5000
netstat -ano | findstr :80

# Linux/Mac
lsof -i :5000
lsof -i :80
```

## Volume Mounts

- **Model files**: `../academic-risk-model/models` → `/app/models` (read-only)
- **Data files**: `../academic-risk-model/data` → `/app/data` (read-only)

These allow you to update model and data files on the host without rebuilding the container.

## Development Workflow

1. Make changes to the code in the dependency project folders
2. Rebuild the affected service: `docker-compose up -d --build <service-name>`
3. Or rebuild all services: `docker-compose up -d --build`
4. Check logs to verify the changes: `docker-compose logs -f <service-name>`

## Notes

- Model and data files are mounted as read-only volumes, so you can update them without rebuilding containers
- The `docker-compose.yml` file uses relative paths (`../`) to reference the dependency projects at the same directory level
- The academic-risk-app container serves both the Angular frontend and the Express.js backend in a single container
