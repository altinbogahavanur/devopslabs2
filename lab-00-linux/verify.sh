#!/usr/bin/env bash
# ==============================================================================
# LAB-00 Linux Temelleri Otomatik Doğrulama ve Güvenli Test Betiği
# Sistem Bütünlüğünü Koruyan (Zero-Impact / Sandbox) Model
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="${SCRIPT_DIR}/sandbox"

echo "======================================================================"
echo "🐧 LAB-00: Linux Temelleri ve Sistem Yönetimi Doğrulama Başlatılıyor"
echo "======================================================================"

# 1. Sandbox Dizinini Hazırlama
rm -rf "${SANDBOX_DIR}"
mkdir -p "${SANDBOX_DIR}"
cd "${SANDBOX_DIR}"

echo -e "\n[1/8] Linux Mimarisi ve Çıkış Kodları Testi..."
uname -srm > /dev/null
test -f /etc/os-release
echo "stdout test" > app.log
ls /olmayan_dosya_test 2> error.log || true
test -f app.log && test -f error.log
echo "✅ Bölüm 1 Başarılı!"

echo -e "\n[2/8] Dizin Hiyerarşisi ve Metin Filtreleme Testi..."
mkdir -p app/{conf,logs,data}
cat <<EOF > app/logs/access.log
2026-09-22 01:00:01 INFO [auth] User admin login successful
2026-09-22 01:00:15 WARN [api] Latency high on /api/v1/products
2026-09-22 01:00:22 ERROR [db] Connection timeout to postgres
2026-09-22 01:01:02 ERROR [gateway] 502 Bad Gateway
2026-09-22 01:01:10 ERROR [db] Connection timeout to postgres
EOF

ERROR_COUNT=$(grep -c "ERROR" app/logs/access.log)
if [ "${ERROR_COUNT}" -ne 3 ]; then
  echo "❌ Hata: Beklenen hata sayısı 3, bulunan: ${ERROR_COUNT}"
  exit 1
fi
echo "✅ Bölüm 2 Başarılı! (${ERROR_COUNT} hata satırı doğrulandı)"

echo -e "\n[3/8] Kullanıcı Kimlikleri ve İzinler (chmod) Testi..."
cat <<'EOF' > script.sh
#!/bin/bash
echo "OK"
EOF
chmod 755 script.sh
test -x script.sh
touch secret.env
chmod 600 secret.env
SECRET_PERM=$(stat -c "%a" secret.env 2>/dev/null || stat -f "%Op" secret.env | tail -c 4)
echo "✅ Bölüm 3 Başarılı! (secret.env izinleri: ${SECRET_PERM})"

echo -e "\n[4/8] Paket Yönetimi ve Sürüm Sorgulama Testi..."
dpkg -l | grep -q "curl"
dpkg -s curl | grep -q "Status: install ok installed"
echo "✅ Bölüm 4 Başarılı! (dpkg ve apt depoları okundu)"

echo -e "\n[5/8] Disk, Inode ve Alan Analizi Testi..."
df -hT / > /dev/null
df -i / > /dev/null
lsblk > /dev/null
echo "✅ Bölüm 5 Başarılı! (df ve lsblk çıktıları doğrulandı)"

echo -e "\n[6/8] Süreç Yönetimi, Sinyaller ve systemd Testi..."
sleep 60 &
DUMMY_PID=$!
kill -15 "${DUMMY_PID}"
sleep 0.5
if ps -p "${DUMMY_PID}" > /dev/null 2>&1; then
  kill -9 "${DUMMY_PID}" 2>/dev/null || true
fi
systemctl is-active docker > /dev/null
echo "✅ Bölüm 6 Başarılı! (Kukla süreç kontrollü sonlandırıldı, docker aktif)"

echo -e "\n[7/8] Ağ Mimarisi, Portlar ve DNS Testi..."
ip -brief addr show > /dev/null
ip route show > /dev/null
cat /etc/resolv.conf > /dev/null
echo "✅ Bölüm 7 Başarılı! (Ağ kartları, yönlendirme ve DNS doğrulandı)"

echo -e "\n[8/8] SSH Anahtar Mimarisi Testi..."
ssh-keygen -t ed25519 -f ./test_key -N "" -C "verify-test" > /dev/null
test -f test_key && test -f test_key.pub
echo "✅ Bölüm 8 Başarılı! (Ed25519 anahtar çifti başarıyla üretildi)"

# Temizlik
cd "${SCRIPT_DIR}"
rm -rf "${SANDBOX_DIR}"

echo "======================================================================"
echo "🎉 TEBRİKLER! LAB-00'deki Tüm Linux Komutları Başarıyla Doğrulandı."
echo "Sistem üzerinde hiçbir hasar veya kalıntı bırakılmadı."
echo "======================================================================"
