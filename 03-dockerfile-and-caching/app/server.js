const express = require('express');
const morgan = require('morgan');
const _ = require('lodash');

const app = express();
const PORT = process.env.PORT || 3000;
const BUILD_VERSION = process.env.BUILD_VERSION || "v1.0.0";

app.use(morgan('combined'));

app.get('/', (req, res) => {
    res.json({
        status: "success",
        message: "Docker Build Cache Dersi Başarıyla Çalışıyor!",
        version: BUILD_VERSION,
        timestamp: new Date().toISOString(),
        framework: "Express.js",
        random_hash: _.uniqueId("cache-demo-")
    });
});

app.get('/healthz', (req, res) => {
    res.status(200).send("OK");
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Sunucu 0.0.0.0:${PORT} üzerinde dinliyor [Sürüm: ${BUILD_VERSION}]`);
});
