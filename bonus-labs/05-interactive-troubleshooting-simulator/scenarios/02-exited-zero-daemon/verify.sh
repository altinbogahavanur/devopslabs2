#!/usr/bin/env bash

RUNNING=$(docker inspect -f '{{.State.Running}}' exit-web 2>/dev/null || echo "false")
STATUS=$(docker inspect -f '{{.State.Status}}' exit-web 2>/dev/null || echo "not found")

if [ "$RUNNING" = "true" ]; then
  echo "✅ TEBRİKLER! exit-web konteyneri ön planda (foreground) çalışacak şekilde onarıldı ve Status: Up durumunda!"
  exit 0
else
  echo "❌ HATA: exit-web konteyneri hala çalışmıyor (Durum: $STATUS)."
  echo "   İpucu: Docker PID 1 sürecini ön planda (daemon off;) çalıştırmalıdır."
  exit 1
fi
