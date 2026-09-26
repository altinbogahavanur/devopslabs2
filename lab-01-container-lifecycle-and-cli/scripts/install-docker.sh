#!/usr/bin/env bash
# ==============================================================================
# Script: install-docker.sh
# Amac: Resmi docs.docker.com dokumanina gore Ubuntu'ya Docker Engine Kurulumu
# Dokuman: https://docs.docker.com/engine/install/ubuntu/
# ==============================================================================
set -euo pipefail

# Idempotency Kontrolu: Docker zaten kurulu mu?
if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1; then
    echo "=========================================================="
    echo ">>> [BILGI] Docker zaten sistemde kurulu:"
    docker --version
    docker compose version 2>/dev/null || true
    echo ">>> Kurulum adimlari atlandi (Hata vermeden basariyla sonlandirildi)."
    echo "=========================================================="
    exit 0
fi

echo "=========================================================="
echo ">>> [1/6] Eski ve Cakisan Paketler Temizleniyor..."
echo "=========================================================="
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" 2>/dev/null || true
done

echo "=========================================================="
echo ">>> [2/6] On Sart Paketleri Kuruluyor..."
echo "=========================================================="
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "=========================================================="
echo ">>> [3/6] Resmi Docker GPG Anahtari Ekleniyor..."
echo "=========================================================="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=========================================================="
echo ">>> [4/6] Resmi Docker APT Deposu Ekleniyor..."
echo "=========================================================="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

echo "=========================================================="
echo ">>> [5/6] Docker Engine, CLI, Buildx ve Compose Kuruluyor..."
echo "=========================================================="
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "=========================================================="
echo ">>> [6/6] Non-root Kullanici Iznı ve Servis Yapilandirmasi..."
echo "=========================================================="
# Mevcut kullaniciyi docker grubuna ekleme
sudo usermod -aG docker "$USER"

# /etc/docker/daemon.json icin log rotasyon ayari
sudo mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
cat <<'EOF' | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
fi

sudo systemctl enable docker
sudo systemctl restart docker

echo "=========================================================="
echo ">>> DOCKER KURULUMU TAMAMLANDI! Surum Bilgileri:"
echo "=========================================================="
sudo docker --version
sudo docker compose version
echo -e "\n[!] Not: Sudo olmadan 'docker' komutunu calistirmak icin terminali yeniden baslatin veya 'newgrp docker' komutunu calistirin."
