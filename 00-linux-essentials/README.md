# LAB-00 — Temel Linux Becerileri, Sunucu Hazırlığı ve 16 GB Swap Yapılandırması

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 45 dakika | `bash`, `apt`, `procps`, `iproute2` | `22` |

---

## Adım Adım Uygulama

### Adım 1: Paket Listelerini Güncelleme ve Temel Araçları Kurma

```bash
# 1. Paket listelerini güncelleme
sudo apt update

# 2. Temel araçları kurma
sudo apt install -y curl wget git htop procps iproute2 net-tools unzip tar ca-certificates
```

---

### Adım 2: Dosya, Dizin ve Arşivleme İşlemleri

```bash
# Klasör yapısı oluşturma
mkdir -p /tmp/devops-test/{logs,data,config}
cd /tmp/devops-test

# Dosya oluşturma ve listeleme
touch config/app.conf data/users.db
ls -lah

# Süreçleri ve bellek/disk durumunu inceleme
ps aux | head -n 10
free -h
df -hT /

# Klasörü tar.gz olarak arşivleme ve test dizinine açma
cd /tmp
tar -czvf devops-yedek.tar.gz devops-test/
mkdir -p /tmp/restore-test
tar -xzvf devops-yedek.tar.gz -C /tmp/restore-test/
ls -la /tmp/restore-test/devops-test
```

---

### Adım 3: 16 GB Swap Alanı Yapılandırması

Sunucuda ağır iş yükleri (GitLab, Jenkins, veritabanları) çalıştığında fiziksel RAM tükendiğinde sistemin kilitlenmemesi için 16 GB Swap alanı yapılandırılır:

```bash
# 1. 16 GB boyutunda swap dosyası tahsis etme
sudo fallocate -l 16G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress

# 2. Dosya izinlerini yalnızca root erişimine sınırlandırma
sudo chmod 600 /swapfile

# 3. Dosyayı Linux Swap formatına dönüştürme ve aktif etme
sudo mkswap /swapfile
sudo swapon /swapfile

# 4. Sunucu yeniden başladığında kaybolmaması için /etc/fstab içine ekleme
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# 5. vm.swappiness değerini 10 olarak ayarlama
# Linux varsayılan değeri 60'tır ve RAM doluluğu henüz %50-%60 seviyelerindeyken bile sayfaları diske yazmaya başlar.
# vm.swappiness = 10 ayarı, çekirdeğe fiziksel RAM %90 dolmadıkça diske dokunmama talimatı verir ve I/O darboğazını önler.
sudo sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi

# 6. Swap durumunu denetleme
swapon --show
free -h
```

---

### Adım 4: Standart Kullanıcı ve Sudo Yetkilendirmesi

```bash
# 1. devops kullanıcısını oluşturma ve sudo grubuna ekleme
sudo useradd -m -s /bin/bash devops
echo "devops:DevopsLab2026!" | sudo chpasswd
sudo usermod -aG sudo devops

# 2. SSH anahtar dizin izinlerini yapılandırma
sudo mkdir -p /home/devops/.ssh
sudo chmod 700 /home/devops/.ssh
sudo touch /home/devops/.ssh/authorized_keys
sudo chmod 600 /home/devops/.ssh/authorized_keys
sudo chown -R devops:devops /home/devops/.ssh
```

---

## Temizlik

Oluşturulan geçici arşiv ve test dizinlerini temizleyin:

```bash
rm -rf /tmp/devops-test /tmp/restore-test /tmp/devops-yedek.tar.gz
```
