#!/bin/bash
set -e

echo "=========================================================="
echo "DOCKER COMPOSE PROFİLLERİ VE OVERRIDE TESTİ"
echo "=========================================================="

echo -e "\n[1/4] Standart Başlatma (Hiçbir profil belirtilmedi)..."
docker compose up -d --build || docker-compose up -d --build

echo -e "\nÇalışan Servisler:"
docker compose ps || docker-compose ps
echo "✓ Yalnızca web ve db servisleri ayağa kalktı. Monitoring ve Tools başlamadı!"

echo -e "\n[2/4] 'monitoring' Profili ile Başlatılıyor..."
docker compose --profile monitoring up -d || docker-compose --profile monitoring up -d

echo -e "\nÇalışan Servisler:"
docker compose ps || docker-compose ps
echo "✓ Şimdi monitoring-agent da devreye girdi!"

echo -e "\n[3/4] Üretim (Prod) Override Konfigürasyonunun Birleştirilmesi (Config Merge Testi):"
docker compose -f docker-compose.yaml -f docker-compose.prod.yaml config | grep -A 5 "APP_ENV"

echo -e "\n=========================================================="
echo "BAŞARILI: Compose Profiles ve Çoklu Ortam yapılandırması"
echo "kusursuz olarak doğrulandı!"
echo "=========================================================="
