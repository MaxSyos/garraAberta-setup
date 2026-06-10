# garraAberta-setup

## O que este projeto faz

Este projeto roda o Hermes Agent em Docker e expõe a interface em `http://localhost:8080`.

Também inclui um serviço opcional `ngrok` para expor o Hermes na internet.

## Como usar (sem precisar entender programação)

### 1. Criar um token ngrok

1. Acesse https://dashboard.ngrok.com/get-started/your-authtoken
2. Copie o token
3. No terminal do projeto, defina a variável:

```bash
export NGROK_AUTHTOKEN="seu_token_ngrok_aqui"
```

### 2. Iniciar o projeto

No diretório do projeto:

```bash
docker compose up --build -d
```

### 3. Acessar localmente

Abra no navegador:

- `http://localhost:8080`

### 4. Acessar pela internet via ngrok

Depois de iniciado, o ngrok cria um túnel para o serviço Hermes.

Para ver o URL público, use:

```bash
docker compose logs -f ngrok
```

Procure uma linha como:

```
url=tcp://... or url=https://xxxxx.ngrok.io
```

### 5. Parar o projeto

```bash
docker compose down
```

## O que foi adicionado

- serviço `ngrok` no `docker-compose.yml`
- `NGROK_AUTHTOKEN` lido de variável de ambiente
- documentação simples em `README.md`
