#!/usr/bin/env bash
set -euo pipefail

docker rm -f memory-crasher 2>/dev/null || true

docker run -d --name memory-crasher --memory 32m python:3.12-alpine \
  python3 -c "import time; a = 'x' * (80 * 1024 * 1024); time.sleep(60)" >/dev/null || true

sleep 2
echo "==> [SCEN-03] 'memory-crasher' baslatildi ancak bellek asimiyla (Exit Code 137 / OOMKilled) coktu."
echo "==> Hedef: 'memory-crasher' konteynerinin bellek sinirini optimize ederek Status: Up (Running) kalmasini saglayin."
