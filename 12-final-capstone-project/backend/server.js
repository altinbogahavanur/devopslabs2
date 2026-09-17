const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');

const app = express();
const port = process.env.PORT || 3000;

const dbPassword = fs.existsSync('/run/secrets/db_password')
  ? fs.readFileSync('/run/secrets/db_password', 'utf8').trim()
  : process.env.DB_PASSWORD || 'capstonesecret';

const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  user: process.env.DB_USER || 'capstone_user',
  password: dbPassword,
  database: process.env.DB_NAME || 'capstonedb',
  port: 5432
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', service: 'capstone-backend', timestamp: new Date().toISOString() });
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM products');
    res.json({ success: true, count: result.rows.length, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(port, () => console.log(`🚀 Capstone Backend dinleniyor: ${port}`));
