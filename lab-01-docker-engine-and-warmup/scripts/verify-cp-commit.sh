#!/usr/bin/env bash
# ==============================================================================
# Script: verify-cp-commit.sh
# Amac: docker cp ve docker commit Mekanizmalarinin Test Edilmesi
# ==============================================================================
set -euo pipefail

CONTAINER_NAME="test-web-server"
NEW_IMAGE_NAME="custom-nginx:v1.0"

echo "=========================================================="
echo ">>> [1/5] Standart Nginx Konteyneri Baslatiliyor..."
echo "=========================================================="
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
docker run -d --name "$CONTAINER_NAME" -p 8081:80 nginx:alpine

sleep 2

echo "=========================================================="
echo ">>> [2/5] docker cp ile Hosttan Konteynera Dosya Kopyalama..."
echo "=========================================================="
# app/index.html dosyasini calisan konteynerin web kok dizinine kopyalama
docker cp app/index.html "$CONTAINER_NAME":/usr/share/nginx/html/index.html
echo "[+] Dosya konteynera basariyla aktarildi."

# Test etme
curl -s http://localhost:8081 | grep -q "Docker Konteyner Temelleri"
echo "[OK] Nginx yeni HTML dosyasini basariyla yanitliyor!"

echo "=========================================================="
echo ">>> [3/5] docker cp ile Konteynerdan Hosta Dosya Cekme..."
echo "=========================================================="
# Konteyner icindeki varsayilan nginx config dosyasini disari cekme
mkdir -p /tmp/extracted-configs
docker cp "$CONTAINER_NAME":/etc/nginx/nginx.conf /tmp/extracted-configs/nginx.conf
ls -lh /tmp/extracted-configs/nginx.conf
echo "[OK] Nginx konfigrasyon dosyasi host makineye basariyla alindi."

echo "=========================================================="
echo ">>> [4/5] docker commit ile Calisan Durumu Yeni Imaj Yapma..."
echo "=========================================================="
docker commit -m "index.html guncellendi" "$CONTAINER_NAME" "$NEW_IMAGE_NAME"
docker images "$NEW_IMAGE_NAME"
echo "[OK] Yeni imaj olusturuldu: $NEW_IMAGE_NAME"

echo "=========================================================="
echo ">>> [5/5] Yeni Imajdan Konteyner Baslatma ve Dogrulama..."
echo "=========================================================="
docker rm -f "$CONTAINER_NAME"
docker run -d --name "${CONTAINER_NAME}-committed" -p 8082:80 "$NEW_IMAGE_NAME"
sleep 2

curl -s http://localhost:8082 | grep -q "Docker Konteyner Temelleri"
echo "[OK] Committed imaj uzerinden calisan konteyner dogrulandi!"

# Temizlik
docker rm -f "${CONTAINER_NAME}-committed"
echo -e "\n[+] Testler basariyla tamamlandi."
