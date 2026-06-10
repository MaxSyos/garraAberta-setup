#!/bin/bash

set -e

# garraAberta - Script de Instalação Completo
# Execute uma única vez: curl -fsSL https://raw.githubusercontent.com/MaxSyos/garraAberta-setup/main/install.sh | bash

echo "=== garraAberta - Setup Completo ==="
echo ""

# Detecta se está rodando como pipe (curl | bash)
if [ -t 0 ]; then
  # Modo interativo
  INSTALL_DIR="${1:-.}"
else
  # Modo pipe - cria diretório temporário e clona repositório
  echo "Modo de instalação remota detectado..."
  INSTALL_DIR=$(mktemp -d)
  echo "Diretório de trabalho: $INSTALL_DIR"
  
  # Verifica se é um sistema baseado em Debian
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Erro: Este script suporta apenas sistemas baseados em Debian/Ubuntu."
    exit 1
  fi
  
  # Instala git se não estiver presente
  if ! command -v git >/dev/null 2>&1; then
    echo "Git não encontrado. Instalando git..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl wget ca-certificates 2>&1 | grep -v "^Reading\|^Building\|^Selecting" || true
  fi
  
  # Clona repositório
  echo "Clonando repositório..."
  git clone https://github.com/MaxSyos/garraAberta-setup.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Verifica se é um sistema baseado em Debian
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Erro: Este script suporta apenas sistemas baseados em Debian/Ubuntu."
  echo "Detectado: $(cat /etc/os-release 2>/dev/null | grep NAME | head -1)"
  exit 1
fi

# Verifica se o usuário pode usar sudo
echo "Configurando permissões sudo..."
if ! sudo -n true 2>/dev/null; then
  echo "Por favor, digite sua senha quando solicitado."
  sudo -v
fi

# Update inicial
echo "Atualizando repositórios..."
sudo apt-get update -qq

# Instala dependências básicas
echo "Instalando dependências..."
DEPS="ca-certificates curl gnupg lsb-release git bash wget"
sudo apt-get install -y -qq $DEPS 2>&1 | grep -v "^Reading\|^Building\|^Selecting" || true

# Instala Docker se não estiver instalado
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker não encontrado. Instalando Docker..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  DISTRO=$(lsb_release -cs 2>/dev/null || echo "jammy")
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $DISTRO stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>&1 | grep -v "^Reading\|^Building\|^Selecting" || true
  
  echo "Adicionando usuário ao grupo docker..."
  sudo usermod -aG docker "$USER"
  
  echo ""
  echo "⚠️  IMPORTANTE: Execute o comando abaixo para aplicar as permissões docker:"
  echo "   newgrp docker"
  echo ""
  echo "Depois execute este script novamente."
  exit 0
else
  echo "✓ Docker já instalado"
fi

# Verifica se pode rodar docker sem sudo
if ! docker ps >/dev/null 2>&1; then
  echo "Erro: Não consegui rodar docker sem sudo."
  echo "Execute 'newgrp docker' e tente novamente."
  exit 1
fi

# Verifica Docker Compose
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose não encontrado. Instalando..."
  sudo apt-get install -y -qq docker-compose-plugin 2>&1 | grep -v "^Reading\|^Building\|^Selecting" || true
else
  echo "✓ Docker Compose já instalado"
fi

# Cria diretórios necessários
echo "Preparando diretórios..."
mkdir -p ./postgres ./hermes-data ./workspace

# Inicia os containers
echo ""
echo "Iniciando a aplicação Docker (primeira vez pode demorar...)..."
docker compose up --build -d

# Aguarda o Hermes iniciar
echo "Aguardando Hermes iniciar..."
for i in {1..30}; do
  if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✓ Hermes está online!"
    break
  fi
  echo -n "."
  sleep 2
done

echo ""
echo "=== Setup concluído com sucesso ==="
echo ""
echo "Acesse em: http://localhost:8080"
echo ""
echo "Para parar: docker compose down"
echo "Para reiniciar: docker compose up -d"
echo ""
if [ -z "$NGROK_AUTHTOKEN" ]; then
  echo "Para usar ngrok (expor na internet):"
  echo "  export NGROK_AUTHTOKEN='seu_token_aqui'"
  echo "  docker compose up -d"
fi
