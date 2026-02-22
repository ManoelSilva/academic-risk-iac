[Read in English](DOCKER_SETUP.md)

# Guia de Configuração Docker Compose

Este guia explica como configurar e executar a stack de aplicação Academic Risk localmente usando Docker Compose.

## Visão Geral

O arquivo `docker-compose.yml` orquestra dois serviços:
- **academic-risk-model**: Serviço de API do modelo de ML para predição de risco (porta 5000)
- **academic-risk-app**: Frontend web Angular + API backend Express.js (porta 80)

## Pré-requisitos

- Docker e Docker Compose instalados
- Git (para clonar os projetos de dependência)

## Configuração Inicial

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

3. **Certifique-se de que os arquivos de modelo estão disponíveis**: 
   Certifique-se de que o arquivo `.joblib` do modelo de produção está em `../academic-risk-model/models/production/`. Este será montado como um volume somente leitura no container.

## Executando os Serviços

### Iniciar todos os serviços:
```bash
docker-compose up -d
```

### Ver logs:
```bash
# Todos os serviços
docker-compose logs -f

# Serviço específico
docker-compose logs -f academic-risk-model
docker-compose logs -f academic-risk-app
```

### Parar todos os serviços:
```bash
docker-compose down
```

### Reiniciar um serviço específico:
```bash
docker-compose restart academic-risk-model
```

### Reconstruir serviços após mudanças no código:
```bash
docker-compose up -d --build
```

## Acessando os Serviços

Após iniciar os serviços, você pode acessar:

- **Frontend (Angular) + API Backend**: `http://localhost`
- **API do Modelo de Risco**: `http://localhost:5000`

A aplicação web automaticamente roteia as requisições de API:
- Requisições `/api/*` são tratadas pelo backend Express.js (porta 3000 dentro do container)
- O backend Express se comunica com a API do modelo de risco via nomes de serviços Docker

## Detalhes dos Serviços

### academic-risk-model
- **Porta**: 5000
- **Verificação de Saúde**: `http://localhost:5000/health`
- **Arquivos de Modelo**: Montados de `../academic-risk-model/models` (somente leitura)
- **Arquivos de Dados**: Montados de `../academic-risk-model/data` (somente leitura)
- **Variáveis de Ambiente**: 
  - `PORT=5000`: Porta da API
  - `LOG_LEVEL=INFO`: Nível de logging
  - `MODEL_PATH=models/production/model.joblib`: Caminho para o modelo de produção

### academic-risk-app
- **Porta**: 80 (mapeada para porta interna 3000)
- **Verificação de Saúde**: `http://localhost/api/health`
- **Dependências**: Aguarda academic-risk-model estar pronto
- **Variáveis de Ambiente**: 
  - `RISK_MODEL_URL=http://academic-risk-model:5000`: Aponta para o serviço do modelo de risco via rede Docker

## Rede

Todos os serviços se comunicam através de uma rede bridge Docker (`academic-risk-network`), permitindo que eles se referenciem pelo nome do serviço (ex: `academic-risk-model:5000`).

## Solução de Problemas

### Verificar saúde dos serviços:
```bash
docker-compose ps
```

### Ver logs dos serviços para erros:
```bash
docker-compose logs academic-risk-model
docker-compose logs academic-risk-app
```

### Reiniciar todos os serviços:
```bash
docker-compose restart
```

### Remover todos os containers e redes:
```bash
docker-compose down -v
```

### Verificar se as portas já estão em uso:
```bash
# Windows
netstat -ano | findstr :5000
netstat -ano | findstr :80

# Linux/Mac
lsof -i :5000
lsof -i :80
```

## Montagens de Volume

- **Arquivos de modelo**: `../academic-risk-model/models` → `/app/models` (somente leitura)
- **Arquivos de dados**: `../academic-risk-model/data` → `/app/data` (somente leitura)

Isso permite que você atualize arquivos de modelo e dados no host sem reconstruir o container.

## Fluxo de Trabalho de Desenvolvimento

1. Faça alterações no código nas pastas dos projetos de dependência
2. Reconstrua o serviço afetado: `docker-compose up -d --build <nome-do-serviço>`
3. Ou reconstrua todos os serviços: `docker-compose up -d --build`
4. Verifique os logs para confirmar as alterações: `docker-compose logs -f <nome-do-serviço>`

## Notas

- Os arquivos de modelo e dados são montados como volumes somente leitura, então você pode atualizá-los sem reconstruir containers
- O arquivo `docker-compose.yml` usa caminhos relativos (`../`) para referenciar os projetos de dependência no mesmo nível do diretório
- O container academic-risk-app serve tanto o frontend Angular quanto o backend Express.js em um único container

---
[Read in English](DOCKER_SETUP.md)
