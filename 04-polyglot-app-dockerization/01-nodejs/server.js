const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('<html><body style="font-family:sans-serif;background:#0d1117;color:#c9d1d9;padding:40px;"><h1>🐳 DevOps Atölyesi - Node.js API</h1><p>Dockerize edilmis Express.js web uygulamasi basariyla calisiyor.</p></body></html>\n');
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/info', (req, res) => {
  res.json({
    name: 'devops-node-api',
    version: '1.0.0',
    node: process.version,
    port: PORT
  });
});

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Node.js Sunucu calisiyor: http://0.0.0.0:${PORT}`);
  });
}

module.exports = app;
