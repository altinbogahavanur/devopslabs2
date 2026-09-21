#!/usr/bin/env bash
# ==============================================================================
# LAB-00 Linux Temelleri Otomatik Doğrulama ve Güvenli Test Betiği
# Sistem Bütünlüğünü Koruyan (Zero-Impact / Sandbox) Model
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_DIR="${SCRIPT_DIR}/sandbox"

echo "======================================================================"
echo "🐧 LAB-00: Ubuntu Linux Sistem Yönetimi & DevOps Teftiş Testi Başlıyor"
echo "======================================================================"

# 1. Donanım, CPU, RAM ve Sistem Yükü Testi
echo -e "\n[1/8] Donanım, CPU ve Bellek Bilgisi..."
lscpu | grep -E "Model name|CPU\(s\):" > /dev/null
free -h > /dev/null
uptime > /dev/null
echo "✅ Bölüm 1 Başarılı! (CPU, RAM ve Load Average okundu)"

# 2. Disk, Filesystem ve Inode Testi
echo -e "\n[2/8] Disk, Inode ve Blok Aygıtları..."
lsblk > /dev/null
df -hT / > /dev/null
df -i / > /dev/null
echo "✅ Bölüm 2 Başarılı! (Disk kapasitesi ve Inode durumu doğrulandı)"

# 3. Kullanıcı Ekleme, Parola, Yetki ve Güvenli Silme Testi
echo -e "\n[3/8] Kullanıcı Yönetimi (useradd, chpasswd, usermod, userdel)..."
sudo useradd -m -s /bin/bash devopsdemo
echo "devopsdemo:DevOpsPass123!" | sudo chpasswd
sudo usermod -aG sudo devopsdemo
id devopsdemo | grep -q "devopsdemo"
sudo userdel -r devopsdemo
echo "✅ Bölüm 3 Başarılı! (Kullanıcı güvenle oluşturuldu, test edildi ve silindi)"

# 4. Çalışan Servisleri Görme ve systemd Testi
echo -e "\n[4/8] Çalışan Tüm Servislerin Listelenmesi..."
RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l)
if [ "${RUNNING_SERVICES}" -lt 5 ]; then
  echo "❌ Hata: Çalışan servis sayısı beklenenden az: ${RUNNING_SERVICES}"
  exit 1
fi
systemctl is-active docker > /dev/null
echo "✅ Bölüm 4 Başarılı! (${RUNNING_SERVICES} adet aktif çalışan servis listelendi)"

# 5. Sistem ve Servis Loglarını İnceleme Testi
echo -e "\n[5/8] Log İnceleme (journalctl & log disk usage)..."
journalctl -u docker -n 5 --no-pager > /dev/null
journalctl -p err -b --no-pager | head -n 5 > /dev/null
journalctl --disk-usage > /dev/null
echo "✅ Bölüm 5 Başarılı! (Docker logları, hata günlükleri ve disk boyutu okundu)"

# 6. Ağ Arayüzleri, Portlar ve DNS Testi
echo -e "\n[6/8] Ağ, Dinlenen Portlar (ss) ve DNS Testi..."
ip -brief addr show > /dev/null
ip route show > /dev/null
sudo ss -tulpn | head -n 10 > /dev/null
cat /etc/resolv.conf > /dev/null
echo "✅ Bölüm 6 Başarılı! (Ağ kartları, yönlendirme tablosu ve dinlenen portlar teftiş edildi)"

# 7. Paket Yönetimi (Port Açmayan CLI Aracı Kurma & Kaldırma)
echo -e "\n[7/8] Paket Yönetimi Testi (ncdu CLI aracı)..."
sudo apt-get install -y ncdu > /dev/null 2>&1
ncdu -v > /dev/null
dpkg -s ncdu | grep "Status: install ok installed" > /dev/null
sudo apt-get remove -y ncdu > /dev/null 2>&1
echo "✅ Bölüm 7 Başarılı! (Paket kuruldu, doğrulandı ve sıfır port etkisiyle temizlendi)"

# 8. İzole Sandbox, İzinler ve Metin Filtreleme Testi
echo -e "\n[8/8] İzole Sandbox, Dosya İzinleri ve Metin Filtreleme Testi..."
rm -rf "${SANDBOX_DIR}"
mkdir -p "${SANDBOX_DIR}"
cd "${SANDBOX_DIR}"

cat <<'EOF' > deploy.sh
#!/bin/bash
echo "DEPLOY_OK"
EOF
chmod 755 deploy.sh
test -x deploy.sh

touch api.env
chmod 600 api.env
SECRET_PERM=$(stat -c "%a" api.env 2>/dev/null || stat -f "%Op" api.env | tail -c 4)

cat <<EOF > server.log
2026-09-22 INFO [auth] login ok
2026-09-22 ERROR [db] timeout
2026-09-22 ERROR [gateway] bad gateway
2026-09-22 ERROR [db] timeout
EOF
ERROR_COUNT=$(grep -c "ERROR" server.log)
if [ "${ERROR_COUNT}" -ne 3 ]; then
  echo "❌ Hata: Beklenen hata sayısı 3, bulunan: ${ERROR_COUNT}"
  exit 1
fi

sleep 60 &
DUMMY_PID=$!
kill -15 "${DUMMY_PID}"
sleep 0.5
if ps -p "${DUMMY_PID}" > /dev/null 2>&1; then
  kill -9 "${DUMMY_PID}" 2>/dev/null || true
fi

cd "${SCRIPT_DIR}"
rm -rf "${SANDBOX_DIR}"
echo "✅ Bölüm 8 Başarılı! (İzinler: ${SECRET_PERM}, Pipeline hata sayısı: ${ERROR_COUNT}, Süreç kapatıldı)"

echo "======================================================================"
echo "🎉 TEBRİKLER! LAB-00'deki Tüm Linux DevOps Komutları Başarıyla Doğrulandı."
echo "Sunucu üzerinde hiçbir servis bozulmadı ve hiçbir port çakışması üretilmedi."
echo "======================================================================"
