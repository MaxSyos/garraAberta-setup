# garraAberta-setup

## 🚀 Instalação em um comando

Em um Linux recém instalado com apenas **conexão à internet**:

```bash
curl -fsSL https://raw.githubusercontent.com/MaxSyos/garraAberta-setup/main/install.sh | bash
```

**É isso!** O script vai:
- ✅ Instalar git, bash, curl, wget
- ✅ Clonar o repositório
- ✅ Instalar Docker e Docker Compose  
- ✅ Iniciar a aplicação Hermes

Depois de alguns minutos, acesse: **`http://localhost:8080`**

## 📖 Instruções detalhadas

Veja [QUICK_START.md](QUICK_START.md) para mais informações.

## 🔧 Comandos úteis

### Parar a aplicação
```bash
docker compose down
```

### Reiniciar
```bash
docker compose up -d
```

### Ver logs
```bash
docker compose logs -f hermes
```

### Com ngrok (internet)
```bash
export NGROK_AUTHTOKEN="seu_token"
docker compose up -d
docker compose logs -f ngrok
```

## 📋 Requisitos

- Linux Debian/Ubuntu
- Conexão à internet
- Acesso a sudo

---

**Pronto para usar!** 🎉

