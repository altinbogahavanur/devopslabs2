#!/usr/bin/env bash
# ==============================================================================
# Script: preflight-check.sh
# Amac: Ubuntu 24.04/22.04 Sistem Saglik, Port ve Kaynak Denetimi (Preflight)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "          DEVOPS LAB ON HAZIRLIK (PREFLIGHT) RAPORU       "
echo "=========================================================="

echo -e "\n--- 1. Isletim Sistemi ve Cekirdek Bilgisi ---"
hostnamectl | grep -E "Operating System|Kernel|Architecture" || uname -a

echo -e "\n--- 2. CPU Bilgileri ---"
echo "Toplam Cekirdek (nproc): $(nproc)"
lscpu | grep -E "Model name|Thread\(s\) per core|Core\(s\) per socket" || true

echo -e "\n--- 3. Bellek (RAM) ve Swap Durumu ---"
free -h

echo -e "\n--- 4. Disk Doluluk Orani (100 GB Kontrolu) ---"
df -hT /

echo -e "\n--- 5. Kritik Portlarin Durumu (22, 80, 443, 8080, 5432, 6379, 5000) ---"
CRITICAL_PORTS=(22 80 443 8080 5432 6379 5000)
for port in "${CRITICAL_PORTS[@]}"; do
    if ss -tulpn 2>/dev/null | grep -q ":$port "; then
        echo "  [DOLU] Port $port su anda dinleniyor:"
        ss -tulpn 2>/dev/null | grep ":$port " || true
    else
        echo "  [BOS]  Port $port kullanima hazir."
    fi
done

echo -e "\n--- 6. Temel Gerekli Komutlarin Kontrolu ---"
COMMANDS=(curl tar gzip unzip htop ps git)
for cmd in "${COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "  [OK] $cmd kurulu: $(command -v "$cmd")"
    else
        echo "  [EKSIK] $cmd bulunamadi! 'sudo apt install -y $cmd' ile kurun."
    fi
done

echo -e "\n=========================================================="
echo "          PREFLIGHT DENETIMI TAMAMLANDI                   "
echo "=========================================================="
