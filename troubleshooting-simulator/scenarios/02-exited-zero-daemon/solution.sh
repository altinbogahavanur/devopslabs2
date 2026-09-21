#!/usr/bin/env bash
set -euo pipefail

echo "==> [SCEN-02 Çözüm] exit-web ön plan direktifiyle başlatılıyor..."
docker rm -f exit-web 2>/dev/null || true
docker run -d --name exit-web nginx:alpine nginx -g "daemon off;"
sleep 1
