#!/usr/bin/env bash
# ==============================================================================
# Script: setup-swap.sh
# Amac: 16 GB RAM / 100 GB Diskli Ubuntu Sunucuda 16 GB Swap Alani Olusturma
# ==============================================================================
set -euo pipefail

SWAP_SIZE="16G"
SWAP_FILE="/swapfile"

echo "=========================================================="
echo ">>> [1/5] Mevcut Bellek ve Swap Durumu Kontrol Ediliyor..."
echo "=========================================================="
free -h

# Eger zaten aktif bir swap alani varsa uyar
if swapon --show | grep -q "$SWAP_FILE"; then
    echo "[!] $SWAP_FILE zaten aktif. Yeniden olusturulmayacak."
    free -h
    exit 0
fi

echo "=========================================================="
echo ">>> [2/5] $SWAP_SIZE Boyutunda Swap Dosyasi Olusturuluyor..."
echo "=========================================================="
# fallocate ile hizli olusturma, basarisiz olursa dd fallback
if ! sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
    echo "[*] fallocate basarisiz oldu, dd ile tahsis ediliyor..."
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1G count=16 status=progress
fi

echo "=========================================================="
echo ">>> [3/5] Dosya Izinleri Guvenli Hale Getiriliyor (chmod 600)..."
echo "=========================================================="
sudo chmod 600 "$SWAP_FILE"
ls -la "$SWAP_FILE"

echo "=========================================================="
echo ">>> [4/5] Swap Formati Atiliyor ve Aktiflestiriliyor..."
echo "=========================================================="
sudo mkswap "$SWAP_FILE"
sudo swapon "$SWAP_FILE"

echo "=========================================================="
echo ">>> [5/5] Kalicilik ve Swappiness Ayari Yapiliyor..."
echo "=========================================================="
# /etc/fstab icine kalici kayit ekleme
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "[+] /etc/fstab dosyasina kalici olarak eklendi."
fi

# Swappiness degerini 10 yaparak RAM tamamen dolmadan diske yazmayi engelleme
sudo sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi

echo "=========================================================="
echo ">>> ISLEM BASARIYLA TAMAMLANDI! Yeni Bellek Durumu:"
echo "=========================================================="
free -h
swapon --show
