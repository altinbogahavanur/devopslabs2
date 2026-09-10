#!/usr/bin/env bash
# ==============================================================================
# Script: verify-backup-restore.sh
# Amac: save/load, export/import ve Named Volume Yedekleme/Kurtarma Testi
# ==============================================================================
set -euo pipefail

BACKUP_DIR="/tmp/docker-backup-lab"
mkdir -p "$BACKUP_DIR"

echo "=========================================================="
echo ">>> [1/4] TEST 1: 'docker save' ve 'docker load' Testi..."
echo "=========================================================="
docker pull alpine:latest
docker tag alpine:latest test-alpine:backup-v1

# Imajı tar olarak diske kaydetme
docker save -o "$BACKUP_DIR/test-alpine.tar" test-alpine:backup-v1
ls -lh "$BACKUP_DIR/test-alpine.tar"

# Imajı yerelden silme
docker rmi test-alpine:backup-v1

# Tar dosyasından geri yukleme
docker load -i "$BACKUP_DIR/test-alpine.tar"
docker images test-alpine:backup-v1
echo "[OK] 'docker save' ve 'docker load' basariyla dogrulandi!"

echo "=========================================================="
echo ">>> [2/4] TEST 2: 'docker export' ve 'docker import' Testi..."
echo "=========================================================="
docker run -d --name temp-exporter alpine:latest sleep 3600
docker exec temp-exporter sh -c "echo 'Gizli Veri 123' > /root/secret.txt"

# Konteyner dosya sistemini tar olarak export etme
docker export -o "$BACKUP_DIR/container-fs.tar" temp-exporter
docker rm -f temp-exporter

# Tar'dan sifir katmanli yeni imaj import etme
docker import "$BACKUP_DIR/container-fs.tar" imported-alpine:v1
docker run --rm imported-alpine:v1 cat /root/secret.txt
echo "[OK] 'docker export' ve 'docker import' basariyla dogrulandi!"

echo "=========================================================="
echo ">>> [3/4] TEST 3: PostgreSQL Named Volume Yedekleme (Backup)..."
echo "=========================================================="
VOLUME_NAME="demo-pg-volume"
docker volume rm -f "$VOLUME_NAME" 2>/dev/null || true
docker volume create "$VOLUME_NAME"

# PostgreSQL baslatma ve veri yazma
docker run -d --name pg-test \
    -e POSTGRES_PASSWORD=secret123 \
    -e POSTGRES_DB=devopsdb \
    -v "$VOLUME_NAME":/var/lib/postgresql/data \
    postgres:16-alpine

echo "Veritabani hazirlaniyor (10s)..."
sleep 10
docker exec pg-test psql -U postgres -d devopsdb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO users (name) VALUES ('Hakan'), ('DevOps-Learner');"

# Yardimci konteyner (Helper container) ile salt-okunur volume yedegi alma
docker run --rm \
    -v "$VOLUME_NAME":/source:ro \
    -v "$BACKUP_DIR":/backup \
    alpine:latest \
    tar -czf /backup/pg-volume-backup.tar.gz -C /source .

ls -lh "$BACKUP_DIR/pg-volume-backup.tar.gz"
echo "[OK] Volume yedegi basariyla alindi!"

echo "=========================================================="
echo ">>> [4/4] TEST 4: Felaket Kurtarma (Disaster Recovery - Restore)..."
echo "=========================================================="
# Konteyneri ve veritabanı volume'unu SILEREK felaket senaryosu olusturma
docker rm -f pg-test
docker volume rm "$VOLUME_NAME"
echo "[!] Veritabani volume'u tamamen silindi (Veri kaybi olusturuldu)."

# Sifirdan yeni volume olusturma
RESTORED_VOLUME="restored-pg-volume"
docker volume create "$RESTORED_VOLUME"

# Yedekten yeni volume'a geri yukleme
docker run --rm \
    -v "$RESTORED_VOLUME":/target \
    -v "$BACKUP_DIR":/backup \
    alpine:latest \
    tar -xzf /backup/pg-volume-backup.tar.gz -C /target

# Yeni volume ile PostgreSQL baslatma
docker run -d --name pg-restored \
    -e POSTGRES_PASSWORD=secret123 \
    -e POSTGRES_DB=devopsdb \
    -v "$RESTORED_VOLUME":/var/lib/postgresql/data \
    postgres:16-alpine

sleep 8
# Verilerin kayipsiz geri geldigini dogrulama
USER_COUNT=$(docker exec pg-restored psql -U postgres -d devopsdb -t -c "SELECT COUNT(*) FROM users;" | xargs)

if [ "$USER_COUNT" -eq 2 ]; then
    echo "[OK] FELAKET KURTARMA BASARILI! Kullanici sayisi eksiksiz: $USER_COUNT"
    docker exec pg-restored psql -U postgres -d devopsdb -c "SELECT * FROM users;"
else
    echo "[HATA] Veri kurtarma basarisiz oldu!"
    exit 1
fi

# Temizlik
docker rm -f pg-restored
docker volume rm "$RESTORED_VOLUME"
rm -rf "$BACKUP_DIR"
echo -e "\n[+] TUM YEDEKLEME VE KURTARMA TESTLERI BASARIYLA GECTI!"
