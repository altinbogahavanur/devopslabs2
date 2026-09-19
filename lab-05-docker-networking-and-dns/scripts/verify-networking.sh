#!/usr/bin/env bash
# ==============================================================================
# LAB 05 - DOCKER NETWORKING DOĞRULAMA VE TESTİ
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "DOCKER AĞ MİMARİSİ VE DNS TESTİ BAŞLATILIYOR"
echo "=========================================================="

# 1. Temizlik
docker rm -f net-web net-db 2>/dev/null || true
docker network rm app-net 2>/dev/null || true

# 2. Custom Bridge Oluşturma
echo -e "\n[1/5] Kullanıcı Tanımlı Bridge Ağ Oluşturuluyor (app-net)..."
docker network create app-net
echo "✓ app-net ağı oluşturuldu."

# 3. Veritabanı Konteynerını Başlatma
echo -e "\n[2/5] PostgreSQL Konteyneri app-net üzerinde Başlatılıyor..."
docker run -d --name net-db --network app-net -e POSTGRES_PASSWORD=BilgincIT454 postgres:17-alpine
sleep 3
echo "✓ net-db çalışıyor."

# 4. Dahili DNS Çözümleme Testi (Embedded DNS)
echo -e "\n[3/5] Dahili DNS Test Ediliyor (busybox ping net-db)..."
DNS_IP=$(docker run --rm --network app-net busybox ping -c 1 net-db | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
echo "✓ Başarılı: net-db ismi başarıyla IP'ye çözüldü -> ${DNS_IP}"

# 5. Web Sunucusu ve Port Publishing
echo -e "\n[4/5] Nginx Web Sunucusu Başlatılıyor (8080:80)..."
docker run -d --name net-web --network app-net -p 8080:80 nginx:alpine
sleep 2
curl -s -I http://localhost:8080 | grep "HTTP/1.1 200 OK"
echo "✓ Port 8080 üzerinden Nginx erişimi doğrulandı."

# 6. None Network İzolasyon Testi
echo -e "\n[5/5] 'none' Ağ İzolasyonu Test Ediliyor..."
IFACES=$(docker run --rm --network none busybox ip addr | grep -E "^[0-9]+:" | awk '{print $2}')
echo "✓ Kullanılabilir Arayüzler: ${IFACES} (Sadece loopback 'lo', dış dünya yok!)"

# 7. Temizlik
echo -e "\n[TEMİZLİK] Test konteynerları ve ağ temizleniyor..."
docker rm -f net-web net-db >/dev/null
docker network rm app-net >/dev/null

echo -e "\n=========================================================="
echo "BAŞARILI: Docker Networking ve Dahili DNS kusursuz çalışıyor!"
echo "=========================================================="
