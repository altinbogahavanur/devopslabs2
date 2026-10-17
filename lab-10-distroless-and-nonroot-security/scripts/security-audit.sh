#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB10_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================================="
echo "🛡️  KONTEYNER GÜVENLİK VE SERTLEŞTİRME TESTİ 🛡️"
echo "=========================================================="

echo -e "\n[1/4] Sertleştirilmiş Konteyner Başlatılıyor..."
docker rm -f hardened-app 2>/dev/null || true
docker build -f "${LAB10_DIR}/app/Dockerfile.hardened" -t sec-demo:hardened "${LAB10_DIR}/app" > /dev/null

docker run -d --name hardened-app \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid \
  -p 8080:8080 \
  sec-demo:hardened > /dev/null
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

# Temizlik
docker rm -f hardened-app >/dev/null 2>&1 || true
