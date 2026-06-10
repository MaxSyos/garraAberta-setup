# 🚀 Início Rápido - garraAberta

## Um único comando para tudo

Em um Linux recém instalado com apenas **conexão à internet**:

### Modo remoto (recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/MaxSyos/garraAberta-setup/main/install.sh | bash
```

Isso vai:
✅ Instalar git, bash, curl e wget (se faltar)
✅ Clonar o repositório automaticamente
✅ Instalar Docker e Docker Compose
✅ Iniciar a aplicação Hermes
✅ Mostrar o endereço para acessar

### Resultado

Quando terminar, acesse:

```
http://localhost:8080
```

## Modo local (já dentro do diretório clonado)

Se você já clonou o repositório:

```bash
./install.sh
```

## Com ngrok (expor na internet)

Antes de rodar o comando, defina seu token:

```bash
export NGROK_AUTHTOKEN="seu_token_aqui"
curl -fsSL https://raw.githubusercontent.com/MaxSyos/garraAberta-setup/main/install.sh | bash
```

Obtenha o token em: https://dashboard.ngrok.com/get-started/your-authtoken

## Comandos úteis

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

### Ver URL público do ngrok
```bash
docker compose logs -f ngrok
```

## Requisitos

- Linux baseado em Debian/Ubuntu
- Conexão à internet
- Acesso a sudo (senha será solicitada)

---

**É isso!** 🎉 Um comando e tudo funciona.

