import express from "express";

const app = express();

app.get("/electricity", async (req, res) => {
  res.json({
    provider: "Energia",
    amount: 627,
    barcode: "MOCKED_BARCODE"
  });
});

app.get("/water", async (req, res) => {
  res.json({
    provider: "Água",
    amount: 120,
    barcode: "MOCKED_BARCODE"
  });
});

app.get("/school", async (req, res) => {
  res.json({
    provider: "Escola",
    amount: 900,
    barcode: "MOCKED_BARCODE"
  });
});

app.listen(4000, () => {
  console.log("Scraper rodando na porta 4000");
});