#!/usr/bin/env bash
set -euo pipefail

docker rm -f port-occupier fixed-port-web broken-port-web 2>/dev/null || true

# 8080 portunu kitleyen süreci başlatıyoruz
docker run -d --name port-occupier -p 8080:80 nginx:alpine >/dev/null

echo "==> [SCEN-01] 8080 portu 'port-occupier' konteyneri tarafından kilitlendi."
echo "==> Hedef: 'fixed-port-web' konteynerini 8080 portundan HTTP 200 dönecek şekilde ayağa kaldırın."
