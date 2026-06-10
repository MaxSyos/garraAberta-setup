#!/bin/bash
set -e

echo "Iniciando Hermes Agent..."

if command -v hermes >/dev/null 2>&1; then
  exec hermes dashboard --host 0.0.0.0 --port 8080 --insecure
else
  echo "Comando hermes não encontrado."
  tail -f /dev/null
fi
