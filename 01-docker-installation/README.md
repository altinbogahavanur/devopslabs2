# LAB-DOC-01 — Ubuntu Üzerine Resmi Docker Engine ve Compose Kurulumu

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç | `docker-ce`, `docker-compose-plugin`, `portainer` | 9000, 9443 |

> **Önemli Erişim Notu:** Portainer web arayüzüne erişirken `http://<SUNUCU-IP>:9000` adresini kullanabilir veya yerel doğrulama için `curl http://localhost:9000` komutunu çalıştırabilirsiniz.
> 
> [!WARNING]
> **Platform & Canlı Ortam Güvenlik Uyarısı:** Azure eğitim sanal makinesinde Docker Engine ve Docker Compose V2 **zaten önceden kurulu ve aktif** durumdadır. Arka planda GitLab, Jenkins, Harbor ve KinD gibi temel servisler çalışmaktadır. Bu servislerin kesintiye uğramaması için `install-docker.sh` betiğindeki APT paket temizliğini (`apt remove containerd runc`) ve Docker daemon'ı yeniden başlatma (`systemctl restart docker`) adımlarını **çalıştırmayınız**. Bu laboratuvarda kurulum prensiplerini inceleyip doğrudan **Adım 7 / Doğal Doğrulama** komutlarıyla motor yapılandırmasını denetleyiniz.

---

## 1. Amaç

Bu laboratuvarın amacı; Ubuntu sunucumuz üzerine Docker konteyner motorunu, resmi Docker APT deposunu ve modern eklentileri (Buildx ve Docker Compose V2) **resmi Docker dokümantasyonuna** birebir sadık kalarak kurmak ve sudo yetkisi olmadan güvenle çalıştırmaktır:

1. **Dağıtım Paketlerinin Temizliği:** Dağıtımla gelen eski ve güncel olmayan paketlerin (`docker.io`, `podman-docker`) kaldırılması.
2. **Resmi APT ve GPG Entegrasyonu:** Güvenilir Docker paket deposunun anahtar doğrulama ile eklenmesi.
3. **Modern Motor Bileşenleri:** `docker-ce`, `containerd.io`, `docker-buildx-plugin` ve `docker-compose-plugin` kurulumu.
4. **Sudo Bağımsızlığı:** Mevcut kullanıcının `docker` grubuna dahil edilmesi.
5. **Log Rotasyonu Yapılandırması:** `/etc/docker/daemon.json` ile disk taşmalarını önleyici log sınırlarının belirlenmesi.

> **Resmi Dokümantasyon Kaynağı:** [Docker Engine Installation Guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

---

## 2. Ön Koşullar

* Ubuntu 22.04 veya 24.04 LTS kurulu sunucu erişimi.
* `sudo` yetkili kullanıcı oturumu.
* LAB-00 Linux hazırlıklarının tamamlanmış olması.

---

## 3. Mimari ve Bileşenler

```text
+─────────────────────────────────────────────────────────────────────────────+
|                         UBUNTU İŞLETİM SİSTEMİ                              |
|                                                                             |
|  [ Linux Kernel: cgroups v2, namespaces, overlayfs ]                        |
+─────────────────────────────────────────────────────────────────────────────+
                                      │
                         DOCKER KURULUM KATMANLARI
                                      ▼
+─────────────────────────────────────────────────────────────────────────────+
| 1. DAEMON & ENGINE: dockerd + containerd                                    |
|    - /var/run/docker.sock (UNIX Socket)                                     |
|    - /etc/docker/daemon.json (Log rotasyonu ve storage driver)              |
+─────────────────────────────────────────────────────────────────────────────+
| 2. CLI VE EKLENTİLER:                                                       |
|    - docker (Ana Komut Satırı)                                              |
|    - docker compose (Compose V2 CLI Plugin)                                 |
|    - docker buildx (Modern BuildKit Derleyicisi)                            |
+─────────────────────────────────────────────────────────────────────────────+
| 3. KULLANICI GÜVENLİK YETKİSİ:                                              |
|    - docker group (/var/run/docker.sock rw izni)                            |
|    - Sudo şifresi girmeden 'docker run' çalıştırabilme                |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 4. Görevler (Tasks)

1. **Eski Paketleri Temizleme:** Sistemdeki olası eski paketleri (`docker.io`, `docker-doc`, `docker-compose`, `podman-docker`, `containerd`, `runc`) temizleyin.
2. **Resmi Docker APT Deposunu Ekleme:** Gerekli sertifika paketlerini yükleyin, Docker GPG anahtarını `/etc/apt/keyrings/docker.asc` olarak kaydedin ve kaynak listesine ekleyin.
3. **Docker Engine ve Eklentilerini Kurma:** `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` ve `docker-compose-plugin` paketlerini kurun.
4. **Sudo'suz Kullanım:** Mevcut kullanıcınızı `docker` grubuna ekleyin ve oturumu yenileyerek sudo olmadan çalışabilir hale getirin.
5. **Log Rotasyonu Yapılandırması:** `/etc/docker/daemon.json` dosyasını oluşturarak maksimum log dosya boyutunu 50MB ve maksimum dosya adedini 3 ile sınırlandırın; servisi yeniden başlatıp otomatik başlatmayı (`enable`) açın.
6. **İlk Konteyner Testi:** `docker run --rm hello-world` komutu ile motorun çalıştığını doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: "Permission Denied" Hatası</summary>

Kullanıcıyı `usermod -aG docker $USER` ile gruba ekledikten sonra terminal oturumunu kapatıp açmazsanız veya `newgrp docker` komutunu işletmezseniz Docker UNIX soketine (`/var/run/docker.sock`) erişirken yetki hatası alırsınız.
</details>

<details>
<summary>💡 İpucu 2: Compose V1 (docker-compose) vs Compose V2 (docker compose)</summary>

Eski Python tabanlı `docker-compose` komutu artık kullanımdan kalkmıştır. Modern sistemlerde Go dili ile doğrudan Docker CLI eklentisi olarak yazılmış `docker compose` (arada tire olmadan) komutu kullanılır.
</details>

<details>
<summary>💡 İpucu 3: Neden daemon.json Log Sınırı Şart?</summary>

Varsayılan yapılandırmada Docker konteyner logları sonsuza kadar büyür ve özellikle log üreten yoğun uygulamalarda sunucu diskini tamamen doldurarak kernel paniklerine yol açabilir (`json-file` max-size ve max-file ayarları bu riski sıfırlar).
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Komutlar (Tıklayınca Açılır)</summary>

### Adım 1: Eski veya Dağıtım Paketlerinin Temizlenmesi
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" 2>/dev/null || true
done
```

### Adım 2: Docker Resmi APT Deposunun ve GPG Anahtarının Eklenmesi
```bash
# 1. Gerekli sertifika araçlarını kurma
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Keyrings dizinini oluşturma ve GPG anahtarını indirme
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. Docker APT deposunu sources.list.d altına ekleme
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Paket listesini güncelleme
sudo apt-get update
```

### Adım 3: Docker Engine, Buildx ve Compose Kurulumu
```bash
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

### Adım 4: Root Olmayan Kullanıcı İzni (docker Grubu)
```bash
# Mevcut kullanıcıyı docker grubuna ekleme
sudo usermod -aG docker "$USER"

# Grup yetkisini geçerli oturumda aktif etme
newgrp docker
```

### Adım 5: Üretim Seviyesi Log Rotasyonu Yapılandırması
```bash
sudo mkdir -p /etc/docker
cat << 'DAEMON_EOF' | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
DAEMON_EOF

# Servisi yeniden başlatma ve etkinleştirme
sudo systemctl restart docker
sudo systemctl enable docker
```

### Adım 6: Otomasyon Betikleriyle Kurulum (Alternatif)
```bash
cd ~/docker-labs/01-docker-installation
chmod +x scripts/*.sh
./scripts/install-docker.sh
./scripts/verify-install.sh
```

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla Docker motorunun sağlıklı çalıştığını teyit edin:

```bash
# 1. Servis durumu
systemctl status docker --no-pager

# 2. Versiyon ve eklenti kontrolü
docker version
docker compose version
docker buildx version

# 3. Test konteyneri çalıştırma
docker run --rm hello-world
```

---

### Adım 7: Portainer CE ile Görsel Yönetim Paneli Kurulumu (Opsiyonel)

Konteynerları, imajları, volume ve ağları web arayüzünden görsel olarak denetlemek için Portainer CE başlatılır:

```bash
# 1. Kalıcı volume oluşturma
docker volume create portainer_data

# 2. Portainer CE konteynerini başlatma
docker run -d -p 8000:8000 -p 9443:9443 -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

*Tarayıcınızdan `http://localhost:9000` veya `https://localhost:9443` adresine giderek ilk admin şifrenizi belirleyin.*

---

* **Beklenen Başarı Çıktısı:**
  * `docker version` çıktısında hem Client hem de Server versiyonları `24.x` veya üzeri görünmelidir.
  * `docker compose version` çıktısında `Docker Compose version v2.x` görülmelidir.
  * `hello-world` konteyneri `Hello from Docker! This message shows that your installation appears to be working correctly.` mesajını basmalıdır.

---

## 8. Temizlik

Laboratuvar doğrulamasında indirilen `hello-world` test imajını silin:

```bash
docker rmi hello-world 2>/dev/null || true
```
