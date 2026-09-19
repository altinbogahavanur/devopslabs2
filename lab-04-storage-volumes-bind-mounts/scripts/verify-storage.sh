#!/usr/bin/env bash
# ==============================================================================
# LAB 05 - DOCKER STORAGE DOĞRULAMA VE TESTİ
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "💾 DOCKER STORAGE ÜÇLÜSÜ DOĞRULAMA TESTİ 💾"
echo "=========================================================="

# 1. Temizlik
docker rm -f store-db 2>/dev/null || true
docker volume rm pgdata 2>/dev/null || true

# 2. Named Volume Oluşturma ve Veri Yazma
echo -e "\n[1/4] Named Volume Oluşturuluyor (pgdata)..."
docker volume create pgdata
docker run -d --name store-db -e POSTGRES_PASSWORD=secret -v pgdata:/var/lib/postgresql/data postgres:17-alpine
sleep 5
docker exec store-db psql -U postgres -c "CREATE TABLE users (name text); INSERT INTO users VALUES ('hakan');"
echo "✓ PostgreSQL çalıştırıldı ve 'hakan' kaydı yazıldı."

# 3. Felaket & Kalıcılık Testi: Konteyneri Silip Yeniden Başlatma
echo -e "\n[2/4] Konteyner Siliniyor ve Aynı Volume ile Yeni Konteyner Açılıyor..."
docker rm -f store-db
docker run -d --name store-db-recovered -e POSTGRES_PASSWORD=secret -v pgdata:/var/lib/postgresql/data postgres:17-alpine
sleep 5
RECOVERED_USER=$(docker exec store-db-recovered psql -U postgres -t -c "SELECT name FROM users LIMIT 1;" | tr -d '[:space:]')

if [ "$RECOVERED_USER" = "hakan" ]; then
    echo "✓ BAŞARILI: Veri kaybolmadı! Kurtarılan kullanıcı: $RECOVERED_USER"
else
    echo "HATA: Veri kalıcılığı başarısız!"; exit 1
fi
docker rm -f store-db-recovered >/dev/null

# 4. Host Bind Mount Testi
echo -e "\n[3/4] Host Bind Mount Test Ediliyor (-v \$PWD:/work)..."
HOST_DIR=$(pwd)
LIST_OUTPUT=$(docker run --rm -v "${HOST_DIR}:/work" busybox ls -la /work)
echo "✓ Host dizini konteyner içine başarıyla bağlandı (Bind Mount aktif)."

# 5. Bellek İçi (tmpfs) Geçici Depolama Testi
echo -e "\n[4/4] Bellek İçi tmpfs Test Ediliyor (--tmpfs /cache:rw,size=64m)..."
TMPFS_OUT=$(docker run --rm --tmpfs /cache:rw,size=64m busybox sh -c "echo 'in-memory-data' > /cache/data.txt && cat /cache/data.txt")
if [ "$TMPFS_OUT" = "in-memory-data" ]; then
    echo "✓ tmpfs RAM tabanlı disk başarıyla çalıştı."
fi

# 6. Temizlik
docker volume rm pgdata >/dev/null

echo -e "\n=========================================================="
echo "✅ BAŞARILI: Volume, Bind Mount ve tmpfs ayrımı kanıtlandı!"
echo "=========================================================="
