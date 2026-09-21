#!/bin/bash
set -e

echo "=========================================================="
echo "⚡ DOCKER BUILD CACHE HIZ KARŞILAŞTIRMA BENCHMARK'I ⚡"
echo "=========================================================="

echo -e "\n[1/4] İlk Temiz Kurulumlar (İkisi de önbelleksiz inşa ediliyor)..."
docker build -f Dockerfile.slow -t slow-app:v1 . > /dev/null
docker build -f Dockerfile.cached -t cached-app:v1 . > /dev/null
echo "✓ İlk imajlar oluşturuldu."

echo -e "\n[2/4] Kaynak kodda küçük bir değişiklik yapılıyor..."
echo "// Build timestamp: $(date +%s)" >> app/server.js

echo -e "\n[3/4] KÖTÜ SIRALAMA (Dockerfile.slow) ile Tekrar Derleniyor..."
START_SLOW=$(date +%s)
docker build -f Dockerfile.slow -t slow-app:v2 . | grep -E "(Step|CACHED|npm install)" || true
END_SLOW=$(date +%s)
DIFF_SLOW=$((END_SLOW - START_SLOW))
echo "⏱️  Dockerfile.slow Derleme Süresi: ${DIFF_SLOW} saniye"

echo -e "\n[4/4] DOĞRU SIRALAMA (Dockerfile.cached) ile Tekrar Derleniyor..."
START_CACHED=$(date +%s)
docker build -f Dockerfile.cached -t cached-app:v2 . | grep -E "(Step|CACHED|npm install)" || true
END_CACHED=$(date +%s)
DIFF_CACHED=$((END_CACHED - START_CACHED))
echo "⏱️  Dockerfile.cached Derleme Süresi: ${DIFF_CACHED} saniye"

# Değişikliği geri al
git checkout -- app/server.js 2>/dev/null || sed -i '' '/Build timestamp/d' app/server.js 2>/dev/null || sed -i '/Build timestamp/d' app/server.js 2>/dev/null || true

echo -e "\n=========================================================="
echo "📊 ÖZET SONUÇ:"
echo "Kötü Katman Sıralaması : ${DIFF_SLOW}s (Cache Bust - npm install tekrar çalıştı)"
echo "Doğru Katman Sıralaması: ${DIFF_CACHED}s (Önbellekten anında yüklendi)"
echo "=========================================================="
