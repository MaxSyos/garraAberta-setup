#!/bin/sh

set -eu

# garraAberta - Script de Instalação Completo
# Execute uma única vez (modo remoto):
#   curl -fsSL https://raw.githubusercontent.com/MaxSyos/garraAberta-setup/main/install.sh | sh
# Ou se já tiver o repositório local:
#   ./install.sh

echo "=== garraAberta - Setup Completo ==="
echo ""

# Diretório de instalação
INSTALL_DIR="."

# Detecta pipe (curl | sh)
if [ ! -t 0 ]; then
  INSTALL_DIR=$(mktemp -d)
  echo "Modo de instalação remota detectado..."
  echo "Diretório de trabalho: $INSTALL_DIR"
fi

# Verifica se é um sistema baseado em Debian/Ubuntu
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Erro: Este script suporta apenas sistemas baseados em Debian/Ubuntu."
  if [ -f /etc/os-release ]; then
    grep '^NAME=' /etc/os-release | head -1
  fi
  exit 1
fi

# Detecta se é root ou se sudo está disponível
if [ "$(id -u)" = "0" ]; then
  SUDO=""
else
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Erro: usuário não root e sudo não está disponível."
    echo "Instale sudo ou execute este script como root."
    exit 1
  fi
fi

# Se for modo remoto, instala git antes de clonar
if [ ! -t 0 ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "Git não encontrado. Instalando git..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq git curl wget ca-certificates
  fi
  echo "Clonando repositório..."
  git clone https://github.com/MaxSyos/garraAberta-setup.git "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Se não estiver dentro do repositório, avisa
if [ ! -f ./docker-compose.yml ]; then
  echo "Erro: docker-compose.yml não encontrado no diretório atual."
  echo "Execute este script dentro do repositório garraAberta-setup."
  exit 1
fi

# Atualiza repositórios
echo "Atualizando repositórios..."
$SUDO apt-get update -qq

# Instala dependências básicas
echo "Instalando dependências básicas..."
DEPS="ca-certificates curl gnupg lsb-release git wget"
$SUDO apt-get install -y -qq $DEPS

# Instala Docker se não estiver instalado
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker não encontrado. Instalando Docker..."
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  DISTRO=$(lsb_release -cs 2>/dev/null || echo "jammy")
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $DISTRO stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin
  echo "Adicionando usuário ao grupo docker..."
  $SUDO usermod -aG docker "$(id -un)"
  echo ""
  echo "⚠️  IMPORTANTE: execute 'newgrp docker' para aplicar as permissões docker, ou abra uma nova sessão."
  echo "Depois execute este script novamente."
  exit 0
else
  echo "✓ Docker já instalado"
fi

# Descobre se precisa usar sudo para Docker
echo "Verificando acesso ao Docker..."
DOCKER_CMD="docker"
if ! $DOCKER_CMD ps >/dev/null 2>&1; then
  if [ -n "$SUDO" ] && $SUDO docker ps >/dev/null 2>&1; then
    DOCKER_CMD="$SUDO docker"
    echo "✓ Usando sudo para executar Docker nesta sessão."
  else
    echo "Erro: Docker está instalado mas não pode ser executado."
    echo "Verifique se o usuário está no grupo docker ou execute 'newgrp docker'."
    exit 1
  fi
fi

# Verifica Docker Compose
echo "Verificando Docker Compose..."
if ! $DOCKER_CMD compose version >/dev/null 2>&1; then
  echo "Docker Compose não encontrado. Instalando..."
  $SUDO apt-get install -y -qq docker-compose-plugin
else
  echo "✓ Docker Compose já instalado"
fi

# Cria diretórios necessários
echo "Preparando diretórios..."
mkdir -p ./postgres ./hermes-data ./workspace

# Inicia os containers
echo ""
echo "Iniciando a aplicação Docker (primeira vez pode demorar...)..."
$DOCKER_CMD compose up --build -d

# Aguarda o Hermes iniciar
echo "Aguardando Hermes iniciar..."
count=1
while [ "$count" -le 30 ]; do
  if command -v curl >/dev/null 2>&1 && curl -s http://localhost:8080 >/dev/null 2>&1; then
    echo ""
    echo "✓ Hermes está online!"
    break
  fi
  printf "."
  count=$((count + 1))
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
if [ -z "${NGROK_AUTHTOKEN:-}" ]; then
  echo "Para usar ngrok (expor na internet):"
  echo "  export NGROK_AUTHTOKEN='seu_token_aqui'"
  echo "  docker compose up -d"
fi
