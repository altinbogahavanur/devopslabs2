#!/usr/bin/env bash
# ==============================================================================
# Script: verify-install.sh
# Amac: Docker Engine, Compose, Buildx ve Izinlerin Dogrulanmasi
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          DOCKER KURULUM DOGRULAMA TESTLERI               "
echo "=========================================================="

echo -e "\n--- 1. Docker Daemon Servis Durumu ---"
if systemctl is-active --quiet docker; then
    echo "  [OK] Docker servisi calisiyor (active)."
else
    echo "  [HATA] Docker servisi calismiyor! 'sudo systemctl start docker' calistirin."
    exit 1
fi

echo -e "\n--- 2. Docker Surumu ve Bilesenler ---"
docker --version
docker compose version
docker buildx version

echo -e "\n--- 3. Non-Root Calisma Yetkisi ---"
if groups | grep -q '\bdocker\b'; then
    echo "  [OK] $USER kullanicisi 'docker' grubuna dahil."
else
    echo "  [UYARI] $USER henuz 'docker' grubunda aktif degil. 'newgrp docker' calistirin."
fi

echo -e "\n--- 4. 'hello-world' Test Konteynerinin Calistirilmasi ---"
docker run --rm hello-world

echo -e "\n=========================================================="
echo "  TEBRIKLER! DOCKER MOTORU KULLANIMA HAZIR.              "
echo "=========================================================="
