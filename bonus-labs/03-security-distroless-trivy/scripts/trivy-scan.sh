#!/usr/bin/env bash
# ==============================================================================
# Script: trivy-scan.sh
# Amac: Trivy ile Imaj Guvenlik Acigi (CVE) Taramasi ve Quality Gate
# ==============================================================================
set -euo pipefail

IMAGE_TARGET="${1:-python:3.12-slim}"

echo "=========================================================="
echo "🛡️  TRIVY GUVENLIK ACIGI (CVE) TARAMASI: $IMAGE_TARGET"
echo "=========================================================="

# Trivy kurulu mu kontrol et, yoksa docker ile calistir
if command -v trivy >/dev/null 2>&1; then
    trivy image --severity HIGH,CRITICAL "$IMAGE_TARGET"
else
    echo "[*] Yerel Trivy bulunamadi, Docker uzerinden calistiriliyor..."
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /tmp/trivy-cache:/root/.cache/ \
        aquasec/trivy:latest image \
        --severity HIGH,CRITICAL \
        "$IMAGE_TARGET"
fi
