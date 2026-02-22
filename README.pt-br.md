[Read in English](README.md)

# Infraestrutura Academic Risk (Terraform)

Esta configuração do Terraform provisiona uma instância AWS EC2 para hospedar e servir os seguintes projetos:
- [academic-risk-model](https://github.com/manoelsilva/academic-risk-model) (Python/Flask — API de Predição de Risco com ML)
- [academic-risk-app](https://github.com/manoelsilva/academic-risk-app) (Angular + Express.js — Aplicação Web)

## Pré-requisitos

### Para Deploy AWS (Terraform)
- AWS CLI configurado com permissões apropriadas
- Terraform >= 1.0.0
- Um EC2 Key Pair existente (para acesso SSH)
- IAM Role nomeada `LabRole` com as permissões necessárias

### Para Desenvolvimento Local (Docker Compose)
- Docker e Docker Compose instalados
- Git (para clonar os projetos de dependência)

## Desenvolvimento Local com Docker Compose

Este projeto inclui um arquivo `docker-compose.yml` que permite executar toda a stack de aplicação localmente em containers Docker isolados. Isso é útil para desenvolvimento e testes antes de fazer o deploy na AWS.

### Configuração para Desenvolvimento Local

1. **Clone este repositório**:
   ```bash
   git clone <academic-risk-iac-repo-url>
   cd academic-risk-iac
   ```

2. **Clone os projetos de dependência** no mesmo nível deste diretório:
   ```bash
   cd ..
   git clone https://github.com/manoelsilva/academic-risk-model.git academic-risk-model
   git clone https://github.com/manoelsilva/academic-risk-app.git academic-risk-app
   cd academic-risk-iac
   ```
   
   A estrutura de diretórios deve ficar assim:
   ```
   projects/
   ├── academic-risk-iac/
   │   └── docker-compose.yml
   ├── academic-risk-model/
   └── academic-risk-app/
   ```

3. **Certifique-se de que os arquivos de modelo estão disponíveis**: Certifique-se de que o arquivo `.joblib` do modelo está em `../academic-risk-model/models/production/`.

4. **Construa e inicie todos os serviços**:
   ```bash
   docker-compose up -d
   ```

5. **Acesse a aplicação**:
   - Frontend + API: `http://localhost` (porta 80)
   - API do Modelo de Risco: `http://localhost:5000`

### Comandos do Docker Compose

- **Ver logs**: `docker-compose logs -f`
- **Parar serviços**: `docker-compose down`
- **Reiniciar um serviço**: `docker-compose restart academic-risk-model`
- **Reconstruir após mudanças no código**: `docker-compose up -d --build`
- **Verificar status dos serviços**: `docker-compose ps`

> **Nota**: As pastas dos projetos de dependência (`academic-risk-model`, `academic-risk-app`) são ignoradas pelo git neste repositório. Cada usuário deve cloná-las separadamente no mesmo nível do diretório `academic-risk-iac`.

## Deploy AWS com Terraform

1. **Inicializar o Terraform**
   ```sh
   cd src
   terraform init
   ```
2. **Aplicar a configuração**
   ```sh
   terraform apply
   ```

3. **Acessar a instância**
   O IP público e DNS serão exibidos após o apply. SSH usando:
   ```sh
   ssh -i /caminho/para/sua-chave.pem ec2-user@<ip_publico>
   ```

4. **Deploy do academic-risk-model**
   ```bash
   sudo EC2_HOST=seu_ip bash /tmp/deploy_academic_risk_model.sh
   ```

5. **Deploy do academic-risk-app**
   ```bash
   sudo EC2_HOST=seu_ip bash /tmp/deploy_academic_risk_app.sh
   ```

## Arquivos

### Arquivos Terraform
- `src/main.tf`: Configuração EC2, security group e IAM role
- `src/outputs.tf`: Outputs para acesso à instância (IP público e DNS)
- `src/user_data.sh`: Inicializa a instância com software necessário (Python 3.12, Node.js, Docker, Git)

### Scripts de Deploy
- `src/deploy_academic_risk_model.sh`: Automatiza deploy e configuração do serviço para academic-risk-model
- `src/deploy_academic_risk_app.sh`: Automatiza deploy e configuração do serviço para academic-risk-app (Angular + Express + nginx)
- `src/academic-risk-app-nginx.conf`: Configuração Nginx para servir o frontend Angular e fazer proxy das requisições de API

### Workflows do GitHub Actions
- `.github/workflows/deploy_academic_risk_model.yml`: Workflow manual para deploy da API do modelo ML no EC2
- `.github/workflows/deploy_academic_risk_app.yml`: Workflow manual para deploy da aplicação web no EC2

### Docker Compose
- `docker-compose.yml`: Configuração Docker Compose para desenvolvimento local
- `.env.example`: Arquivo de exemplo de variáveis de ambiente

## Variáveis de Ambiente Necessárias

### Para academic-risk-model:
O serviço do modelo usa valores padrão que funcionam sem configuração. Opcionalmente:
```bash
export PORT=5000
export LOG_LEVEL=INFO
export MODEL_PATH=models/production/model.joblib
```

### Para academic-risk-app:
```bash
export RISK_MODEL_URL=http://localhost:5000   # Aponta para a API do modelo de risco
export PORT=3000                               # Porta do servidor Express
```

### Para deploy via GitHub Actions:
```bash
EC2_HOST=seu_ip_publico_ec2_ou_dominio
```

## Processo Completo de Deploy

1. **Deploy da Infraestrutura**
   ```bash
   cd src
   terraform init
   terraform apply
   ```

2. **Deploy do academic-risk-model**
   ```bash
   # Via GitHub Actions (recomendado) ou manualmente no EC2:
   sudo EC2_HOST=seu_ip bash deploy_academic_risk_model.sh
   ```

3. **Deploy do academic-risk-app**
   ```bash
   # Via GitHub Actions (recomendado) ou manualmente no EC2:
   sudo EC2_HOST=seu_ip bash deploy_academic_risk_app.sh
   ```

## Endpoints dos Serviços

Após o deploy, os seguintes serviços estarão disponíveis:

- **Frontend (Angular)**: `http://seu-ip-ec2/` (porta 80, servido via nginx)
- **API Backend (Express)**: `http://seu-ip-ec2/api/` (proxy via nginx para porta 3000)
- **API do Modelo de Risco (Flask)**: `http://seu-ip-ec2:5000/` (API Python/Flask)

## Considerações de Segurança

- O security group permite SSH (22), HTTP (80), HTTPS (443) e portas customizadas (3000, 5000)
- Considere restringir o acesso SSH ao seu range de IP em produção
- A instância usa um IAM role (`LabRole`) para acesso aos serviços AWS
- Todos os serviços rodam como `ec2-user` com permissões apropriadas

## Estimativa de Custos

- **Instância EC2**: t3.large (~$0.0832/hora)
- **Armazenamento**: Volume EBS gp3 8GB (~$0.08/mês)
- **Transferência de Dados**: Mínima para uso típico
- **Custo total estimado**: ~$60-80/mês para operação contínua

## Solução de Problemas

### Problemas Comuns

1. **Serviços não iniciando**
   ```bash
   sudo systemctl status academic-risk-model
   sudo systemctl status academic-risk-app
   
   sudo journalctl -u academic-risk-model -f
   sudo journalctl -u academic-risk-app -f
   ```

2. **Conflitos de porta**
   ```bash
   sudo netstat -tlnp | grep :5000
   sudo netstat -tlnp | grep :3000
   sudo netstat -tlnp | grep :80
   ```

3. **Problemas de permissão**
   ```bash
   sudo chown -R ec2-user:ec2-user /opt/academic-risk-*
   ```

4. **Problemas com Nginx**
   ```bash
   sudo nginx -t
   sudo systemctl status nginx
   sudo journalctl -u nginx -f
   ```

5. **Variáveis de ambiente não definidas**
   - Verifique os arquivos de serviço em `/etc/systemd/system/` para variáveis de ambiente
   - Certifique-se de que `EC2_HOST` está definido corretamente durante o deploy

---
[Read in English](README.md)
