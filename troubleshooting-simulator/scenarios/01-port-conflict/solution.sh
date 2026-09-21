#!/usr/bin/env bash
set -euo pipefail

echo "==> [SCEN-01 Çözüm] Çakışan süreçler temizleniyor..."
docker rm -f port-occupier broken-port-web fixed-port-web 2>/dev/null || true

echo "==> fixed-port-web konteyneri 8080 portunda başlatılıyor..."
docker run -d --name fixed-port-web -p 8080:80 nginx:alpine
sleep 1
