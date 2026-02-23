import express from "express";
import httpProxy from "http-proxy";

const app = express();
const proxy = httpProxy.createProxyServer({});

app.use((req, res) => {
  proxy.web(req, res, { target: "https://site-real.com" });
});

app.listen(8080, () => {
  console.log("Proxy rodando na 8080");
});