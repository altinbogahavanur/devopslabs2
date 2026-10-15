#!/usr/bin/env bash
# ==============================================================================
# Harbor Enterprise OCI Registry ve Trivy Kurulum Betiği (Port 18444)
# Referans: devops-platform-infrastructure/docs/09-container-registry-harbor.md
# Web UI: https://student100-harbor.devopsatolyesi.com/ veya http://127.0.0.1:18444
# Docker CLI Push/Pull: 127.0.0.1:18444 (Cloudflare 100MB sınırını aşmak için)
# Varsayılan Yönetici: admin / Harbor12345
# ==============================================================================
set -euo pipefail

INSTALL_DIR="/opt/devops-platform/harbor"
HARBOR_PORT="18444"
HARBOR_DOMAIN="harbor.devopsatolyesi.com"
HARBOR_PASSWORD="${HARBOR_ADMIN_PASSWORD:-Harbor12345}"

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
cd "${INSTALL_DIR}"

HARBOR_VERSION=$(curl -sSL https://api.github.com/repos/goharbor/harbor/releases/latest | jq -r .tag_name 2>/dev/null || echo "v2.12.2")
echo "===> Harbor sürümü: ${HARBOR_VERSION}"

INSTALLER_TAR="harbor-online-installer-${HARBOR_VERSION}.tgz"
if [ ! -f "install.sh" ]; then
    echo "===> Harbor kurulum paketi indiriliyor..."
    curl -fsSL "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/${INSTALLER_TAR}" -o /tmp/harbor.tgz
    sudo tar -xzf /tmp/harbor.tgz -C "${INSTALL_DIR}" --strip-components=1
    rm -f /tmp/harbor.tgz
fi

# 3. harbor.yml Yapılandırması
echo "===> harbor.yml hazırlanıyor (HTTP Port: ${HARBOR_PORT})..."
sudo cp -f harbor.yml.tmpl harbor.yml

# Hostname ayarı (Harbor prepare IP kullanımına izin vermez, FQDN gereklidir)
sudo sed -i "s|^hostname: .*|hostname: ${HARBOR_DOMAIN}|g" harbor.yml
sudo sed -i "s|port: 80|port: ${HARBOR_PORT}|g" harbor.yml
sudo sed -i "s|harbor_admin_password: .*|harbor_admin_password: ${HARBOR_PASSWORD}|g" harbor.yml
sudo sed -i "s|^data_volume: .*|data_volume: ${INSTALL_DIR}/data|g" harbor.yml

# HTTPS bloğunu devre dışı bırakma (SSL sonlandırmayı Nginx Master Reverse Proxy üstlenir)
sudo sed -i '/^https:/,/private_key:/ s/^/#/' harbor.yml

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

# 5. Harbor ve Trivy Entegrasyonunu Başlatma
echo "===> Harbor servisleri hazırlanıyor (Trivy zafiyet tarayıcısı aktif ediliyor)..."
sudo ./prepare --with-trivy
sudo ./install.sh --with-trivy

# 6. Yetkilendirme ve Sembolik Bağlantı
sudo chmod -R a+r "${INSTALL_DIR}/common/config" 2>/dev/null || true
if [ ! -L "/opt/harbor" ] && [ ! -d "/opt/harbor" ]; then
    sudo ln -sf "${INSTALL_DIR}" /opt/harbor
fi

echo "======================================================================"
echo "✅ Harbor ve Trivy Başarıyla Kuruldu ve Çalışıyor!"
echo "🌐 Web UI (Tarayıcı)   : http://${HARBOR_DOMAIN}:${HARBOR_PORT} veya http://127.0.0.1:${HARBOR_PORT}"
echo "🐳 Docker CLI (Lokal)  : docker login 127.0.0.1:${HARBOR_PORT} -u admin -p ${HARBOR_PASSWORD}"
echo "🛡️ Zafiyet Motoru      : Trivy (Aktif)"
echo "👤 Kullanıcı Adı       : admin"
echo "🔑 Parola              : ${HARBOR_PASSWORD}"
echo "======================================================================"
