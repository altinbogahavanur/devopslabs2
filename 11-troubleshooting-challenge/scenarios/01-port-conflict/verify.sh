#!/usr/bin/env bash

RUNNING=$(docker inspect -f '{{.State.Running}}' fixed-port-web 2>/dev/null || echo "false")
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null || echo "000")

if [ "$RUNNING" = "true" ] && [ "$HTTP_CODE" = "200" ]; then
  echo "✅ TEBRİKLER! fixed-port-web konteyneri 8080 portunda başarıyla çalışıyor ve HTTP 200 yanıtı veriyor!"
  exit 0
else
  echo "❌ HATA: Hedef henüz karşılanmadı!"
  echo "   fixed-port-web çalışıyor mu: $RUNNING"
  echo "   http://localhost:8080 HTTP Kodu: $HTTP_CODE (Beklenen: 200)"
  echo "   İpucu: 8080 portunu tutan eski konteyneri silip fixed-port-web konteynerini başlatın."
  exit 1
fi
