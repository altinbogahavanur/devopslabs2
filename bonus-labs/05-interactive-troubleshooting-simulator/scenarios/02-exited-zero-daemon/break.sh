#!/usr/bin/env bash
set -euo pipefail

docker rm -f exit-web 2>/dev/null || true

docker run -d --name exit-web nginx:alpine nginx >/dev/null

echo "==> [SCEN-02] 'exit-web' konteyneri baslatildi ancak aninda kapandi (Exit Code 0)."
echo "==> Hedef: 'exit-web' konteynerinin kapanmadan Status: Up (Running) kalmasini saglayin."
