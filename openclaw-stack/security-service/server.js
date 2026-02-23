import express from "express";
import fetch from "node-fetch";

const app = express();
app.use(express.json());

const SECURE_TOKEN = process.env.SECURE_TOKEN;

function auth(req, res, next) {
  const token = req.headers.authorization;

  if (token !== `Bearer ${SECURE_TOKEN}`) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  next();
}

app.get("/api/electricity/bills", auth, async (req, res) => {
  const response = await fetch("http://scraper:4000/electricity");
  const data = await response.json();
  res.json(data);
});

app.get("/api/water/bills", auth, async (req, res) => {
  const response = await fetch("http://scraper:4000/water");
  const data = await response.json();
  res.json(data);
});

app.get("/api/school/bills", auth, async (req, res) => {
  const response = await fetch("http://scraper:4000/school");
  const data = await response.json();
  res.json(data);
});

app.listen(3000, () => {
  console.log("Security Service rodando na porta 3000");
});