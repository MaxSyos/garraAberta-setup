FROM node:22

RUN npm install -g openclaw@latest

WORKDIR /app

CMD ["openclaw", "gateway", "--port", "18789", "--bind", "lan", "--allow-unconfigured"]