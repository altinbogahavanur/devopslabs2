#!/usr/bin/env bash
# ==============================================================================
# Harbor OCI Registry ve Trivy Kurulum Betiği (Port 18444)
# Varsayılan Giriş: admin / Harbor12345
# ==============================================================================
set -euo pipefail

HARBOR_VERSION="v2.11.0"
INSTALL_DIR="/opt/harbor"
HARBOR_PORT="18444"

echo "======================================================================"
echo "🚀 Harbor OCI Registry ve Trivy Kurulumu Başlatılıyor (Port: ${HARBOR_PORT})"
echo "======================================================================"

# 1. Docker ve Compose Kontrolü
if ! command -v docker &> /dev/null; then
    echo "❌ HATA: Docker motoru bulunamadı. Lütfen önce Docker'ı kurun."
    exit 1
fi

# 2. Kurulum Dizinini Hazırlama
sudo mkdir -p "${INSTALL_DIR}"
cd /tmp

INSTALLER_TAR="harbor-online-installer-${HARBOR_VERSION}.tgz"
if [ ! -f "${INSTALLER_TAR}" ] || [ $(wc -c < "${INSTALLER_TAR}") -lt 1000000 ]; then
    echo "===> Harbor ${HARBOR_VERSION} kurulum paketi indiriliyor..."
    rm -f "${INSTALLER_TAR}"
    curl -fSLo "${INSTALLER_TAR}" "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/${INSTALLER_TAR}"
fi

echo "===> Paket ${INSTALL_DIR} dizinine açılıyor..."
sudo tar -xzf "${INSTALLER_TAR}" -C /opt/

# 3. harbor.yml Yapılandırması
echo "===> harbor.yml hazırlanıyor (HTTP Port: ${HARBOR_PORT})..."
cd "${INSTALL_DIR}"
sudo cp harbor.yml.tmpl harbor.yml

# Hostname ayarı (Harbor prepare IP kullanımına izin vermez, FQDN gereklidir)
HARBOR_DOMAIN="harbor.devopsatolyesi.com"
sudo sed -i "s|^hostname: .*|hostname: ${HARBOR_DOMAIN}|g" harbor.yml
sudo sed -i "s|port: 80|port: ${HARBOR_PORT}|g" harbor.yml
sudo sed -i "s|harbor_admin_password: .*|harbor_admin_password: Harbor12345|g" harbor.yml

# HTTPS bloğunu devre dışı bırakma (SSL sonlandırma yerel veya Nginx tarafından yapılır)
sudo sed -i '/^https:/,/^  certificate:/ s/^/#/' harbor.yml
sudo sed -i 's|^  private_key:|#  private_key:|' harbor.yml

# /etc/hosts içine yerel alan adı çözümlemesini ekleyin
if ! grep -q "${HARBOR_DOMAIN}" /etc/hosts; then
    echo "127.0.0.1 ${HARBOR_DOMAIN}" | sudo tee -a /etc/hosts
fi

# 4. Docker Daemon Insecure Registry Tanımlama
echo "===> /etc/docker/daemon.json güncelleniyor..."
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["${HARBOR_DOMAIN}:${HARBOR_PORT}", "127.0.0.1:${HARBOR_PORT}", "localhost:${HARBOR_PORT}"]
}
EOF
sudo systemctl reload docker 2>/dev/null || true

# 5. Harbor ve Trivy Kurulumunu Başlatma
echo "===> Harbor servisleri hazırlanıyor ve Trivy entegre ediliyor..."
sudo ./prepare
sudo ./install.sh --with-trivy

echo "======================================================================"
echo "✅ Harbor Başarıyla Kuruldu ve Çalışıyor!"
echo "🌐 Web Arayüzü: http://<SUNUCU-IP>:${HARBOR_PORT} veya http://127.0.0.1:${HARBOR_PORT}"
echo "👤 Kullanıcı Adı: admin"
echo "🔑 Parola       : Harbor12345"
echo "======================================================================"
