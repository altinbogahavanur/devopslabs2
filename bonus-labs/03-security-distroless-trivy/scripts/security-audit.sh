#!/bin/bash
set -e

cd "$(dirname "$0")/.."

echo "=========================================================="
echo "🛡️  KONTEYNER GÜVENLİK VE SERTLEŞTİRME TESTİ 🛡️"
echo "=========================================================="

echo -e "\n[1/4] Sertleştirilmiş Konteyner Başlatılıyor..."
docker compose up -d --build || docker-compose up -d --build
sleep 2

echo -e "\n[2/4] Çalışan Kullanıcı (UID) Denetleniyor:"
docker exec hardened-app id

echo -e "\n[3/4] Salt-Okunur Kök Dosya Sistemi Test Ediliyor:"
echo "Konteynerin kök dizinine (/evil.sh) dosya yazmayı deniyoruz..."
set +e
docker exec hardened-app touch /evil.sh 2>&1
EXIT_TOUCH=$?
set -e

if [ $EXIT_TOUCH -ne 0 ]; then
    echo "✅ KANITLANDI: Read-only Filesystem aktif! Kök dizine dosya yazılamaz."
fi

echo -e "\n[4/4] Geçici Dizin (/tmp) Yazılabilirliği Kontrol Ediliyor:"
docker exec hardened-app touch /tmp/legit_temp_file.txt
echo "✅ /tmp başarıyla yazıldı (RAM tabanlı tmpfs)."

echo -e "\n=========================================================="
echo "🌐 API GÜVENLİK DURUMU:"
curl -s http://localhost:8080/
echo -e "\n=========================================================="
