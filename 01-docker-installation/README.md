# LAB-01 — Ubuntu 24.04/22.04 Üzerine Resmi Docker Engine ve Compose Kurulumu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 30 dakika | `docker-ce`, `docker-compose-plugin`, `systemd` | `-` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 10-14); Ubuntu sunucumuz üzerine Docker konteyner motorunu, resmi Docker APT deposunu ve modern eklentileri (Buildx ve Docker Compose V2) **resmi Docker dokümantasyonuna** birebir sadık kalarak kurmak ve sudo yetkisi olmadan güvenle çalıştırmaktır:

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

## 6. Doğal Doğrulama ve Beklenen Sonuç

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

* **Beklenen Başarı Çıktısı:**
  * `docker version` çıktısında hem Client hem de Server versiyonları `24.x` veya üzeri görünmelidir.
  * `docker compose version` çıktısında `Docker Compose version v2.x` görülmelidir.
  * `hello-world` konteyneri `Hello from Docker! This message shows that your installation appears to be working correctly.` mesajını basmalıdır.

---

## 7. Temizlik

Laboratuvar doğrulamasında indirilen `hello-world` test imajını silin:

```bash
docker rmi hello-world 2>/dev/null || true
```
