#!/usr/bin/env bash
set -euo pipefail

echo "==> [SCEN-03 Çözüm] memory-crasher 256m bellek sınırı ile başlatılıyor..."
docker rm -f memory-crasher 2>/dev/null || true
docker run -d --name memory-crasher --memory 256m python:3.12-alpine \
  python3 -c "import time; a = 'x' * (80 * 1024 * 1024); time.sleep(60)"
sleep 1
