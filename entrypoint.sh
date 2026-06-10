#!/bin/bash

echo "Iniciando Hermes Agent..."

if command -v hermes >/dev/null 2>&1; then
  hermes --insecure dashboard --host 0.0.0.0 --port 8080
else
  echo "Comando hermes não encontrado."
  tail -f /dev/null
fi