#!/usr/bin/env bash
set -euo pipefail

echo "==> [SCEN-04 Çözüm] Özel bridge ağı oluşturuluyor ve konteynerler bağlanıyor..."
docker network create custom-net 2>/dev/null || true
docker network connect custom-net srv-db 2>/dev/null || true
docker network connect custom-net srv-app 2>/dev/null || true
sleep 1
