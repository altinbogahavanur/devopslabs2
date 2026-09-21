#!/usr/bin/env bash
set -euo pipefail

echo "==> [SCEN-05 Çözüm] /tmp/perm-test izinleri düzenleniyor..."
chmod 777 /tmp/perm-test 2>/dev/null || sudo chown -R 1000:1000 /tmp/perm-test 2>/dev/null || true
sleep 2
ls -la /tmp/perm-test/app.log 2>/dev/null || true
