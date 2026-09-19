#!/usr/bin/env bash
set -euo pipefail

docker rm -f perm-app 2>/dev/null || true
rm -rf /tmp/perm-test
mkdir -p /tmp/perm-test
chmod 700 /tmp/perm-test

docker run -d --name perm-app -u 1000:1000 -v /tmp/perm-test:/data alpine \
  sh -c "while true; do echo 'log kaydi' >> /data/app.log 2>/tmp/err.log || sleep 1; sleep 1; done" >/dev/null

sleep 2
echo "==> [SCEN-05] 'perm-app' baslatildi ancak /tmp/perm-test dizinine yetki yetersizligi (Permission Denied) yuzunden yazamiyor."
echo "==> Hedef: /tmp/perm-test/app.log dosyasina basariyla log yazilmasini saglayin."
