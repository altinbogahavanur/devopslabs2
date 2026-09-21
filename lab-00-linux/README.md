# LAB-00: Ubuntu Linux Sistem Yönetimi, Analiz ve Teftiş Rehberi (DevOps Essentials)

| Seviye | Profil / Araçlar | Hedef İşletim Sistemi | Çalışma Alanı (Sandbox) |
| :--- | :--- | :--- | :--- |
| Başlangıç - Orta | `bash`, `coreutils`, `systemd`, `iproute2`, `apt`, `procps` | **Ubuntu 24.04 LTS** | `~/docker-labs/lab-00-linux/sandbox` |

---

## 🎯 Labın Amacı
Modern DevOps ekosisteminde Docker konteynerleri, Kubernetes node'ları, CI/CD runner'ları ve bulut sunucuları doğrudan Linux çekirdeği ve işletim sistemi üzerinde koşar. Bu laboratuvarın amacı; bir DevOps mühendisinin günlük operasyonlarda, dağıtımlarda ve arıza anlarında (incident troubleshooting) en sık ihtiyaç duyduğu **CPU, Bellek, Disk, Kullanıcı Yönetimi, Servis Durumu, Log Analizi, Paket Yönetimi ve Ağ Teftişi** yetkinliklerini **Ubuntu sunucusunun mevcut çalışan servislerini bozmadan ve hiçbir port çakışması üretmeden** kazandırmaktır.

---

## 🛡️ Güvenlik ve Sıfır Etki (Zero-Impact) İlkeleri

> [!IMPORTANT]
> **Sistem Bütünlüğünü Koruma Standartları:**
> 1. **Port Çakışması Güvencesi:** Paket kurulum deneyinde Nginx, Apache gibi port dinleyen arka plan servisleri **kesinlikle kurulmaz**. Yalnızca CLI araçları (`ncdu` vb.) test edilir ve kaldırılır; çalışan platform portları (80, 443, 18444, 19001) korunur.
> 2. **İzole Dosya İşlemleri:** Dosya oluşturma, değiştirme, izin ve silme pratikleri **yalnızca** `~/docker-labs/lab-00-linux/sandbox` dizininde yürütülür.
> 3. **Sistem Dizinleri Salt Okunurdur:** `/etc`, `/var`, `/usr`, `/proc` gibi kritik işletim sistemi dizinleri yalnızca inceleme (`cat`, `ls`, `grep`, `head`, `findmnt`) amacıyla okunur.
> 4. **Güvenli Süreç ve Kullanıcı Deneyleri:** Test amaçlı oluşturulan kukla süreçler (`sleep`) ve test kullanıcıları (`devopsdemo`) işlem bitiminde sistemde hiçbir iz bırakmadan temizlenir.

---

## 🚀 Adım Adım Modüller

---

### Bölüm 1: Donanım, CPU, RAM ve Sistem Yükü Analizi

Bir sunucuda performans dar boğazı veya yanıt verememe durumu yaşandığında ilk kontrol edilen katmandır.

```bash
# 1. İşletim sistemi çekirdeğini ve dağıtım sürümünü sorgulayın:
uname -srm
cat /etc/os-release | grep -E "PRETTY_NAME|VERSION_ID"

# 2. CPU Mimarisi ve Çekirdek Sayısını İnceleyin:
lscpu | grep -E "Model name|Socket|Thread|NUMA|CPU\(s\):|CPU MHz"

# 3. Bellek (RAM) ve Swap Tüketimini İnceleyin (İnsan okunabilir -h formatında):
free -h
# total: Toplam RAM | used: Kullanılan | buff/cache: Dosya önbelleği | available: Yeni process için hazır bellek

# 4. Sistem Çalışma Süresi ve Yük Ortalaması (Load Average):
uptime
# Çıktıdaki 3 sayı sırasıyla: Son 1 dakika, 5 dakika ve 15 dakikalık işlemci kuyruk yoğunluğunu gösterir.

# 5. En Çok Bellek Tüketen İlk 8 Süreci Sıralayın:
ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -n 9
```

---

### Bölüm 2: Disk, Dosya Sistemi ve Inode Analizi

Disk problemleri ikiye ayrılır: Kapasite (GB) doluluğu veya dosya tablosu (Inode) tükenmesi.

```bash
# 1. Blok Aygıtları, Disk Bölümleri ve Mount Noktalarını İnceleyin:
lsblk

# 2. Filesystem Alan Doluluğunu Denetleyin (Kapasite Kontrolü):
df -hT /
# Use% değeri %90'ın üzerine çıktığında disk uyarısı verilir.

# 3. Inode (Dosya Sayısı Sınırı) Doluluğunu Denetleyin:
df -i /
# DİKKAT: Disk boş görünse dahi IUse% %100 olursa sıfır byte dosya dahi yazılamaz!

# 4. En Çok Alan Tüketen Dizinleri Tespit Edin (/var dizini için güvenli analiz):
sudo du -xhd1 /var 2>/dev/null | sort -h | tail -n 8

# 5. Kalıcı Disk Bağlantı Tablosunu (/etc/fstab) İnceleyin:
cat /etc/fstab | grep -v "^#"
```

---

### Bölüm 3: Kullanıcı ve Grup Yönetimi (Ekleme, Yetkilendirme, Parola ve Güvenli Silme)

DevOps otomasyonlarında insan kullanıcıları ile servis hesapları (service accounts) ayrıştırılmalıdır.

```bash
# 1. Mevcut Oturum ve Kimlik Bilgilerini Sorgulayın:
whoami
id
w
# 'w' komutu sunucuda o an kimlerin hangi terminalden ve hangi IP'den bağlı olduğunu gösterir.

# 2. Test Amaçlı Yeni Bir Kullanıcı Oluşturun (Ev dizini ve Bash kabuğuyla):
sudo useradd -m -s /bin/bash devopsdemo

# 3. Kullanıcıya Parola Atayın:
echo "devopsdemo:DevOpsPass123!" | sudo chpasswd

# 4. Kullanıcıyı Yönetici (sudo) Grubuna Dahil Edin:
sudo usermod -aG sudo devopsdemo

# 5. Kullanıcının Oluştuğunu ve Gruplarını Doğrulayın:
id devopsdemo
ls -ld /home/devopsdemo
grep "devopsdemo" /etc/passwd

# 6. Güvenli Temizlik: Test Kullanıcısını Ev Diziniyle Birlikte Kaldırın:
sudo userdel -r devopsdemo
echo "✅ Test kullanıcısı sistemden temizlendi."
```

---

### Bölüm 4: Çalışan Tüm Servisleri Görme ve systemd Yönetimi

Sunucuda arka planda çalışan servisleri listeleme, sağlık durumunu ve otomatik başlama kurallarını teftiş etme.

```bash
# 1. Sunucuda Şu Anda Aktif Olarak Çalışan (RUNNING) Tüm Servisleri Listeleyin:
systemctl list-units --type=service --state=running --no-pager

# 2. Belirli Bir Servisin (Örn: Docker ve Nginx) Sağlık Durumunu Okuma:
systemctl is-active docker
systemctl is-active nginx

# 3. Servislerin Makine Yeniden Başladığında Açılıp Açılmayacağını Denetleme:
systemctl is-enabled docker
systemctl is-enabled nginx
# (enabled: Sistem açılışında otomatik başlar | disabled: Elle başlatılmalıdır)

# 4. Servisin Ayrıntılı Çalışma Tanımını (Unit File) Görüntüleme:
systemctl cat docker.service | grep -E "ExecStart|Restart|User"
```

---

### Bölüm 5: Sistem ve Servis Loglarını İnceleme (`journalctl` & `/var/log`)

Bir arıza anında (incident) ezbere komut çalıştırmak yerine doğrudan log kanıtına başvurulur.

```bash
# 1. Bir Servisin Son Log Kayıtlarını İnceleme (Docker servisi örneği):
journalctl -u docker -n 30 --no-pager

# 2. Sistem Açılışından (Boot) İtibaren Yalnızca HATA (ERROR / CRITICAL) Loglarını Filtreleme:
journalctl -p err -b --no-pager | head -n 15

# 3. Belirli Bir Zaman Dilimine Göre Log Sorgulama:
journalctl --since "30 min ago" --no-pager | head -n 20

# 4. Systemd Günlük Dosyalarının Diskte Kapladığı Toplam Alanı Denetleme:
journalctl --disk-usage

# 5. Güvenlik ve Yetkilendirme Günlüklerini İnceleme (SSH girişleri ve Sudo logları):
sudo cat /var/log/auth.log 2>/dev/null | grep -E "Accepted|session opened" | tail -n 10 || journalctl _COMM=sudo -n 10 --no-pager
```

---

### Bölüm 6: Ağ, Port ve HTTP Teftiş Komutları

Uygulama hazır olsa dahi ağ veya port seviyesindeki bir hata dış erişimi engeller.

```bash
# 1. Ağ Arayüzlerini (Network Interfaces) ve IP Adreslerini İnceleyin:
ip -brief addr show

# 2. Varsayılan Ağ Geçidini (Default Gateway / Routing Table) Kontrol Edin:
ip route show

# 3. Sunucuda Dinlenen (LISTEN) Tüm Portları ve Soketleri İnceleyin:
# -t (TCP), -u (UDP), -l (Listen), -p (Process/Program adı), -n (Sayısal Port)
sudo ss -tulpn | head -n 15

# 4. DNS Çözümleme Yapılandırmasını Denetleyin:
cat /etc/resolv.conf
cat /etc/hosts | head -n 8

# 5. Alan Adı Çözümleme Testi (DNS Resolution):
nslookup google.com || dig google.com +short

# 6. HTTP Sağlık Denetimi (Header / Yanıt Kodu Kontrolü):
curl -I -s http://127.0.0.1:80 | head -n 5 || echo "Port 80 HTTP yanıtı kontrol edildi."
```

---

### Bölüm 7: Paket Yönetimi (Port Çakışması Olmadan CLI Araçları Kurma & Kaldırma)

Arka plan servisi ve ağ portu **açmayan** hafif bir CLI analiz aracı (`ncdu`) kurarak `apt` döngüsünü deneyimleyin.

```bash
# 1. APT Paket İndeksini Güncelleyin:
sudo apt-get update -y

# 2. Paket Bilgisini ve Sürümünü Depodan Sorgulayın:
apt-cache policy ncdu

# 3. Paketi Kurun (ncdu: Ncurses Disk Usage - Bağımsız CLI aracı, port açmaz):
sudo apt-get install -y ncdu

# 4. Kurulumu Doğrulayın ve Sürümünü Test Edin:
which ncdu
ncdu -v
dpkg -s ncdu | grep -E "Package:|Version:|Status:"

# 5. Paketi Sistemden Temizleyin (Kaldırma):
sudo apt-get remove -y ncdu
echo "✅ Test paketi sistemden kaldırıldı. Sıfır port ve sıfır atık."
```

---

### Bölüm 8: Güvenli Sandbox Alanı, İzinler (`chmod`, `chown`) ve Metin İşleme

Tüm dosya oluşturma ve metin filtreleme pratikleri izole sandbox içinde yürütülür.

```bash
# 1. İzole Sandbox Dizinini Oluşturun ve Geçiş Yapın:
cd ~/docker-labs/lab-00-linux
mkdir -p sandbox
cd sandbox

# 2. Güvenli Dosya İzinleri Pratiği:
cat <<'EOF' > deploy.sh
#!/bin/bash
echo "DevOps Deploy Scripti Calisti!"
EOF

# Çalıştırma izni ekleyin (chmod 755):
chmod 755 deploy.sh
./deploy.sh

# Gizli dosya izin standardı (chmod 600 - Yalnızca sahip okur/yazar):
touch api-token.env
chmod 600 api-token.env
ls -l api-token.env
# (Beklenen İzin: -rw-------)

# Dosyanın üst dizinler dahil izin zincirini denetleyin:
namei -l $(pwd)/deploy.sh

# 3. Metin Filtreleme ve Pipeline Zinciri (grep, awk, uniq):
cat <<EOF > server.log
2026-09-22 01:00:01 INFO [auth] User admin login successful
2026-09-22 01:00:15 WARN [api] Latency high on /api/v1/products
2026-09-22 01:00:22 ERROR [db] Connection timeout to postgres
2026-09-22 01:00:45 INFO [auth] User student login successful
2026-09-22 01:01:02 ERROR [gateway] 502 Bad Gateway
2026-09-22 01:01:10 ERROR [db] Connection timeout to postgres
EOF

# Hata satırlarını filtreleyin ve modül bazında gruplayın:
grep "ERROR" server.log | awk '{print $4}' | sort | uniq -c
# (Beklenen Çıktı: 2 [db], 1 [gateway])

# 4. Güvenli Süreç Sonlandırma Deneyi:
sleep 120 &
DUMMY_PID=$!
echo "Kukla Surec Baslatildi: PID ${DUMMY_PID}"
kill -15 "${DUMMY_PID}"
sleep 0.5
ps -p "${DUMMY_PID}" >/dev/null || echo "✅ Süreç kontrollü sonlandırıldı (SIGTERM)."
```

---

## ✅ Otomatik Doğrulama (Verification)

Tüm adımların Ubuntu üzerinde sorunsuz çalıştığını tek bir komutla doğrulamak için dizindeki test betiğini çalıştırın:

```bash
cd ~/docker-labs/lab-00-linux
bash ./verify.sh
```
*Tüm test adımlarının yeşil `✅ Başarılı` olduğunu ve `Exit Code 0` ile tamamlandığını görün.*

---

## 🧹 Güvenli Temizlik

Laboratuvar boyunca açılan test dosyaları yalnızca `sandbox` dizinindedir. Sunucuyu temizlemek için:

```bash
cd ~/docker-labs/lab-00-linux
rm -rf sandbox
echo "✅ Sandbox temizlendi. Sunucuda hiçbir yabancı kalıntı veya servis değişikliği bulunmamaktadır."
```
