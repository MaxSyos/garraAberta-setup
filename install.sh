#!/bin/bash

set -e

echo "🚀 Instalando stack completa OpenClaw + SecureAPI + Gemini + Frontend"

DOMAIN="seudominio.com"
EMAIL="seuemail@email.com"

mkdir -p /opt/stack
cd /opt/stack

############################################
# 🔧 INSTALAR DEPENDÊNCIAS
############################################

apt update
apt install -y docker.io docker-compose nginx certbot python3-certbot-nginx ufw curl git

systemctl enable docker
systemctl start docker

############################################
# 🔐 FIREWALL
############################################

ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

############################################
# 🧠 DOCKER COMPOSE
############################################

cat > docker-compose.yml <<EOF
version: '3.8'

services:

  postgres:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: superpassword
      POSTGRES_DB: appdb
    volumes:
      - pgdata:/var/lib/postgresql/data

  secureapi:
    build: ./secureapi
    restart: always
    environment:
      DATABASE_URL: postgres://appuser:superpassword@postgres:5432/appdb
      GEMINI_API_KEY: "COLOQUE_SUA_GEMINI_API_KEY_AQUI"
      INTERNAL_TOKEN: "ROTATE_ME"
    depends_on:
      - postgres

  openclaw:
    image: ghcr.io/openclaw/openclaw:latest
    restart: always
    environment:
      SECURE_API_URL: http://secureapi:4000
      INTERNAL_TOKEN: "ROTATE_ME"
    depends_on:
      - secureapi

  frontend:
    build: ./frontend
    restart: always
    depends_on:
      - secureapi

volumes:
  pgdata:
EOF

############################################
# 🔐 SECURE API
############################################

mkdir -p secureapi
cd secureapi

cat > Dockerfile <<EOF
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]
EOF

cat > package.json <<EOF
{
  "name": "secureapi",
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.6.0",
    "pg": "^8.11.3",
    "jsonwebtoken": "^9.0.2",
    "bcrypt": "^5.1.0"
  }
}
EOF

cat > server.js <<'EOF'
const express = require("express");
const axios = require("axios");
const { Pool } = require("pg");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");

const app = express();
app.use(express.json());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const INTERNAL_TOKEN = process.env.INTERNAL_TOKEN;
const JWT_SECRET = "JWT_SECRET_CHANGE_ME";

//////////////////////////////////////////////////////
// 🔧 CRIAÇÃO AUTOMÁTICA DAS TABELAS
//////////////////////////////////////////////////////

async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email TEXT UNIQUE,
      password TEXT
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS data (
      id SERIAL PRIMARY KEY,
      type TEXT,
      content JSONB,
      ai_allowed BOOLEAN DEFAULT false,
      created_at TIMESTAMP DEFAULT NOW()
    );
  `);

  console.log("Banco inicializado com sucesso");
}

initDB();

//////////////////////////////////////////////////////
// 🔐 MIDDLEWARE DE AUTENTICAÇÃO JWT
//////////////////////////////////////////////////////

function auth(req, res, next) {
  const token = req.headers.authorization;
  if (!token) return res.sendStatus(401);

  try {
    jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    return res.sendStatus(403);
  }
}

//////////////////////////////////////////////////////
// 👤 REGISTRO DE USUÁRIO
//////////////////////////////////////////////////////

app.post("/register", async (req, res) => {
  const { email, password } = req.body;

  const hash = await bcrypt.hash(password, 10);

  try {
    await pool.query(
      "INSERT INTO users(email,password) VALUES($1,$2)",
      [email, hash]
    );
    res.sendStatus(201);
  } catch (err) {
    res.status(400).json({ error: "Usuário já existe" });
  }
});

//////////////////////////////////////////////////////
// 🔑 LOGIN
//////////////////////////////////////////////////////

app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  const user = await pool.query(
    "SELECT * FROM users WHERE email=$1",
    [email]
  );

  if (!user.rows.length) return res.sendStatus(401);

  const match = await bcrypt.compare(password, user.rows[0].password);

  if (!match) return res.sendStatus(401);

  const token = jwt.sign(
    { id: user.rows[0].id },
    JWT_SECRET,
    { expiresIn: "12h" }
  );

  res.json({ token });
});

//////////////////////////////////////////////////////
// 📝 CRUD GENÉRICO AUTENTICADO
//////////////////////////////////////////////////////

app.post("/data", auth, async (req, res) => {
  const { type, content, ai_allowed } = req.body;

  await pool.query(
    `INSERT INTO data(type, content, ai_allowed)
     VALUES ($1,$2,$3)`,
    [type, content, ai_allowed || false]
  );

  res.sendStatus(201);
});

app.get("/data", auth, async (req, res) => {
  const data = await pool.query(
    "SELECT * FROM data ORDER BY created_at DESC"
  );
  res.json(data.rows);
});

//////////////////////////////////////////////////////
// 🤖 ACESSO FILTRADO PARA OPENCLAW
//////////////////////////////////////////////////////

app.post("/internal-search", async (req, res) => {
  if (req.headers["x-internal-token"] !== INTERNAL_TOKEN)
    return res.sendStatus(403);

  const { keyword, type, limit } = req.body;

  let query = `
    SELECT id, type, content, created_at
    FROM data
    WHERE ai_allowed = true
  `;

  const values = [];
  let index = 1;

  if (type) {
    query += ` AND type = $${index++}`;
    values.push(type);
  }

  if (keyword) {
    query += ` AND content::text ILIKE $${index++}`;
    values.push('%' + keyword + '%');
  }

  query += ` ORDER BY created_at DESC`;

  if (limit) {
    query += ` LIMIT $${index++}`;
    values.push(limit);
  } else {
    query += ` LIMIT 20`;
  }

  const result = await pool.query(query, values);
  res.json(result.rows);
});

//////////////////////////////////////////////////////
// 🔍 BUSCA POR ID (SOMENTE SE AI_ALLOWED = TRUE)
//////////////////////////////////////////////////////

app.get("/internal-data/:id", async (req, res) => {
  if (req.headers["x-internal-token"] !== INTERNAL_TOKEN)
    return res.sendStatus(403);

  const result = await pool.query(
    `SELECT id, type, content, created_at
     FROM data
     WHERE id = $1 AND ai_allowed = true`,
    [req.params.id]
  );

  if (!result.rows.length) return res.sendStatus(404);

  res.json(result.rows[0]);
});

//////////////////////////////////////////////////////
// 🧠 PROXY PARA GEMINI (APENAS OPENCLAW)
//////////////////////////////////////////////////////

app.post("/gemini", async (req, res) => {
  if (req.headers["x-internal-token"] !== INTERNAL_TOKEN)
    return res.sendStatus(403);

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" +
        process.env.GEMINI_API_KEY,
      {
        contents: [{ parts: [{ text: req.body.prompt }] }]
      }
    );

    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: "Erro ao chamar Gemini" });
  }
});

//////////////////////////////////////////////////////

app.listen(4000, () =>
  console.log("SecureAPI rodando na porta 4000")
);
EOF

cd ..

############################################
# 🌐 FRONTEND NEXTJS
############################################

mkdir frontend
cd frontend

cat > Dockerfile <<EOF
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
CMD ["npm","start"]
EOF

cat > package.json <<EOF
{
  "name":"frontend",
  "scripts":{
    "dev":"next dev",
    "build":"next build",
    "start":"next start -p 3000"
  },
  "dependencies":{
    "next":"14",
    "react":"18",
    "react-dom":"18",
    "axios":"^1.6.0"
  }
}
EOF

mkdir pages

cat > pages/index.js <<'EOF'
import {useState} from "react";
import axios from "axios";

export default function Home(){
  const [text,setText]=useState("");
  const send=async()=>{
    await axios.post("/api/data",{content:text});
  }
  return(
    <div>
      <h1>Cadastro Livre</h1>
      <textarea onChange={e=>setText(e.target.value)} />
      <button onClick={send}>Salvar</button>
    </div>
  )
}
EOF

cd ..

############################################
# 🔥 SUBIR TUDO
############################################

docker-compose up -d --build

############################################
# 🌍 NGINX
############################################

cat > /etc/nginx/sites-available/app <<EOF
server {
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
    }

    location /api/ {
        proxy_pass http://localhost:4000/;
    }
}
EOF

ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

############################################
# 🔐 HTTPS
############################################

certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

echo "✅ INSTALAÇÃO COMPLETA"
echo "Acesse: https://$DOMAIN"