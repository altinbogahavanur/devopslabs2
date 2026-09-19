#!/usr/bin/env bash
set -euo pipefail

echo ">> Portainer CE (Konteyner Web Yönetim Paneli) Kuruluyor..."

# 1. Kalıcı veri alanı oluşturma
docker volume create portainer_data

# 2. Portainer CE konteynerini başlatma
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo ""
echo "✅ Portainer CE Başarıyla Başlatıldı!"
echo "   - HTTPS Arayüzü: https://localhost:9443"
echo "   - HTTP Arayüzü:  http://localhost:9000"
echo "   (İlk açılışta admin şifrenizi belirleyin)"
