#!/usr/bin/env bash
set -euo pipefail

docker rm -f srv-db srv-app 2>/dev/null || true
docker network rm custom-net 2>/dev/null || true

docker run -d --name srv-db alpine sleep 3600 >/dev/null
docker run -d --name srv-app alpine sleep 3600 >/dev/null

echo "==> [SCEN-04] 'srv-db' ve 'srv-app' varsayilan kopru (default bridge) uzerinde baslatildi."
echo "==> Hedef: 'srv-app' icinden 'srv-db' ismine basarili ping atilabilmesini saglayin."
