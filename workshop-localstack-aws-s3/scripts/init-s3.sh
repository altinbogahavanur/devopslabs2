#!/usr/bin/env bash
# ==============================================================================
# Script: init-s3.sh
# Amac: Docker icerisindeki amazon/aws-cli kullanarak LocalStack S3 uzerinde
#       bucket olusturmak ve ornek dosya yuklemek (Hostta AWS CLI gerektirmez).
# ==============================================================================
set -euo pipefail

BUCKET_NAME="${1:-devops-training-bucket}"
NETWORK_NAME="localstack-aws-net"
ENDPOINT="http://localstack:4566"

echo "=========================================================="
echo "☁️  LocalStack S3 Bucket ve Dosya Hazirlik Betigi"
echo "=========================================================="

echo -e "\n[1/3] S3 Bucket Durumu Kontrol Ediliyor (s3://${BUCKET_NAME})..."
docker run --rm \
  --network "${NETWORK_NAME}" \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli \
  --endpoint-url="${ENDPOINT}" \
  s3 mb "s3://${BUCKET_NAME}" 2>/dev/null || echo "Bucket zaten mevcut veya backend tarafindan olusturuldu."

echo -e "\n[2/3] Ornek Test Dosyasi LocalStack S3'e Kopyalaniyor..."
TMP_DIR=$(mktemp -d)
cat <<EOF > "${TMP_DIR}/welcome-aws.txt"
======================================================
Merhaba DevOps Muhendisi!
Bu dosya Docker icindeki LocalStack S3 uzerinde saklaniyor.
Sifir bulut maliyetiyle AWS S3 testleri basariyla calisiyor.
Zaman: $(date)
======================================================
EOF

docker run --rm \
  --network "${NETWORK_NAME}" \
  -v "${TMP_DIR}:/data" \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli \
  --endpoint-url="${ENDPOINT}" \
  s3 cp /data/welcome-aws.txt "s3://${BUCKET_NAME}/welcome-aws.txt"

rm -rf "${TMP_DIR}"

echo -e "\n[3/3] S3 Bucket Icerigi Listeleniyor:"
docker run --rm \
  --network "${NETWORK_NAME}" \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli \
  --endpoint-url="${ENDPOINT}" \
  s3 ls "s3://${BUCKET_NAME}/"

echo -e "\n✅ AWS CLI ile LocalStack S3 islemleri basariyla tamamlandi!"
