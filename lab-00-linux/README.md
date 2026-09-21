# LAB-00: Linux Sistem Yönetimi, Teftiş ve Analiz Komutları

## 🎯 Labın Amacı
Linux tabanlı sunucularda donanım (CPU/RAM), süreçler (process), disk kapasitesi ve Inode durumu, kullanıcı yönetimi, aktif servisler, sistem logları, paketler ve ağ durumunu teftiş etmek için gerekli temel komutları uygulamak.

---

## 🚀 Adım Adım Uygulama

### 1. Çalışma Dizinine Geçiş
```bash
cd ~/docker-labs/lab-00-linux
```

```bash
mkdir -p sandbox && cd sandbox
```

---

### 2. Çekirdek ve İşletim Sistemi Bilgilerini Görüntüleme
```bash
uname -srm
```

```bash
cat /etc/os-release | grep -E "PRETTY_NAME|VERSION_ID"
```

---

### 3. CPU Donanım Bilgilerini İnceleme
```bash
lscpu | grep -E "Model name|CPU\(s\):"
```

---

### 4. Bellek (RAM) ve Swap Kullanımını Kontrol Etme
```bash
free -h
```

---

### 5. Sistem Çalışma Süresi ve Yük Ortalaması (Load Average)
```bash
uptime
```

---

### 6. En Çok Bellek Tüketen Süreçleri Sıralama
```bash
ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 10
```

---

### 7. Disk Blok Aygıtlarını ve Bölümlerini Listeleme
```bash
lsblk
```

---

### 8. Dosya Sistemi Kapasite Doluluğunu Denetleme
```bash
df -hT /
```

---

### 9. Inode (Dosya Sayısı Sınırı) Doluluğunu Kontrol Etme
```bash
df -i /
```

---

### 10. En Çok Alan Tüketen Dizinleri Sıralama
```bash
sudo du -xhd1 /var 2>/dev/null | sort -h | tail -n 8
```

---

### 11. Kalıcı Disk Bağlantı Tablosunu (/etc/fstab) İnceleme
```bash
cat /etc/fstab | grep -v "^#"
```

---

### 12. Mevcut Kullanıcı ve Oturum Bilgilerini Görme
```bash
whoami
```

```bash
id
```

```bash
w
```

---

### 13. Yeni Bir Test Kullanıcısı Oluşturma
```bash
sudo useradd -m -s /bin/bash devopsdemo
```

---

### 14. Kullanıcıya Parola Atama
```bash
echo "devopsdemo:DevOpsPass123!" | sudo chpasswd
```

---

### 15. Kullanıcıyı Sudo Grubuna Ekleme
```bash
sudo usermod -aG sudo devopsdemo
```

---

### 16. Kullanıcıyı Doğrulama
```bash
id devopsdemo
```

```bash
grep "devopsdemo" /etc/passwd
```

---

### 17. Test Kullanıcısını Ev Diziniyle Birlikte Silme
```bash
sudo userdel -r devopsdemo
```

---

### 18. Çalışan Tüm Servisleri Listeleme
```bash
systemctl list-units --type=service --state=running --no-pager
```

---

### 19. Docker ve Nginx Servis Durumunu Sorgulama
```bash
systemctl is-active docker
```

```bash
systemctl is-active nginx
```

---

### 20. Servislerin Açılışta Otomatik Başlama Ayarını Denetleme
```bash
systemctl is-enabled docker
```

```bash
systemctl is-enabled nginx
```

---

### 21. Docker Servisinin Son Günlüklerini (Log) Okuma
```bash
journalctl -u docker -n 30 --no-pager
```

---

### 22. Açılıştan İtibaren Sistem Hata (Error) Loglarını Filtreleme
```bash
journalctl -p err -b -n 20 --no-pager
```

---

### 23. Son 30 Dakikaya Ait Günlükleri İnceleme
```bash
journalctl --since "30 min ago" -n 20 --no-pager
```

---

### 24. Journal Günlük Dosyalarının Boyutunu Görme
```bash
journalctl --disk-usage
```

---

### 25. Ağ Arayüzleri ve IP Adreslerini Listeleme
```bash
ip -brief addr show
```

---

### 26. Varsayılan Ağ Geçidini (Routing Table) Görüntüleme
```bash
ip route show
```

---

### 27. Sunucuda Dinlenen (LISTEN) Portları İnceleme
```bash
sudo ss -tulpn
```

---

### 28. DNS Çözümleme Yapılandırmasını İnceleme
```bash
cat /etc/resolv.conf
```

```bash
cat /etc/hosts
```

---

### 29. Alan Adı Çözümleme (DNS Lookup) Testi
```bash
nslookup google.com
```

---

### 30. HTTP Uç Noktası Sağlık Kontrolü
```bash
curl -I -s http://127.0.0.1:80 | head -n 5
```

---

### 31. Paket İndeksini Güncelleme
```bash
sudo apt-get update -y
```

---

### 32. Paket Depo Bilgisini Sorgulama
```bash
apt-cache policy ncdu
```

---

### 33. Örnek CLI Aracı Kurma (ncdu)
```bash
sudo apt-get install -y ncdu
```

---

### 34. Kurulan Paketi Doğrulama
```bash
ncdu -v
```

```bash
dpkg -s ncdu | grep -E "Package:|Version:|Status:"
```

---

### 35. Test Paketini Sistemden Kaldırma
```bash
sudo apt-get remove -y ncdu
```

---

### 36. Dosya İzinleri Pratiği (chmod 755)
```bash
cat <<'EOF' > deploy.sh
#!/bin/bash
echo "Deploy scripti calisti!"
EOF
```

```bash
chmod 755 deploy.sh
```

```bash
./deploy.sh
```

---

### 37. Gizli Dosya İzin Standardı (chmod 600)
```bash
touch api-token.env
```

```bash
chmod 600 api-token.env
```

```bash
ls -l api-token.env
```

---

### 38. Dosya İzin Zincirini İnceleme (namei)
```bash
namei -l deploy.sh
```

---

### 39. Örnek Log Dosyası Oluşturma
```bash
cat <<EOF > server.log
2026-09-22 01:00:01 INFO [auth] User admin login successful
2026-09-22 01:00:15 WARN [api] Latency high on /api/v1/products
2026-09-22 01:00:22 ERROR [db] Connection timeout to postgres
2026-09-22 01:00:45 INFO [auth] User student login successful
2026-09-22 01:01:02 ERROR [gateway] 502 Bad Gateway
2026-09-22 01:01:10 ERROR [db] Connection timeout to postgres
EOF
```

---

### 40. Log Dosyası İçinde Hata Arama ve Gruplama (grep & awk)
```bash
grep "ERROR" server.log
```

```bash
grep "ERROR" server.log | awk '{print $4}' | sort | uniq -c
```

---

### 41. Süreç Başlatma ve Güvenli Sonlandırma (kill -15)
```bash
sleep 120 &
```

```bash
DUMMY_PID=$!
```

```bash
kill -15 "${DUMMY_PID}"
```

```bash
ps -p "${DUMMY_PID}" || echo "Surec sonlandirildi."
```

---

## 🧹 Temizlik
```bash
cd ~/docker-labs/lab-00-linux
```

```bash
rm -rf sandbox
```
