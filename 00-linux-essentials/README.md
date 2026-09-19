# LAB-DOC-00 — Temel Linux Becerileri, Sunucu Hazırlığı ve 16 GB Swap Yapılandırması

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç | `bash`, `apt`, `procps`, `iproute2`, `systemd`, `curl` | 22 (SSH), 8080, 9000 (Test) |

> **Önemli Erişim Notu:** Eğitim platformunda sunucuya erişirken Reverse Proxy tanımlı portlar (`app1` için `19001`, `app3` için `19003` vb.) kullanılabilir. Bunların dışındaki veya yerel test portları için tarayıcınızdan doğrudan `http://<SUNUCU-IP>:<PORT>` adresini kullanabilir veya sunucu içinde `curl http://localhost:<PORT>` ile test yapabilirsiniz.

---

## Amaç

Bu laboratuvarın amacı; Docker ve konteyner platformlarını çalıştırmadan önce **Ubuntu Linux sunucusunu kurumsal üretime hazırlamak**, temel Linux sistem yönetimi becerilerini kazanmak ve donanım kaynaklarını optimize etmektir:

- **Paket ve Servis Yönetimi:** `apt` ile paket kurma, kaldırma, temizleme ve `systemd` ile servislerin yaşam döngüsünü yönetme.
- **Port ve Uygulama Farkındalığı:** Farklı portlarda çalışan servisleri (Nginx, Python HTTP) ayağa kaldırma, port çakışmalarını tespit etme ve doğrulama.
- **Kullanıcı ve Güvenlik:** `sudo` yetkili kullanıcı oluşturma, dosya sahipliği ve SSH anahtar (`ed25519`) güvenliği.
- **Dosya ve Süreç Hakimiyeti:** Dosya ağacı, filtreleme (`grep`, `find`), arşivleme (`tar`), süreç takibi (`htop`, `ps`) ve kaynak limitleri.
- **16 GB Swap ve Disk Optimizasyonu:** GitLab, Jenkins veya büyük veritabanları açıldığında Out-Of-Memory (OOM) kilitlenmesini önlemek için 16 GB Swap alanı ve `vm.swappiness=10` yapılandırması.
- **Ağ ve DNS Teşhisi:** `ss`, `netstat`, `ping`, `dig`, `nslookup` ile ağ ve isim çözümleme sorunlarını giderme.

---

## Ön Koşullar

- Ubuntu 22.04 veya 24.04 LTS kurulu sunucu veya sanal makine erişimi.
- `sudo` yetkisine sahip kullanıcı oturumu.
- En az 25 GB boş disk alanı (`df -h /`).

---

## Mimari ve Çalışma Modeli

```text
+─────────────────────────────────────────────────────────────────────────────+
|                         UBUNTU SUNUCU DONANIMI                              |
|   - 4 vCPU (x86_64 / ARM64)                                                 |
|   - 16 GB Fiziksel Bellek (RAM)                                             |
|   - 100 GB SSD Disk                                                         |
+─────────────────────────────────────────────────────────────────────────────+
                                      │
            KAYNAK ESNETME (SWAP) & SİSTEM YÖNETİM KATMANI
                                      ▼
+───────────────────────────────────+   +─────────────────────────────────────+
| BELLEK ESNETME: 16 GB SWAP ALANI  |   | GÜVENLİK, SERVİS & AĞ YÖNETİMİ      |
| - /swapfile (16 GB - chmod 600)   |   | - devops kullanıcısı (sudo grubu)   |
| - vm.swappiness = 10              |   | - SSH Key (~/.ssh/authorized_keys)  |
| - /etc/fstab (Kalıcı bağlama)     |   | - systemd servisleri & journalctl   |
| - Efektif Bellek: 16+16 = 32 GB!  |   | - Ağ portları: ss, netstat, dig     |
+───────────────────────────────────+   +─────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

Konuları sırasıyla inceleyip komutları terminalinizde uygulayın. Her konu başlığına tıklayarak detaylı komutları ve açıklamaları açabilirsiniz:

<details>
<summary><b>📦 1. Paket Yönetimi (APT: Kurma, Kaldırma, Arama ve Temizlik)</b></summary>

Linux sunucularda yazılım yükleme, güncelleme ve kaldırma işlemleri `apt` (Advanced Package Tool) ile yürütülür.

```bash
# 1. Depo paket listesini güncelleyin (yeni sürümleri çeker, henüz yükleme yapmaz)
sudo apt update

# 2. Temel DevOps araçlarını kurun
sudo apt install -y curl wget git htop procps iproute2 net-tools dnsutils unzip tar ca-certificates

# 3. Paket arama ve paket detayını inceleme
apt-cache search nginx
apt-cache show curl

# 4. Bir paketi kaldırma (Yapılandırma dosyaları kalır)
sudo apt install -y tree
sudo apt remove -y tree

# 5. Bir paketi tüm yapılandırma dosyalarıyla birlikte tamamen silme (Purge)
sudo apt purge -y tree

# 6. Artık ihtiyaç duyulmayan gereksiz bağımlılıkları ve APT önbelleğini temizleme
sudo apt autoremove -y --purge
sudo apt clean
```
</details>

<details>
<summary><b>⚙️ 2. Servis ve Daemon Yönetimi (systemd & journalctl)</b></summary>

Modern Linux sistemlerde arka planda çalışan servisler (Docker, Nginx, SSH vb.) `systemd` ile yönetilir.

```bash
# 1. Test amaçlı Nginx web sunucusunu kurun
sudo apt install -y nginx

# 2. Servis durumunu kontrol edin
sudo systemctl status nginx --no-pager

# 3. Servisi durdurma, başlatma ve yeniden başlatma
sudo systemctl stop nginx
sudo systemctl start nginx
sudo systemctl restart nginx

# 4. Servisin sistem açılışında otomatik başlamasını sağlama (veya kapatma)
sudo systemctl enable nginx
sudo systemctl is-enabled nginx
# Kapatmak için: sudo systemctl disable nginx

# 5. Servisi tamamen kilitleme (Yanlışlıkla bile başlamasını engeller)
# sudo systemctl mask nginx
# Kilidi açmak için: sudo systemctl unmask nginx

# 6. Servis loglarını systemd journal üzerinden canlı izleme
sudo journalctl -u nginx -f --no-tail
# Son 10 dakikadaki logları görmek için:
sudo journalctl -u nginx --since "10 min ago"

# 7. Bir servis dosyasını değiştirdikten sonra systemd yapılandırmasını yenileme
sudo systemctl daemon-reload
```
</details>

<details>
<summary><b>🌐 3. Farklı Portlarda Servis Çalıştırma (Port Yönetimi & Çakışma Önleme)</b></summary>

Docker çalıştırmadan önce sunucuda hangi portların açık olduğunu bilmek ve uygulamaları farklı portlarda çalıştırmayı deneyimlemek çok kritiktir.

```bash
# 1. Nginx varsayılan Port 80'i dinler. Test edelim:
curl -I http://localhost:80

# 2. Python ile geçici olarak Port 9000 ve Port 9090 üzerinde web sunucuları açalım:
mkdir -p /tmp/web9000 && echo "Port 9000 Calisiyor" > /tmp/web9000/index.html
mkdir -p /tmp/web9090 && echo "Port 9090 Calisiyor" > /tmp/web9090/index.html

# Arka planda (nohup ile) çalıştıralım:
nohup python3 -m http.server 9000 --directory /tmp/web9000 > /tmp/web9000.log 2>&1 &
nohup python3 -m http.server 9090 --directory /tmp/web9090 > /tmp/web9090.log 2>&1 &

# 3. Dinleyen portları kontrol edin (9000 ve 9090 görünmeli)
sudo ss -tulpn | grep -E ':9000|:9090'

# 4. Doğrudan yerel curl ile test edin:
curl http://localhost:9000
curl http://localhost:9090

# Not: Tarayıcınızdan test etmek isterseniz http://<SUNUCU-IP>:9000 adresini ziyaret edebilirsiniz.

# 5. Test sunucularını sonlandıralım:
kill $(pgrep -f "http.server 9000")
kill $(pgrep -f "http.server 9090")
rm -rf /tmp/web9000 /tmp/web9090 /tmp/web9000.log /tmp/web9090.log
```
</details>

<details>
<summary><b>👥 4. Kullanıcı, Grup ve Sudo Yetki Yönetimi</b></summary>

Üretim sunucularında doğrudan `root` kullanıcısı ile çalışmak büyük bir güvenlik açığıdır. Standart bir DevOps kullanıcısı oluşturulmalı ve gerektiğinde `sudo` yetkisi verilmelidir.

```bash
# 1. 'devops' adında standart bir kullanıcı ve ev dizini oluşturun
sudo useradd -m -s /bin/bash devops

# 2. Kullanıcıya parola atayın
echo "devops:DevopsLab2026!" | sudo chpasswd

# 3. Kullanıcıyı 'sudo' grubuna ekleyin
sudo usermod -aG sudo devops

# 4. Kullanıcının gruplarını teyit edin
id devops

# 5. Parola sormadan belirli komutları çalıştırması için sudoers kuralı bırakma (Opsiyonel / Best Practice)
echo "devops ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/devops-nopasswd
sudo chmod 440 /etc/sudoers.d/devops-nopasswd

# 6. Dosya izinleri ve sahipliği:
sudo touch /tmp/devops-test-file
sudo chown devops:devops /tmp/devops-test-file
sudo chmod 640 /tmp/devops-test-file
ls -l /tmp/devops-test-file
rm -f /tmp/devops-test-file
```
</details>

<details>
<summary><b>📁 5. Dosya, Dizin, Arama ve Arşivleme Yönetimi</b></summary>

Linux dosya sisteminde hızlı gezinme, log arama ve yapılandırma arşivleme operasyonları:

```bash
# 1. Hiyerarşik klasör yapısı oluşturun
mkdir -p /tmp/devops-project/{config,logs,data,src}

# 2. Örnek dosyalar oluşturun
touch /tmp/devops-project/config/app.env
touch /tmp/devops-project/logs/app.log
echo "DATABASE_URL=postgres://db:5432" > /tmp/devops-project/config/app.env

# 3. Belirli kriterlere göre dosya arama (find)
find /tmp/devops-project -type f -name "*.env"
find /var/log -type f -name "*.log" -mtime -2 2>/dev/null | head -n 5

# 4. Dosya içeriklerinde metin arama (grep)
grep -rn "DATABASE_URL" /tmp/devops-project/

# 5. Sembolik Link (Soft Link) oluşturma
ln -s /tmp/devops-project/config/app.env /tmp/app-current.env
ls -l /tmp/app-current.env

# 6. Dizin ağacını tar.gz olarak arşivleme ve geri açma
cd /tmp
tar -czvf devops-project-backup.tar.gz devops-project/
mkdir -p /tmp/restore-area
tar -xzvf devops-project-backup.tar.gz -C /tmp/restore-area/

# Temizlik
rm -rf /tmp/devops-project /tmp/app-current.env /tmp/devops-project-backup.tar.gz /tmp/restore-area
```
</details>

<details>
<summary><b>⚡ 6. Süreç (Process) ve Kaynak Yönetimi (htop, ps, kill, nohup)</b></summary>

Sistemdeki çalışan süreçlerin incelenmesi, kaynak tüketiminin analizi ve takılan süreçlerin sonlandırılması:

```bash
# 1. Süreçleri listeleme ve en çok bellek tüketenleri sıralama
ps aux --sort=-%mem | head -n 10

# 2. Süreç ağacını görüntüleme
ps -ef --forest | head -n 20

# 3. İnteraktif kaynak izleme (Çıkmak için 'q' tuşuna basın)
# htop komutu CPU çekirdeklerini ve RAM/Swap durumunu renkli gösterir
# htop

# 4. Sistem yükü ve çekirdek durumunu kontrol etme
uptime
free -h

# 5. Arka planda bir süreç başlatıp sinyallerle sonlandırma
sleep 300 &
# Çalışan sürecin PID'sini bulma:
SLEEP_PID=$!
echo "Baslatilan surec PID: $SLEEP_PID"
ps aux | grep "[s]leep 300"

# Normal sonlandırma sinyali (SIGTERM - 15):
kill -15 $SLEEP_PID

# Zorla sonlandırma sinyali gerekirse (SIGKILL - 9):
# kill -9 $SLEEP_PID
```
</details>

<details>
<summary><b>🔑 7. SSH Anahtar Yönetimi ve Parolasız Güvenli Giriş</b></summary>

Otomasyon ve güvenli sunucu iletişimi için SSH anahtar çifti oluşturma ve hedef kullanıcıya yetki verme:

```bash
# 1. devops kullanıcısı altında .ssh dizinini hazırlayın
sudo mkdir -p /home/devops/.ssh
sudo chmod 700 /home/devops/.ssh

# 2. Modern ve güvenli ED25519 algoritması ile yeni bir anahtar çifti üretin
# (Parola sormadan geçmek için Enter'a basabilirsiniz)
ssh-keygen -t ed25519 -f /tmp/devops_key -C "devops-key" -N ""

# 3. Üretilen Açık Anahtarı (Public Key) kullanıcının authorized_keys dosyasına ekleyin
cat /tmp/devops_key.pub | sudo tee -a /home/devops/.ssh/authorized_keys

# 4. Dosya izinlerini sıkılaştırın (Yetki 600 olmak ZORUNDADIR, aksi halde SSH reddeder)
sudo chmod 600 /home/devops/.ssh/authorized_keys
sudo chown -R devops:devops /home/devops/.ssh

# 5. Özel anahtarla (Private Key) yerel olarak parolasız bağlantıyı test edin:
ssh -i /tmp/devops_key -o StrictHostKeyChecking=no devops@localhost "whoami; hostname"

# 6. Test anahtarını temizleyin:
rm -f /tmp/devops_key /tmp/devops_key.pub
```
</details>

<details>
<summary><b>💾 8. Disk, Bölümleme ve 16 GB Swap Yönetimi</b></summary>

Ağır iş yükleri (GitLab, Jenkins, veritabanları) çalıştığında fiziksel RAM tükendiğinde sunucunun çökmesini engellemek için **16 GB Swap** alanı oluşturulması ve ayarların kalıcı yapılması:

```bash
# 1. Mevcut disk ve blok aygıt durumunu kontrol edin
df -hT /
lsblk

# 2. 16 GB boyutunda swap dosyası tahsis edin
# (fallocate hızlıdır, desteklenmeyen dosya sistemlerinde dd kullanılır)
sudo fallocate -l 16G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress

# 3. İzinleri yalnızca root erişimine sınırlandırın
sudo chmod 600 /swapfile

# 4. Dosyayı Linux Swap biçimine dönüştürün ve aktif edin
sudo mkswap /swapfile
sudo swapon /swapfile

# 5. Sunucu yeniden başladığında swap'ın korunması için /etc/fstab'a ekleyin
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# 6. Çekirdek swappiness değerini 10 yaparak diske gereksiz yazmayı önleyin
sudo sysctl vm.swappiness=10
if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi
```
</details>

<details>
<summary><b>🔍 9. Ağ, DNS ve Sorun Giderme Araçları (ping, ss, netstat, dig, nslookup)</b></summary>

Konteyner ve sunucu iletişimindeki ağ kopukluklarını, port kilitlenmelerini ve DNS çözümleme hatalarını tespit etme:

```bash
# 1. Ağ arayüzlerini ve yerel IP adresini inceleyin
ip -br addr
ip route show

# 2. Dinleyen TCP ve UDP portlarını kontrol edin (ss ve netstat)
sudo ss -tulpn
sudo netstat -tlpn

# 3. Dış ağ erişimini ve gecikmeyi test edin
ping -c 4 8.8.8.8

# 4. DNS İsim Çözümleme Testleri (dig ve nslookup)
# Alan adının IP'sini sorgulayın:
dig +short google.com
nslookup google.com

# 5. Yerel DNS çözümleme durumunu kontrol edin (systemd-resolved)
resolvectl status | head -n 20

# 6. /etc/hosts dosyasını inceleyin (Yerel DNS yönlendirmeleri için)
cat /etc/hosts

# 7. HTTP başlıklarını ve durum kodunu test etme
curl -I https://www.google.com
```
</details>

---

## Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla sistemin sonraki Docker laboratuvarlarına hazır olduğunu teyit edin:

```bash
# 1. 16 GB Swap alanının aktif olduğunu doğrulayın
swapon --show
free -h

# 2. Swappiness değerinin 10 olduğunu kontrol edin
sysctl vm.swappiness

# 3. devops kullanıcısının hazır olduğunu kontrol edin
id devops

# 4. Açık portları denetleyin (Port 80 Nginx çalışır durumda olabilir)
sudo ss -tulpn
```

* **Beklenen Başarı Kriterleri:**
  - `swapon --show` çıktısında `/swapfile` **16G** olarak listelenmelidir.
  - `free -h` çıktısında `Swap: 16Gi` görünmelidir.
  - `sysctl vm.swappiness` çıktısı `vm.swappiness = 10` olmalıdır.
  - `id devops` çıktısında kullanıcı `sudo` grubuna dahil olmalıdır.

---

## Temizlik

Laboratuvarda açılan geçici servisleri durdurun (Swap alanı ve `devops` kullanıcısı sonraki tüm laboratuvarlar için korunmalıdır):

```bash
# Nginx servisini durdurup kaldırabilirsiniz (Docker kendi Nginx'ini çalıştıracaktır):
sudo systemctl stop nginx
sudo apt remove -y nginx && sudo apt autoremove -y
```
