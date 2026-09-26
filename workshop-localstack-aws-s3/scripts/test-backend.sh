#!/usr/bin/env bash
# ==============================================================================
# Script: test-backend.sh
# Amac: Python Backend uzerinden LocalStack S3 entegrasyonunu dogrulama
# ==============================================================================
set -euo pipefail

APP_URL="${1:-http://localhost:19001}"

echo "=========================================================="
echo "🧪 LocalStack S3 Backend Entegrasyon Testi"
echo "=========================================================="

echo -e "\n[1/5] Backend Saglik Durumu Kontrol Ediliyor (${APP_URL}/health)..."
curl -s -f "${APP_URL}/health" | grep -q '"status":"healthy"'
echo "✅ Backend ve LocalStack S3 baglantisi saglikli!"

echo -e "\n[2/5] Mevcut S3 Bucket'lari Listeleniyor (${APP_URL}/buckets)..."
curl -s "${APP_URL}/buckets"
echo ""

echo -e "\n[3/5] Backend REST API ile Yeni Dosya Yukleniyor..."
curl -s -X POST "${APP_URL}/upload-text" \
  -F "filename=api-log.txt" \
  -F "content=Bu dosya Python FastAPI Backend tarafindan boto3 ile S3'e yazildi."
echo ""

echo -e "\n[4/5] Bucket Icindeki Dosyalar Sorgulaniyor (${APP_URL}/files)..."
curl -s "${APP_URL}/files"
echo ""

echo -e "\n[5/5] Yuklenen Dosyanin Icerigi S3'ten Okunuyor (${APP_URL}/files/api-log.txt)..."
curl -s "${APP_URL}/files/api-log.txt"
echo -e "\n"

echo "=========================================================="
echo "🎉 TEBRIKLER! Python Backend -> LocalStack S3 entegrasyonu calisiyor."
echo "Swagger API Dokumantasyonu: ${APP_URL}/docs"
echo "=========================================================="
