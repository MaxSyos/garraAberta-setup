#!/bin/bash

set -e

# Run this script as a normal user, not root. It will use sudo when needed.

echo "\n=== garraAberta setup script ===\n"

# Ensure required commands are available
command -v curl >/dev/null 2>&1 || { echo "curl is required. Installing..."; sudo apt-get update && sudo apt-get install -y curl; }
command -v git >/dev/null 2>&1 || { echo "git is required. Installing..."; sudo apt-get update && sudo apt-get install -y git; }

# Install Docker if not installed
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found. Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo 
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER"
  echo "Docker instalado. Você pode precisar fechar e reabrir a sessão para aplicar o grupo docker."
else
  echo "Docker já instalado."
fi

# Install Docker Compose plugin if not installed
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose não encontrado. Instalando Docker Compose plugin..."
  sudo apt-get update
  sudo apt-get install -y docker-compose-plugin
else
  echo "Docker Compose já instalado."
fi

# Install bash (normalmente já instalado)
if ! command -v bash >/dev/null 2>&1; then
  echo "Bash não encontrado. Instalando bash..."
  sudo apt-get update
  sudo apt-get install -y bash
else
  echo "Bash já instalado."
fi

# Create required directories if missing
mkdir -p ./postgres ./hermes-data ./workspace

# Build and start containers
echo "Iniciando a aplicação Docker..."
docker compose up --build -d

echo "\n=== Setup concluído ==="

echo "Acesse localmente em http://localhost:8080"
echo "Se quiser usar ngrok, defina NGROK_AUTHTOKEN e reinicie com:"
echo "  export NGROK_AUTHTOKEN='seu_token'"
echo "  docker compose up -d"
