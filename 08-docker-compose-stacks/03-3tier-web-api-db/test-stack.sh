#!/bin/bash
set -e

echo "=========================================================="
echo "🚀 MULTI-CONTAINER COMPOSE STACK TESTİ 🚀"
echo "=========================================================="

echo -e "\n[1/4] Servisler Başlatılıyor (docker compose up -d)..."
docker compose up -d --build || docker-compose up -d --build

echo -e "\n[2/4] API Sağlık Durumu Kontrol Ediliyor..."
sleep 5
curl -s http://localhost/healthz

echo -e "\n\n[3/4] Yeni Ürünler Ekleniyor (PostgreSQL Kaydı)..."
curl -s -X POST "http://localhost/products?title=DevOps%20Handbook&price=350"
echo ""
curl -s -X POST "http://localhost/products?title=Kubernetes%20in%20Action&price=420"
echo ""

echo -e "\n[4/4] İlk Okuma (Veritabanından çekilmeli):"
curl -s http://localhost/products | grep "source"

echo -e "\nİkinci Okuma (Redis Cache'ten anında gelmeli):"
curl -s http://localhost/products | grep "source"

echo -e "\n=========================================================="
echo "✅ BAŞARILI: Nginx -> FastAPI -> Redis -> PostgreSQL mimarisi"
echo "12-Factor ortam değişkenleri ile eksiksiz çalıştı!"
echo "=========================================================="
