# 🐳 Docker ve Konteyner Teknolojileri Laboratuvarları

Bu depo, temel Linux sistem yönetiminden kurumsal mikroservis mimarilerine, çok dilli (polyglot) uygulama paketlemeden kod kalitesi/güvenlik taramasına (SAST) ve OCI registry yönetimine kadar modern konteyner teknolojilerini uçtan uca uygulamak üzere hazırlanmış standart laboratuvar serisidir.

---

## 🛠️ Ubuntu İçin Docker ve Docker Compose Kurulumu (Idempotent)

Aşağıdaki kurulum bloğu **idempotent** (yeniden çalıştırılabilir) mantıkta tasarlanmıştır. Sisteminizde Docker zaten kuruluysa herhangi bir hata vermeden mevcut sürüm bilgilerini görüntüler; Docker kurulu değilse resmi Docker CE, CLI, containerd ve Docker Compose eklentilerini kurup servisi aktif eder.

```bash
#!/usr/bin/env bash
set -euo pipefail

if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1; then
    echo "=========================================================="
    echo "✅ Docker zaten sistemde kurulu:"
    docker --version
    docker compose version 2>/dev/null || true
    echo "=========================================================="
else
    echo "=========================================================="
    echo "🚀 Docker Engine ve Compose Kurulumu Başlatılıyor..."
    echo "=========================================================="
    
    # 1. Eski paket kalıntılarını güvenle kaldır
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y "$pkg" 2>/dev/null || true
    done

    # 2. Ön koşul paketleri ve GPG anahtarı
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # 3. Resmi Docker APT deposu
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 4. Paketleri kur
    sudo apt-get update
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # 5. Non-root yetkisi ve servis aktivasyonu
    sudo usermod -aG docker "$USER"
    sudo systemctl enable --now docker

    echo "=========================================================="
    echo "✅ Docker kurulumu tamamlandı!"
    docker --version
    docker compose version
    echo "=========================================================="
fi
```

> **Not:** Scripti dosya üzerinden çalıştırmak isterseniz:
> ```bash
> bash ~/docker-labs/lab-01-container-lifecycle-and-cli/scripts/install-docker.sh
> ```

---

## 🌐 Host Üzerinde Açılması Gereken Portlar (Güvenlik Duvarı & Güvenlik Grubu)

Eğitim veya üretim sunucusunda laboratuvarların sorunsuz çalışması ve web tarayıcısından erişilebilmesi için host güvenlik duvarında (UFW / Security Group) açılması gereken portların listesi aşağıdadır:

### 1. Port Dağılım Matrisi

| Servis / Kategori | Port | Protokol | Web Tarayıcı / İstemci Erişimi | Açıklama |
|---|:---:|:---:|---|---|
| **SSH Yönetimi** | `22` | TCP | `ssh <kullanıcı>@<SUNUCU-IP>` | Sunucu terminal erişimi |
| **HTTP Web (Nginx Proxy)** | `80` | TCP | `http://<SUNUCU-IP>/` | Ters vekil ana web erişim portu |
| **HTTPS Web (Nginx Proxy)** | `443` | TCP | `https://<SUNUCU-IP>/` | SSL sonlandırma ve güvenli web trafiği |
| **Harbor OCI Registry** | `18444` | TCP | `http://<SUNUCU-IP>:18444` | Doğrudan Docker CLI (`login/push/pull`) ve Harbor Core erişimi |
| **SonarQube Dashboard** | `19000` | TCP | `http://<SUNUCU-IP>:19000/sonar` | Statik kod analizi (SAST) ve Kalite Kapısı paneli |
| **App1 Slotu (Ana Stackler)** | `19001` | TCP | `http://<SUNUCU-IP>:19001` veya `/app1` | WordPress (Lab-07), 3-Tier Stack (Lab-08), NovaShop (Lab-14), Polyglot App (Lab-15) |
| **App2 - App8 Slotları (Arcade & Araçlar)** | `19002 - 19008` | TCP | `http://<SUNUCU-IP>:<PORT>` | IT-Tools (19002), Excalidraw (19003), 2048 (19004), FileBrowser (19005), WhoAmI (19006), Speedtest (19007), draw.io (19008) |
| **Temel CLI & Test Portları** | `8080 - 8086` | TCP | `http://<SUNUCU-IP>:<PORT>` | Lab-01 (8080), Lab-02 (8081), Lab-04 (8080), Lab-06 (8082), Lab-09 (8085-8086), Lab-10 (8080) test konteynerleri |
| **Node.js Uygulama Portları** | `3000, 3001` | TCP | `http://<SUNUCU-IP>:<PORT>` | Lab-03 Dockerfile ve ortam değişkeni testleri |
| **Python / Fundamentals API Portu** | `8000` | TCP | `http://<SUNUCU-IP>:8000` | Lab-08 Fundamentals ve Lab-15 Python test konteyneri |

### 2. Ubuntu UFW Güvenlik Duvarı Açma Komutları

```bash
# Yönetim ve Web Trafiği
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP Web'
sudo ufw allow 443/tcp comment 'HTTPS Web'

# Kurumsal Servisler ve App Slotları
sudo ufw allow 18444/tcp comment 'Harbor Enterprise OCI Registry'
sudo ufw allow 19000:19008/tcp comment 'SonarQube ve DevOps Uygulama Slotlari'

# Test ve Bireysel Konteyner Portlari
sudo ufw allow 8080:8086/tcp comment 'Docker Lab Standalone Portlar'
sudo ufw allow 3000:3001/tcp comment 'Docker Lab Node Portlari'
sudo ufw allow 8000/tcp comment 'Docker Lab Python API Portu'

sudo ufw reload
```

---

## 🗺️ Laboratuvar Kataloğu ve Çalışma Dizinleri

Tüm laboratuvar geçişleri standart tam yol formatında hazırlanmıştır. İlgili modüle başlamak için doğrudan verilen geçiş komutunu çalıştırmanız yeterlidir:

| Sıra | Laboratuvar Adı | Dizin / Geçiş Komutu | Açık Portlar | Kapsam ve Kazanımlar |
|:---:|---|---|:---:|---|
| **00** | [Linux Sistem Yönetimi & Teftiş](lab-00-linux/README.md) | `cd ~/docker-labs/lab-00-linux` | — | CPU, RAM, disk kapasitesi, Inode limitleri, kullanıcı ve yetki yönetimi, systemd servisleri, journalctl logları ve ağ arayüzü teftişi. |
| **01** | [Konteyner Yaşam Döngüsü & CLI](lab-01-container-lifecycle-and-cli/README.md) | `cd ~/docker-labs/lab-01-container-lifecycle-and-cli` | `8080` | Konteyner yaşam döngüsü komutları: `run`, `stop`, `start`, `restart`, `pause`, `unpause`, `kill`, `rm`, `prune` ve disk analizi (`df`). |
| **02** | [Canlı Hata Ayıklama & Log Yönetimi](lab-02-live-debugging-and-logging/README.md) | `cd ~/docker-labs/lab-02-live-debugging-and-logging` | `8081` | Canlı konteyner içine kabuk açma (`exec`), `docker cp` ile sıcak yama (hotfix), katman dosya farkları (`diff`), log filtreleme (`logs -t`) ve `inspect`. |
| **03** | [Sıfırdan Dockerfile & İmaj Derleme](lab-03-dockerfile-from-scratch/README.md) | `cd ~/docker-labs/lab-03-dockerfile-from-scratch` | `3000, 3001` | Linux terminal adımlarının Dockerfile direktiflerine dönüşümü (`FROM`, `WORKDIR`, `COPY`, `ENV`, `EXPOSE`, `CMD` vs `ENTRYPOINT`). |
| **04** | [Katman Önbellekleme & Multi-Stage](lab-04-layer-caching-and-multistage/README.md) | `cd ~/docker-labs/lab-04-layer-caching-and-multistage` | `8080` | Katman önbellekleme mekanizması (`CACHED`), `.dockerignore` kullanımı, Go ile çok aşamalı (Multi-Stage) derleme (850 MB -> 12 MB). |
| **05** | [Konteyner Ağları & Dahili DNS](lab-05-networking-and-dns/README.md) | `cd ~/docker-labs/lab-05-networking-and-dns` | — | Varsayılan köprü (bridge) kısıtları, kullanıcı tanımlı özel köprü ağı, gömülü DNS (`127.0.0.11`) ile isimle çözümleme ve ağ izolasyonu. |
| **06** | [Depolama: Bind Mount vs Volume](lab-06-storage-bind-mount-vs-volume/README.md) | `cd ~/docker-labs/lab-06-storage-bind-mount-vs-volume` | `8082` | Ephemeral veri kaybı deneyi, Bind Mount ile canlı kod senkronizasyonu (hot-reload), Named Volume ile veri kalıcılığı ve bellek içi `tmpfs`. |
| **07** | [Docker Compose Hızlı Başlangıç](lab-07-docker-compose-quickstart/README.md) | `cd ~/docker-labs/lab-07-docker-compose-quickstart` | `19001` | WordPress ve MariaDB veritabanı yığınının `docker-compose.yaml` ve `.env` ile tek komutla (`docker compose up -d`) ayağa kaldırılması. |
| **08** | [Docker Compose 3-Tier Mimari](lab-08-docker-compose-stack/README.md) | `cd ~/docker-labs/lab-08-docker-compose-stack/03-3tier-web-api-db` | `19001` | Frontend (Nginx), Backend (FastAPI), Database (Postgres) ve Cache (Redis) bileşenleri, izole iç/dış ağlar ve `service_healthy` bağımlılık zinciri. |
| **09** | [İmaj Etiketleme & Registry (Hub)](lab-09-image-tagging-and-registry/README.md) | `cd ~/docker-labs/lab-09-image-tagging-and-registry` | `8085, 8086` | Semantik imaj etiketleme, Docker Hub Public (`push/pull`) vs Private depo güvenliği, yetkisiz erişim engelleme testi (`pull access denied`). |
| **10** | [Konteyner Güvenliği: Non-Root & Distroless](lab-10-distroless-and-nonroot-security/README.md) | `cd ~/docker-labs/lab-10-distroless-and-nonroot-security/app` | `8080` | `USER nonroot` ile en az yetki ilkesi, Google Distroless ile kabuksuz sıfır saldırı yüzeyi ve Aqua Trivy ile CVE güvenlik açığı taraması. |
| **11** | [Kaynak Kotaları (cgroups) & OOMKilled](lab-11-cgroups-resource-limits-and-oom/README.md) | `cd ~/docker-labs/lab-11-cgroups-resource-limits-and-oom` | — | Linux cgroups v2 kotaları (`--memory`, `--cpus`), bellek sızıntısı simülasyonu, Linux Kernel OOM-Killer tetiklenmesi ve `Exit Code 137` analizi. |
| **12** | [Felaket Kurtarma: İmaj & Volume Yedekleme](lab-12-backup-restore-disaster-recovery/README.md) | `cd ~/docker-labs/lab-12-backup-restore-disaster-recovery` | — | Air-gapped ortamlar için `docker save`/`load`, Helper Container kalıbı ile Docker Named Volume verilerini `.tar.gz` olarak yedekleme ve geri yükleme. |
| **13** | [Kurumsal OCI Registry: Harbor](lab-13-enterprise-harbor-registry/README.md) | `cd ~/docker-labs/lab-13-enterprise-harbor-registry` | `18444` | Harbor Enterprise OCI Registry kurulumu, yerel port (`127.0.0.1:18444`), Public/Private projeler, CI/CD Robot Account, Tag Immutability ve Trivy. |
| **14** | [NovaShop Capstone & Sorun Giderme](lab-14-capstone-novashop-troubleshooting/README.md) | `cd ~/docker-labs/lab-14-capstone-novashop-troubleshooting` | `19001` | 3 gerçek hayat arıza senaryosu: Veritabanı bağlantı kopması, Gateway 502 Bad Gateway (Port uyuşmazlığı) ve bellek sızıntısı (OOM çökmesi). |
| **15** | [Polyglot Uygulama Paketleme Atölyesi](lab-15-polyglot-application-packaging/README.md) | `cd ~/docker-labs/lab-15-polyglot-application-packaging` | `19001` | Host kirliliği olmadan izole paketleme: Python Flask, Node.js Express, Go Scratch, Java PetClinic, .NET API, PHP ve React SPA. |
| **16** | [Kod Kalitesi & Güvenlik Taraması (SAST)](lab-16-code-quality-sonarqube-cli/README.md) | `cd ~/docker-labs/lab-16-code-quality-sonarqube-cli` | `19000` | Host'a Java kurmadan Docker üzerinden `sonar-scanner-cli` ile kaynak kod taraması, Code Smells tespiti ve SonarQube Quality Gate denetimi. |

---

## 🕹️ Destekleyici Modüller ve Araçlar

Laboratuvar serisini destekleyen pratik araçlar ve başvuru kaynakları:

| Modül | Dizin / Geçiş Komutu | Açık Portlar | Açıklama |
|---|---|:---:|---|
| **DevOps Arcade & Tools** | `cd ~/docker-labs/devops-arcade-and-tools` | `19001 - 19008` | Tetris, IT-Tools, Excalidraw, 2048, FileBrowser, WhoAmI, Speedtest ve draw.io servislerini tek komutla veya tekil ayağa kaldırma. |
| **Docker Cheatsheet** | `cd ~/docker-labs/docker-cheatsheet` | — | 7 kategoride derlenmiş modüler Docker komut başvuru kütüphanesi (Konteynerler, İmajlar, Depolama, Ağ, Compose, Temizlik ve Güvenlik). |

---

## 📚 Hızlı Başvuru Rehberi (Cheatsheet Bağlantıları)

Operasyonel komut referanslarına doğrudan erişebilirsiniz:

* [**01. Konteyner Yönetimi (Containers)**](docker-cheatsheet/01-containers.md) — `run`, `ps`, `exec`, `logs`, `cp`, `diff`, `stats`, `inspect`
* [**02. İmaj Yönetimi (Images)**](docker-cheatsheet/02-images.md) — `build`, `history`, `tag`, `push`, `pull`, `rmi`, `save`, `load`
* [**03. Depolama (Storage)**](docker-cheatsheet/03-storage.md) — Named Volume, Bind Mount, tmpfs, Backup/Restore Helper
* [**04. Ağ Yönetimi (Networking)**](docker-cheatsheet/04-networking.md) — Bridge, host, none, dahili DNS (`127.0.0.11`), connect/disconnect
* [**05. Docker Compose**](docker-cheatsheet/05-compose.md) — `up`, `down`, `ps`, `logs`, `exec`, `scale`, `config`
* [**06. Sistem ve Temizlik (System & Cleanup)**](docker-cheatsheet/06-system-and-cleanup.md) — `system df`, `system prune`, `builder prune`, `events`
* [**07. Güvenlik ve Hata Ayıklama (Security & Troubleshooting)**](docker-cheatsheet/07-security-and-troubleshooting.md) — cgroups limitleri, non-root, Trivy, Exit Codes

Detaylı genel bakış ve en sık kullanılan 20 komut tablosu için [**📖 Docker Cheatsheet Ana Sayfası**](docker-cheatsheet/README.md) belgesini inceleyebilirsiniz.
