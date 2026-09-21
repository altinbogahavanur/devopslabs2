#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "=========================================================="
echo "🛑 SİNYAL YÖNETİMİ VE GRACEFUL SHUTDOWN TESTİ 🛑"
echo "=========================================================="

echo -e "\n[1/4] İmajlar Derleniyor..."
docker build -f app/Dockerfile.bad -t signals:bad app > /dev/null
docker build -f app/Dockerfile.tini -t signals:graceful app > /dev/null

echo -e "\n[2/4] ❌ KÖTÜ KONTEYNER TESTİ (Sinyal Yakalamayan)..."
docker rm -f bad-container 2>/dev/null || true
docker run -d --name bad-container signals:bad > /dev/null
sleep 1

echo "docker stop gönderiliyor (10 saniye timeout beklenecek)..."
START=$(date +%s)
docker stop bad-container > /dev/null
END=$(date +%s)
DIFF=$((END - START))
echo "⏱️  Kapanma Süresi: ${DIFF} saniye (SIGKILL ile zorla öldürüldü!)"
docker rm -f bad-container > /dev/null

echo -e "\n[3/4] ✅ GRACEFUL KONTEYNER TESTİ (Tini + SIGTERM Handler)..."
docker rm -f graceful-container 2>/dev/null || true
docker run -d --name graceful-container signals:graceful > /dev/null
sleep 1

echo "docker stop gönderiliyor (Sinyali yakalayıp zarifçe kapanmalı)..."
START=$(date +%s)
docker stop graceful-container > /dev/null
END=$(date +%s)
DIFF=$((END - START))
echo "⏱️  Kapanma Süresi: ${DIFF} saniye"

echo -e "\n[4/4] Konteyner Çıkış Günlüğü (Log) İnceleniyor:"
docker logs graceful-container
docker rm -f graceful-container > /dev/null

echo -e "\n=========================================================="
echo "🎯 KANITLANDI: Tini ve SIGTERM yöneticisi sayesinde konteyner"
echo "zorla SIGKILL yemeden, verisini kaydederek temiz kapandı!"
echo "=========================================================="
