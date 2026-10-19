# 🐳 Docker ve Konteyner Teknolojileri Labları

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

## 🗺️ Lab Kataloğu

| No | Lab | Port |
|:---:|---|:---:|
| **00** | [Linux Sistem Yönetimi & Teftiş](lab-00-linux/README.md) | — |
| **01** | [Konteyner Yaşam Döngüsü & CLI](lab-01-container-lifecycle-and-cli/README.md) | `8080` |
| **02** | [Canlı Hata Ayıklama & Log Yönetimi](lab-02-live-debugging-and-logging/README.md) | `8081` |
| **03** | [Sıfırdan Dockerfile & İmaj Derleme](lab-03-dockerfile-from-scratch/README.md) | `3000, 3001` |
| **04** | [Katman Önbellekleme & Multi-Stage](lab-04-layer-caching-and-multistage/README.md) | `8080` |
| **05** | [Konteyner Ağları & Dahili DNS](lab-05-networking-and-dns/README.md) | — |
| **06** | [Depolama: Bind Mount vs Volume](lab-06-storage-bind-mount-vs-volume/README.md) | `8082` |
| **07** | [Docker Compose Hızlı Başlangıç](lab-07-docker-compose-quickstart/README.md) | `19001` |
| **08** | [Docker Compose 3-Tier Mimari](lab-08-docker-compose-stack/README.md) | `19001` |
| **09** | [İmaj Etiketleme & Registry](lab-09-image-tagging-and-registry/README.md) | `8085, 8086` |
| **10** | [Konteyner Güvenliği: Non-Root & Distroless](lab-10-distroless-and-nonroot-security/README.md) | `8080` |
| **11** | [Kaynak Kotaları (cgroups) & OOMKilled](lab-11-cgroups-resource-limits-and-oom/README.md) | — |
| **12** | [Felaket Kurtarma: İmaj & Volume Yedekleme](lab-12-backup-restore-disaster-recovery/README.md) | — |
| **13** | [Kurumsal OCI Registry: Harbor](lab-13-enterprise-harbor-registry/README.md) | `18444` |
| **14** | [NovaShop Capstone & Sorun Giderme](lab-14-capstone-novashop-troubleshooting/README.md) | `19001` |
| **15** | [Polyglot Uygulama Paketleme Atölyesi](lab-15-polyglot-application-packaging/README.md) | `19001` |
| **16** | [Kod Kalitesi & Güvenlik Taraması (SAST)](lab-16-code-quality-sonarqube-cli/README.md) | `19000` |

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
