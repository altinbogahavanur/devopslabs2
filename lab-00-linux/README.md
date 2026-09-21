# LAB-00: Linux Temelleri, Sistem Yönetimi ve Sorun Giderme (DevOps Essentials)

| Seviye | Profil / Araçlar | İlgili Eğitim Sunumu | Çalışma Alanı (Sandbox) |
| :--- | :--- | :--- | :--- |
| Başlangıç - Orta | `bash`, `coreutils`, `systemd`, `iproute2`, `apt`, `procps` | **`3-Linux_Fundamentals.pptx` (Slayt 01 - 40)** | `~/docker-labs/lab-00-linux/sandbox` |

---

## 🎯 Labın Amacı
Modern DevOps dünyasında çalışan tüm bileşenler (Docker konteynerleri, Kubernetes node'ları, CI/CD runner'ları ve bulut sunucuları) Linux üzerinde koşar. Bu laboratuvarın amacı, **`3-Linux_Fundamentals.pptx`** sunumundaki 40 slaytlık müfredatı adım adım pratik uygulamaya dökmek; **Ubuntu sunucusunun mevcut çalışan servislerini bozmadan (Zero-Impact / Sandbox modeliyle)** dosya sistemi, süreç (process), paket, disk, ağ ve güvenlik katmanlarında profesyonel kanıt toplama ve analiz yetkinliği kazanmaktır.

---

## 🧭 Sunum Slaytları ve Lab Eşleştirme Tablosu

| Sunum Bölümü | İlgili Slaytlar | Lab Konu Başlığı | Öğrenilecek Temel Komutlar & Beceriler |
| :--- | :---: | :--- | :--- |
| **Giriş & Mimari** | Slayt 01 - 07 | **Bölüm 1:** Linux Mimarisi, Shell ve Çıkış Kodları | `uname -a`, `cat /etc/os-release`, `echo $?`, Standard Streams (`>`, `2>`, `\|`) |
| **Dosya Sistemi** | Slayt 08 - 12 | **Bölüm 2:** Dizin Hiyerarşisi, Güvenli Dosya İşlemleri & Metin Filtreleme | `pwd`, `ls -lah`, `mkdir -p`, `cat`, `head`, `tail`, `grep`, `awk`, `sort`, `uniq` |
| **Kullanıcı & İzinler** | Slayt 13 - 17 | **Bölüm 3:** Kullanıcı Kimlikleri, Dosya İzinleri (`rwx`) ve `sudo` | `id`, `whoami`, `chmod` (Oktal: 755, 644, 600), `chown`, `namei -l`, `sudo -l` |
| **Paket Yönetimi** | Slayt 18 - 22 | **Bölüm 4:** Paket Yaşam Döngüsü ve Sürüm Sorgulama | `dpkg -l`, `dpkg -s`, `apt-cache policy`, `/etc/apt/sources.list.d/` |
| **Disk & Depolama** | Slayt 23 - 26 | **Bölüm 5:** Disk, Kapasite, Inode ve Büyük Dizin Analizi | `lsblk`, `df -hT`, `df -i` (Inode kontrolü), `du -xhd1`, `/etc/fstab` |
| **Process & Servisler** | Slayt 27 - 32 | **Bölüm 6:** Süreç (Process) Yönetimi, Yük Analizi ve systemd | `ps aux`, `top`, `uptime`, Güvenli Sinyaller (`kill -15` / `SIGTERM`), `systemctl`, `journalctl` |
| **Ağ ve Portlar** | Slayt 33 - 36 | **Bölüm 7:** Ağ Arayüzleri, Yönlendirme, Dinlenen Portlar ve DNS | `ip addr`, `ip route`, `ss -tulpn`, `/etc/resolv.conf`, `nslookup`, `curl -I` |
| **Güvenli Erişim** | Slayt 37 - 40 | **Bölüm 8:** SSH Anahtar Mimarisi ve Erişim İzinleri | `ssh-keygen`, `chmod 600`, `chmod 700`, `~/.ssh/authorized_keys` yapısı |

---

## 🛡️ Güvenlik Kuralı: Sistemi Bozmadan Çalışma İlkesi

> [!IMPORTANT]
> **Kritik Kurallar:**
> 1. **İzole Sandbox Çalışması:** Yeni dosya oluşturma, isim değiştirme, silme ve izin denemeleri **yalnızca** `~/docker-labs/lab-00-linux/sandbox` dizini içinde yapılacaktır.
> 2. **Sistem Dizinleri Salt Okunurdur:** `/etc`, `/var`, `/usr`, `/opt` gibi işletim sistemi dizinleri yalnızca inceleme (`cat`, `ls`, `grep`, `head`, `findmnt`) amacıyla okunur; bu dizinlerde asla `rm`, `mv` veya `chmod` çalıştırılmaz.
> 3. **Güvenli Sinyal Simülasyonu:** Süreç sonlandırma (`kill`) alıştırmasında sistemin veya Docker'ın process'leri değil, öğrencinin kendisinin başlattığı zararsız bir arka plan görevi (`sleep 300 &`) hedef alınır.

---

## 🚀 Adım Adım Uygulama

### Bölüm 1: Linux Mimarisi, Shell ve Çıkış Kodları (Slayt 05 - 07)

Linux'ta her komut user-space'te çalışır, kernel üzerinden kaynaklara erişir ve tamamlandığında bir **çıkış kodu (Exit Code)** üretir.

```bash
# 1. Lab çalışma dizinine geçin ve izole sandbox klasörünü hazırlayın:
cd ~/docker-labs/lab-00-linux
mkdir -p sandbox
cd sandbox

# 2. Çekirdek (Kernel) ve dağıtım bilgilerini sorgulayın (Slayt 05):
uname -srm
cat /etc/os-release | grep -E "PRETTY_NAME|VERSION_ID"

# 3. Mevcut kabuk ve kullanıcı oturumunu teyit edin (Slayt 06):
echo "Aktif Kabuk: $SHELL | Kullanıcı: $(whoami) | Çalışma Dizini: $(pwd)"

# 4. Çıkış Kodu (Exit Code) Mekanizması (Slayt 07):
# Başarılı bir komut daima 0 döndürür:
ls / > /dev/null
echo "Başarılı Komut Çıkış Kodu: $?"
# (Beklenen: 0)

# Hatalı bir komut sıfırdan farklı bir hata kodu döndürür:
ls /olmayan_dizin_12345 2>/dev/null || true
echo "Hatalı Komut Çıkış Kodu: $?"
# (Beklenen: 2 - No such file or directory)

# 5. Standart Akışlar (stdout vs stderr) ve Yönlendirme (Slayt 06):
echo "Bu standart bir ciktidir (stdout)" > app.log
ls /olmayan_dosya 2> error.log || true

# Dosyaların içeriğini teyit edin:
cat app.log
cat error.log
```

---

### Bölüm 2: Dizin Hiyerarşisi, Dosya İşlemleri ve Filtreleme (Slayt 08 - 12)

FHS (Filesystem Hierarchy Standard) uyarınca sistem dizinlerinin rollerini okuyun ve sandbox içinde güvenli metin filtreleme zinciri kurun.

```bash
# 1. Standart sistem dizinlerini inceleyin (Slayt 10):
# /etc     -> Konfigürasyon dosyaları
# /var/log -> Log dosyaları
# /opt     -> Üçüncü parti yazılımlar (Harbor vb.)
# /proc    -> Kernel ve process sanal dosya sistemi
ls -ld /etc /var/log /opt /proc

# 2. Sandbox içinde güvenli hiyerarşik dizinler oluşturun (Slayt 08):
mkdir -p app/{conf,logs,data}
touch app/conf/app.env
touch app/data/database.sqlite

# 3. Gerçekçi bir log dosyası simülasyonu oluşturun (Slayt 11):
cat <<EOF > app/logs/access.log
2026-09-22 01:00:01 INFO [auth] User admin login successful from 192.168.1.10
2026-09-22 01:00:15 WARN [api] Latency high on /api/v1/products (450ms)
2026-09-22 01:00:22 ERROR [db] Connection timeout to postgres-master:5432
2026-09-22 01:00:45 INFO [auth] User student login successful from 192.168.1.20
2026-09-22 01:01:02 ERROR [gateway] 502 Bad Gateway upstream unavailable
2026-09-22 01:01:10 ERROR [db] Connection timeout to postgres-master:5432
2026-09-22 01:01:30 INFO [api] Health check passed 200 OK
EOF

# 4. Dosya Okuma Araçları (Slayt 11):
# İlk 2 satırı okuma:
head -n 2 app/logs/access.log

# Son 3 satırı okuma:
tail -n 3 app/logs/access.log

# 5. Pipe (|), grep, awk ve uniq ile İleri Seviye Filtreleme (Slayt 12):
# Yalnızca ERROR içeren satırları filtreleyin:
grep "ERROR" app/logs/access.log

# Hangi modülde kaç hata olduğunu özetleyin (Pipeline gücü):
grep "ERROR" app/logs/access.log | awk '{print $4}' | sort | uniq -c
# (Beklenen: 2 [db], 1 [gateway])
```

---

### Bölüm 3: Kullanıcılar, Dosya İzinleri (`rwx`) ve `sudo` (Slayt 13 - 17)

Linux'ta her process bir kullanıcıya aittir ve dosya izinleri `rwx` (Okuma: 4, Yazma: 2, Çalıştırma: 1) oktal aritmetiğiyle hesaplanır.

```bash
# 1. Kendi kullanıcı ve grup kimliğinizi (UID / GID) inceleyin (Slayt 13):
id

# 2. Dosya İzinlerinin Anatomisi (Slayt 15):
# Sahip (u) | Grup (g) | Diğerleri (o)
# -rw-r--r-- (644) -> Sahip okur/yazar, grup ve diğerleri sadece okur.
# -rwxr-xr-x (755) -> Sahip her şeyi yapar, diğerleri okur ve çalıştırır.
# -rw------- (600) -> Yalnızca sahip okur/yazar (Secret & SSH standardı).

# 3. İzin Deneyi (Sandbox içinde güvenle test edin):
cat <<'EOF' > script.sh
#!/bin/bash
echo "Linux Scripti Basariyla Calisti!"
EOF

# İzinleri listeleyin (Varsayılan olarak çalıştırma yetkisi yoktur):
ls -l script.sh

# Çalıştırmayı deneyin (Beklenen: Permission denied):
./script.sh || echo "Beklenen Hata: Calistirma yetkisi yok!"

# Çalıştırma izni ekleyin (chmod +x veya chmod 755):
chmod 755 script.sh
./script.sh

# 4. Sıkı İzin Modeli (chmod 600 - Güvenli Dosya):
touch secret.env
chmod 600 secret.env
ls -l secret.env
# (Beklenen Çıktı: -rw-------)

# 5. Dizin Hiyerarşisinde İzin Zincirini İnceleme (Slayt 16):
namei -l $(pwd)/script.sh

# 6. Sudo Yetki Sınırlarını Sorgulama (Slayt 17):
# Parolasız veya izin verilen komut listesini görüntüleyin:
sudo -l
```

---

### Bölüm 4: Paket Yönetimi ve Sürüm Sorgulama (Slayt 18 - 22)

Ubuntu üzerinde `apt` ve `dpkg` araçları yazılım paketlerinin yaşam döngüsünü ve bağımlılıklarını yönetir.

```bash
# 1. Kurulu paketleri arama ve listeleme (Slayt 19):
dpkg -l | grep -E "docker|curl|nginx" | head -n 5

# 2. Belirli bir paketin durumunu ve kurulu dosyalarını inceleme:
dpkg -s curl | grep -E "Package:|Version:|Status:"

# 3. Paket Deposunun (Repository) ve Sürüm Politikasının Kontrolü (Slayt 22):
apt-cache policy curl

# 4. Sistemdeki aktif APT kaynak listelerini okuma (Salt Okunur):
ls -l /etc/apt/sources.list.d/
```

---

### Bölüm 5: Disk, Kapasite, Inode ve Alan Analizi (Slayt 23 - 26)

Bir sunucuda disk alanı boş görünse dahi **Inode (dosya tablosu göstericisi)** dolduysa yeni dosya yazılamaz. Disk yönetimi bu iki metriğin birlikte incelenmesini gerektirir.

```bash
# 1. Fiziksel ve Mantıksal Blok Aygıtlarını İnceleyin (Slayt 24):
lsblk

# 2. Filesystem Alan Kullanımını İnceleyin (Slayt 25):
df -hT /

# 3. Inode (Dosya Sayısı Sınırı) Kullanımını İnceleyin:
df -i /
# (Not: %100 Inode doluluğu, sıfır byte dosya dahi olsa disk doldu hatası üretir).

# 4. Hangi Dizinlerin Ne Kadar Alan Tükettiğini Sıralayın:
# /var dizinindeki ilk seviye klasörlerin boyut sıralaması:
sudo du -xhd1 /var 2>/dev/null | sort -h | tail -n 8

# 5. Kalıcı Disk Bağlama Dosyasını (/etc/fstab) İnceleyin (Slayt 26):
cat /etc/fstab | grep -v "^#"
```

---

### Bölüm 6: Süreç (Process) Yönetimi, Yük Analizi ve systemd (Slayt 27 - 32)

Uygulama çökmelerinde ve kaynak darboğazlarında process tablosunu ve systemd servis günlüklerini analiz etme adımları.

```bash
# 1. Anlık Sistem Yükünü (Load Average) Okuma (Slayt 29):
# 1 dk, 5 dk ve 15 dk ortalama kuyruk uzunluğu:
uptime

# 2. En Çok Bellek Tüketen İlk 5 Süreci Sıralama (Slayt 28):
ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 6

# 3. Güvenli Sinyal ve Process Sonlandırma Laboratuvarı (Slayt 30):
# Sisteme zarar vermeyecek zararsız bir arka plan süreci başlatın:
sleep 300 &
DUMMY_PID=$!
echo "Kukla Surec Baslatildi - PID: ${DUMMY_PID}"

# Sürecin çalıştığını teyit edin:
ps -p "${DUMMY_PID}"

# Nazik Kapatma Sinyali Gönderin (SIGTERM / 15):
kill -15 "${DUMMY_PID}"
sleep 1

# Kapanıp kapanmadığını doğrulayın:
if ! ps -p "${DUMMY_PID}" > /dev/null; then
  echo "✅ Surec SIGTERM ile kontrollu sekilde sonlandirildi."
fi

# 4. systemd Servis Durumunu ve Canlı Günlükleri Okuma (Slayt 31 - 32):
# Docker servisinin durumunu inceleyin:
systemctl is-active docker
systemctl is-enabled docker

# Servisin son 5 log kaydını systemd journal'dan okuyun:
journalctl -u docker -n 5 --no-pager
```

---

### Bölüm 7: Ağ Mimarisi, Portlar ve DNS Çözümleme (Slayt 33 - 36)

Servislerin erişilebilirliğini; IP katmanı, dinlenen portlar (socket'ler) ve DNS çözümleme sırasıyla teftiş edin.

```bash
# 1. Ağ Arayüzlerini ve IP Adreslerini İnceleyin (Slayt 34):
ip -brief addr show

# 2. Varsayılan Ağ Geçidini (Default Gateway) Kontrol Edin:
ip route show

# 3. Sunucuda Dinlenen (LISTEN) TCP/UDP Portlarını İnceleyin (Slayt 35):
# ss (Socket Statistics): -t (TCP), -u (UDP), -l (Listen), -p (Process), -n (Numeric Port)
sudo ss -tulpn | head -n 12

# 4. DNS Çözümleme Yapılandırmasını İnceleyin (Slayt 36):
cat /etc/resolv.conf
cat /etc/hosts | head -n 10

# 5. Alan Adı Çözümleme Testi (DNS Lookup):
nslookup google.com || dig google.com +short

# 6. HTTP Uç Noktası Sağlık Kontrolü (Header İnceleme):
curl -I -s http://127.0.0.1:80 | head -n 5 || echo "Port 80 HTTP kontrol edildi."
```

---

### Bölüm 8: Güvenli Erişim: SSH Anahtarları ve İzin Standartları (Slayt 37 - 40)

SSH bağlantılarında parola yerine asimetrik şifreleme (Public/Private Key) kullanılır. SSH istemcisi izin kurallarında çok katıdır; dosya izinleri yanlışsa (`chmod 777` gibi) bağlantıyı güvenlik nedeniyle reddeder.

```bash
# 1. SSH Standart İzin Kuralları (Slayt 38):
# ~/.ssh dizini            -> 700 (drwx------)
# ~/.ssh/id_rsa (Private)  -> 600 (-rw-------) veya 400
# ~/.ssh/id_rsa.pub        -> 644 (-rw-r--r--)
# ~/.ssh/authorized_keys   -> 600 (-rw-------)

# 2. Sandbox İçinde Test Amaçlı Yeni Bir SSH Anahtar Çifti Üretin:
ssh-keygen -t ed25519 -f ./test_ssh_key -N "" -C "lab-test-key"

# 3. Üretilen Anahtarların Boyut ve İzinlerini İnceleyin:
ls -la test_ssh_key*
# Private key: test_ssh_key (Gizli kalmalı)
# Public key : test_ssh_key.pub (Sunuculara dağıtılır)

# 4. Public Anahtar İçeriğini İnceleyin:
cat test_ssh_key.pub
```

---

## ✅ Doğrulama (Verification)

Laboratuvar adımlarını tamamladığınızda, aşağıdaki kontrol komutlarıyla ortamın sıfır hata ve sıfır sistem hasarıyla çalıştığını teyit edin:

```bash
# 1. Sandbox dizininde üretilen dosyaların sağlamlığı:
ls -la ~/docker-labs/lab-00-linux/sandbox/app/logs/access.log
ls -la ~/docker-labs/lab-00-linux/sandbox/test_ssh_key

# 2. Sistem temel servislerinin (Docker, Nginx) saglikli calistigi:
systemctl is-active docker
systemctl is-active nginx

# 3. Sunucu portlarının ve yerel API'ların aktif olduğu:
curl -s http://127.0.0.1:18444/api/v2.0/systeminfo > /dev/null && echo "✅ Harbor & Docker Calisiyor"
```

---

## 🧹 Güvenli Temizlik

Laboratuvar boyunca oluşturulan tüm geçici dosyalar yalnızca `sandbox` dizinindedir. Sunucuyu ilk temiz haline getirmek için sandbox klasörünü silmeniz yeterlidir:

```bash
cd ~/docker-labs/lab-00-linux
rm -rf sandbox
echo "✅ Sandbox temizlendi. Ubuntu sunucusu ilk temiz durumundadır."
```
