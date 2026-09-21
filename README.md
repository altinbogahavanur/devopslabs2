# 🐳 Docker ve Konteyner Teknolojileri Eğitim Laboratuvarı

Bu depo, sıfırdan ileri seviyeye kadar modern DevOps ve konteyner mühendisliği becerilerini uygulamalı olarak kazandırmak üzere tasarlanmış, **kademeli (Tiered)** ve **gerçek hayat kurumsal altyapı standartlarıyla tam uyumlu** 17 modüllük bir laboratuvar serisidir.

---

## 🗺️ Laboratuvar Müfredatı ve Seviye Haritası

```text
docker-labs/
├── lab-01-container-lifecycle-and-cli/       # Yaşam döngüsü (run, pause, stop, kill, rm, prune)
├── lab-02-live-debugging-and-logging/        # Canlı teftiş (exec, cp ile hotfix, logs -f, top, inspect)
├── lab-03-storage-bind-mount-vs-volume/      # Bind Mount vs Named Volume vs tmpfs
├── lab-04-networking-and-dns/                # Custom Bridge, Dahili DNS (127.0.0.11), İzolasyon
├── lab-05-docker-compose-quickstart/         # Docker Compose: WordPress + MariaDB (Port 19001 /app1)
├── lab-06-dockerfile-from-scratch/           # Sıfırdan Dockerfile: FROM, WORKDIR, COPY, ENV, CMD vs ENTRYPOINT
├── lab-07-image-size-reduction-and-multistage/ # 850 MB -> 12 MB Go Multi-Stage, Cache & .dockerignore
├── lab-08-distroless-and-nonroot-security/   # USER nonroot, Google Distroless & Trivy CLI zafiyet taraması
├── lab-09-image-tagging-and-registry/        # Docker Hub (Public/Private) imaj yayını & yerel registry:2 (Port 5000)
├── lab-10-docker-compose-stack/              # 3-Tier Compose: Frontend + Backend + DB + Redis + Çift Ağ + Volume
├── lab-11-polyglot-application-packaging/    # 7 Dil Atölyesi: Go Scratch, Python, Node, React, Java, .NET, PHP
├── lab-12-cgroups-resource-limits-and-oom/   # Linux cgroups v2 kotaları, bellek sızıntısı, Exit 137 OOMKilled
├── lab-13-backup-restore-disaster-recovery/  # Helper Pattern ile Named Volume .tar.gz yedekleme ve geri yükleme
├── lab-14-enterprise-harbor-registry/        # Harbor (Port 18444), Cloudflare Bypass (127.0.0.1), Robot Account, Dahili Trivy
├── lab-15-capstone-novashop-troubleshooting/ # NovaShop Capstone (Port 19001): 3 arıza vakası (DB, 502, OOM)
├── lab-16-cicd-container-pipelines/          # GitHub Actions (Buildx+Cache) & GitLab CI (dind)
├── lab-17-code-quality-sonarqube-cli/        # Docker ile SonarQube (Port 19000): SAST taraması ve Quality Gate
├── devops-arcade-and-tools/                  # Web Tetris, 2048, Excalidraw, IT-Tools, FileBrowser
└── troubleshooting-simulator/                # troubleshoot-menu.sh terminal arıza bulma simülatörü
```

---

### 🟢 1. Bölüm: Başlangıç Seviyesi — Temel Konteyner Refleksleri

| Lab | Dizin | Odak Konusu | Öğrenilen Refleks |
|---|---|---|---|
| **LAB-01** | [`lab-01-container-lifecycle-and-cli/`](lab-01-container-lifecycle-and-cli/README.md) | Konteyner Yaşam Döngüsü & CLI | `run`, `stop`, `start`, `restart`, `pause`/`unpause` (CPU dondurma), `kill`, `rm`, `prune` |
| **LAB-02** | [`lab-02-live-debugging-and-logging/`](lab-02-live-debugging-and-logging/README.md) | Canlı Teftiş, Exec & Log Yönetimi | `exec -it`, `logs -f -t`, `docker cp` ile canlı hotfix, `docker diff`, `top`, `stats`, `inspect` |
| **LAB-03** | [`lab-03-storage-bind-mount-vs-volume/`](lab-03-storage-bind-mount-vs-volume/README.md) | Depolama: Bind Mount vs Named Volume | Ephemeral veri kaybı deneyi, Bind Mount ile canlı kod geliştirme, Named Volume veri kurtarma, `tmpfs` |
| **LAB-04** | [`lab-04-networking-and-dns/`](lab-04-networking-and-dns/README.md) | Konteyner Ağları ve Dahili DNS | Özel `bridge` ağı, gömülü DNS (`127.0.0.11`) ile isimle ping, `connect`/`disconnect`, `host` ve `none` ağları |
| **LAB-05** | [`lab-05-docker-compose-quickstart/`](lab-05-docker-compose-quickstart/README.md) | Docker Compose Hızlı Başlangıç | WordPress + MariaDB stack'i, tek komutla ayağa kaldırma, App1 slotu (`/app1`, Port 19001) |

---

### 🟡 2. Bölüm: Orta Seviye — Paketleme, Optimizasyon & Orkestrasyon

| Lab | Dizin | Odak Konusu | Öğrenilen Refleks |
|---|---|---|---|
| **LAB-06** | [`lab-06-dockerfile-from-scratch/`](lab-06-dockerfile-from-scratch/README.md) | Sıfırdan Dockerfile Hazırlama | **Linux Terminali vs Dockerfile** mantığı, `FROM`, `WORKDIR`, `COPY`, `ENV`, `EXPOSE`, `CMD` vs `ENTRYPOINT` |
| **LAB-07** | [`lab-07-image-size-reduction-and-multistage/`](lab-07-image-size-reduction-and-multistage/README.md) | İmaj Boyutu Küçültme & Multi-Stage | Katman önbellekleme (`CACHED`), `.dockerignore`, Go ile 850 MB'tan 12 MB'a boyut düşürme |
| **LAB-08** | [`lab-08-distroless-and-nonroot-security/`](lab-08-distroless-and-nonroot-security/README.md) | Konteyner Güvenliği & Bağımsız Trivy | `USER 10001`, Google Distroless (sıfır saldırı yüzeyi / kabuksuz), `docker run` ile Trivy CVE taraması |
| **LAB-09** | [`lab-09-image-tagging-and-registry/`](lab-09-image-tagging-and-registry/README.md) | Docker Hub (Public/Private) & Registry | Public imaj push/anonim pull, Private imaj yetkilendirme (`access denied`), yerel `registry:2` (Port 5000) |
| **LAB-10** | [`lab-10-docker-compose-stack/`](lab-10-docker-compose-stack/README.md) | 3-Tier Compose Orkestrasyonu | **Frontend + Backend + Database + Redis + Dual Networks + Named Volume + Healthcheck** zinciri |
| **LAB-11** | [`lab-11-polyglot-application-packaging/`](lab-11-polyglot-application-packaging/README.md) | 7 Farklı Yazılım Dili Paketleme Atölyesi | **Sıfır Host Kirliliği**: Go Scratch (8MB), Python, Node, React SPA, Java Maven, .NET Core, PHP Apache |

---

### 🔴 3. Bölüm: İleri Seviye — Üretim, Performans & Sorun Giderme

| Lab | Dizin | Odak Konusu | Öğrenilen Refleks |
|---|---|---|---|
| **LAB-12** | [`lab-12-cgroups-resource-limits-and-oom/`](lab-12-cgroups-resource-limits-and-oom/README.md) | Kaynak Kısıtları & OOMKilled Teşhisi | cgroups v2, bellek sızıntısı simülasyonu, Linux OOM-Killer tetiklenmesi, `Exit Code 137` adli teftişi |
| **LAB-13** | [`lab-13-backup-restore-disaster-recovery/`](lab-13-backup-restore-disaster-recovery/README.md) | Felaket Kurtarma & Volume Yedekleme | `docker save`/`load` (air-gap), Helper Pattern ile Named Volume `.tar.gz` yedekleme ve sıfırdan geri yükleme |
| **LAB-14** | [`lab-14-enterprise-harbor-registry/`](lab-14-enterprise-harbor-registry/README.md) | Kurumsal Harbor OCI Registry (Port 18444) | **Cloudflare Bypass (127.0.0.1:18444 push/pull)**, Proje & Robot Account, Harbor dahili Trivy taraması |
| **LAB-15** | [`lab-15-capstone-novashop-troubleshooting/`](lab-15-capstone-novashop-troubleshooting/README.md) | NovaShop Capstone & Gerçek Hayat Arızaları | Mikroservis stack'i (Gateway->Backend->DB), 3 kritik arıza senaryosu: DB kopması, 502 Bad Gateway, OOM |
| **LAB-16** | [`lab-16-cicd-container-pipelines/`](lab-16-cicd-container-pipelines/README.md) | Konteyner CI/CD Pipeline Otomasyonu | GitHub Actions (Buildx & gha cache) ve GitLab CI (Docker-in-Docker `dind`) iş akışları |
| **LAB-17** | [`lab-17-code-quality-sonarqube-cli/`](lab-17-code-quality-sonarqube-cli/README.md) | Docker ile SonarQube Kod Analizi (Port 19000) | Host kurulumsuz `sonarsource/sonar-scanner-cli` ile SAST statik kod analizi ve Quality Gate raporu |

---

### 🎮 4. Bölüm: Oyun Alanı ve DevOps Araçları

| Modül | Dizin | Açıklama |
|---|---|---|
| **Troubleshooting Simulator** | [`troubleshooting-simulator/`](troubleshooting-simulator/README.md) | Terminal tabanlı interaktif menü (`troubleshoot-menu.sh`): Port çakışması, PID 1, OOMKilled ve DNS arızalarını canlı bozup onarma oyunu |
| **DevOps Arcade** | [`devops-arcade-and-tools/`](devops-arcade-and-tools/README.md) | Tek komutla ayağa kalkan web araçları: Tetris, 2048, Excalidraw, IT-Tools, FileBrowser |

---

## 🏛️ Platform Port Haritası ve Web Erişim Slotları

Laboratuvarlarımız sunucunuzdaki çekirdek DevOps servisleriyle tam uyumludur ve port çakışması yaşatmaz:

| Servis / Lab | Port | Web Tarayıcı Erişimi | Açıklama |
|---|:---:|---|---|
| **Harbor OCI Registry (Lab 14)** | `18444` | `http://<IP>:18444` veya `http://<IP>/harbor` | Docker push/pull için Cloudflare bypass yerel portu (`127.0.0.1:18444`) |
| **SonarQube (Lab 17)** | `19000` | `http://<IP>:19000/sonar` veya `http://<IP>/sonar` | Statik kod analizi ve Quality Gate paneli |
| **NovaShop Capstone (Lab 15)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (Nginx Gateway -> Backend -> PostgreSQL) |
| **3-Tier Compose Stack (Lab 10)**| `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (Nginx -> FastAPI -> Redis -> PostgreSQL) |
| **WordPress Compose (Lab 05)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (WordPress + MariaDB) |
| **Polyglot Web App (Lab 11)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | React SPA, Go, Node, Python, Java, .NET veya PHP uygulaması |
| **Yerel Docker Registry (Lab 09)**| `5000` | `http://127.0.0.1:5000` | Bağımsız hafif `registry:2` konteyneri |
| **Temel Isınma Labları (Lab 01-08)**| `8080-8086` | `http://localhost:<PORT>` | Öğrencinin bağımsız test konteynerleri |

---

## ⚡ Hızlı Başlangıç

### 1. Docker Motor Durumunu Denetleme
```bash
docker version
docker compose version
```

### 2. İlk Laboratuvara Başlama
```bash
cd lab-01-container-lifecycle-and-cli
cat README.md
```

### 3. Genel Temizlik
```bash
# Çalışan tüm test konteynerlerini durdurup silmek için:
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Kullanılmayan ağları ve diskleri temizlemek için:
docker system prune -f
```
