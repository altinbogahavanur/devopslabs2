# 🐳 Docker ve Konteyner Teknolojileri Eğitim Laboratuvarı

Bu depo, sıfırdan kurumsal seviyeye kadar modern DevOps ve konteyner mühendisliği becerilerini uygulamalı olarak kazandırmak üzere tasarlanmış, **`1-Docker_Foundations.pptx` eğitim sunumuyla birebir eşzamanlı (modüler)** ve **gerçek hayat platform standartlarıyla tam uyumlu** 17 modüllük bir laboratuvar serisidir.

---

## 🧭 Sunum Slaytları ve Sınıf İçi Lab Eşleştirme Haritası

Eğitmen sunumda her teorik bölümü tamamladığında, ilgili **LAB** slaytında sınıfla birlikte aşağıdaki laboratuvarı uygular. Sınıf içi zorunlu omurga labları **`*` (yıldız)** ile işaretlenmiştir:

| Sunum Slaytı | Sunum Bölümü / Başlığı | Uygulanacak Sınıf İçi Laboratuvar | Temel Pratik Çıktısı |
|:---:|---|---|---|
| **Slayt 14** | `LAB — İlk Container` | [**\* LAB-01**](lab-01-container-lifecycle-and-cli/README.md) | Nginx run, port eşleme (`8080:80`), stop, start, pause, curl testi |
| **Slayt 32** | `LAB — LifeCycle & TroubleShooting` | [**\* LAB-02**](lab-02-live-debugging-and-logging/README.md) | `exec` ile kabuk açma, `logs`, `docker cp` ile canlı hotfix, `diff`, `inspect` |
| **Slayt 50** | `LAB — Image Build` (Dockerfile Temelleri) | [**\* LAB-03**](lab-03-dockerfile-from-scratch/README.md) | Linux Terminali vs Dockerfile, `FROM`, `WORKDIR`, `COPY`, `CMD` vs `ENTRYPOINT` |
| **Slayt 50** | `LAB — Image Optimization` (BuildKit & Cache) | [**\* LAB-04**](lab-04-layer-caching-and-multistage/README.md) | Katman önbellekleme (`CACHED` 0.0s), `.dockerignore`, Go Multi-Stage (850MB -> 12MB) |
| **Slayt 58** | `LAB — Docker Networking` | [**\* LAB-05**](lab-05-networking-and-dns/README.md) | Özel bridge ağı, gömülü DNS (`127.0.0.11`) ile isimle ping & curl, ağ izolasyonu |
| **Slayt 67** | `LAB — Docker Storage` | [**\* LAB-06**](lab-06-storage-bind-mount-vs-volume/README.md) | Ephemeral veri kaybı deneyi, Bind Mount canlı hot-reload, Named Volume veri kurtarma |
| **Slayt 76** | `LAB — Docker Compose` (Hızlı Başlangıç) | [**\* LAB-07**](lab-07-docker-compose-quickstart/README.md) | WordPress + MariaDB stack'i, tek komutla ayağa kaldırma (`19001` / `/app1`) |
| **Slayt 76** | `LAB — Docker Compose` (3-Tier & Healthcheck) | [**\* LAB-08**](lab-08-docker-compose-stack/README.md) | Nginx + API + Postgres + Redis, çift izole ağ, `condition: service_healthy` |
| **Slayt 79-84** | `Production Registries Overview` | [**\* LAB-09**](lab-09-image-tagging-and-registry/README.md) | Docker Hub Public (şifresiz pull) vs Private (`access denied`), yerel `registry:2` |
| **Slayt 79** | `Runtime Hardening — Privileges` | [**\* LAB-10**](lab-10-distroless-and-nonroot-security/README.md) | `USER 10001`, Distroless (kabuksuz çalışma) & Trivy bağımsız CVE zafiyet taraması |
| **Slayt 79** | `Runtime Resource Limits (cgroups)` | [**\* LAB-11**](lab-11-cgroups-resource-limits-and-oom/README.md) | CPU/Bellek limitleri, kasıtlı bellek sızıntısı ile `Exit Code 137 (OOMKilled)` analizi |
| **Slayt 66** | `Volume Backup / Restore Akışı` | [**\* LAB-12**](lab-12-backup-restore-disaster-recovery/README.md) | `docker save`/`load`, Helper Container ile Named Volume `.tar.gz` yedekleme ve geri yükleme |
| **Kurumsal** | `Harbor OCI Registry & DevSecOps` | [**\* LAB-13**](lab-13-enterprise-harbor-registry/README.md) | Harbor (Port 18444), Cloudflare bypass (`127.0.0.1`), Robot Account, Tag Immutability |
| **Slayt 84** | `Production Troubleshooting (Capstone)` | [**\* LAB-14**](lab-14-capstone-novashop-troubleshooting/README.md) | NovaShop Capstone: 3 arıza vakası teşhisi (DB kopması, 502 Bad Gateway, OOM çökmesi) |
| **Atölye** | `7 Yazılım Dili Paketleme` | [**LAB-15**](lab-15-polyglot-application-packaging/README.md) | Go Scratch, Python, Node, React, Java PetClinic, .NET, PHP paketleme |
| **Atölye** | `CI/CD Pipeline Otomasyonu` | [**LAB-16**](lab-16-cicd-container-pipelines/README.md) | GitHub Actions (Buildx & Cache) ve GitLab CI (Docker-in-Docker `dind`) |
| **Atölye** | `SAST Statik Kod Kalitesi` | [**LAB-17**](lab-17-code-quality-sonarqube-cli/README.md) | Sunucuya Java/Node kurmadan Docker ile SonarQube CLI (Port 19000) taraması |

---

## 🗺️ Dizin Yapısı

```text
docker-labs/
├── * lab-01-container-lifecycle-and-cli/       # [Slayt 14] Yaşam döngüsü (run, pause, stop, kill, rm)
├── * lab-02-live-debugging-and-logging/        # [Slayt 32] Canlı teftiş (exec, cp hotfix, logs, inspect)
├── * lab-03-dockerfile-from-scratch/           # [Slayt 50] Sıfırdan Dockerfile: FROM, WORKDIR, COPY, CMD vs ENTRYPOINT
├── * lab-04-layer-caching-and-multistage/      # [Slayt 50] Katman önbellekleme (CACHED), .dockerignore, Go Multi-Stage
├── * lab-05-networking-and-dns/                # [Slayt 58] Özel bridge ağı, dahili DNS (127.0.0.11), izolasyon
├── * lab-06-storage-bind-mount-vs-volume/      # [Slayt 67] Bind Mount (hot-reload) vs Named Volume (kalıcılık) vs tmpfs
├── * lab-07-docker-compose-quickstart/         # [Slayt 76] Docker Compose: WordPress + MariaDB (Port 19001 /app1)
├── * lab-08-docker-compose-stack/              # [Slayt 76] 3-Tier Compose: Nginx + API + Postgres + Redis + Healthcheck
├── * lab-09-image-tagging-and-registry/        # [Slayt 79] Docker Hub (Public/Private) yayını & yerel registry:2
├── * lab-10-distroless-and-nonroot-security/   # [Slayt 79] USER nonroot, Google Distroless & Trivy CVE taraması
├── * lab-11-cgroups-resource-limits-and-oom/   # [Slayt 79] Linux cgroups v2 kotaları, Exit Code 137 OOMKilled
├── * lab-12-backup-restore-disaster-recovery/  # [Slayt 66] Helper Pattern ile Named Volume .tar.gz yedekleme
├── * lab-13-enterprise-harbor-registry/        # [Kurumsal] Harbor (Port 18444), Robot Account, Tag Immutability & Trivy
├── * lab-14-capstone-novashop-troubleshooting/ # [Slayt 84] NovaShop Capstone: 3 kritik arıza vakası dedektifliği
├── lab-15-polyglot-application-packaging/      # [Atölye]   7 Dil Atölyesi: Go, Python, Node, React, Java, .NET, PHP
├── lab-16-cicd-container-pipelines/          # [Atölye]   GitHub Actions & GitLab CI pipeline iş akışları
├── lab-17-code-quality-sonarqube-cli/        # [Atölye]   Docker ile SonarQube SAST kod kalitesi analizi
├── devops-arcade-and-tools/                  # [Playground] Web Tetris, 2048, Excalidraw, IT-Tools, FileBrowser
└── troubleshooting-simulator/                # [Simülatör]  troubleshoot-menu.sh terminal arıza bulma oyunu
```

---

## 🏛️ Platform Port Haritası ve Web Erişim Slotları

Laboratuvarlarımız sunucunuzdaki çekirdek DevOps servisleriyle tam uyumludur ve port çakışması yaşatmaz:

| Servis / Lab | Port | Web Tarayıcı Erişimi | Açıklama |
|---|:---:|---|---|
| **Harbor OCI Registry (\* Lab 13)** | `18444` | `http://<IP>:18444` veya `http://<IP>/harbor` | Docker push/pull için Cloudflare bypass yerel portu (`127.0.0.1:18444`) |
| **SonarQube (Lab 17)** | `19000` | `http://<IP>:19000/sonar` veya `http://<IP>/sonar` | Statik kod analizi ve Quality Gate paneli |
| **NovaShop Capstone (\* Lab 14)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (Nginx Gateway -> Backend -> PostgreSQL) |
| **3-Tier Compose Stack (\* Lab 08)**| `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (Nginx -> FastAPI -> Redis -> PostgreSQL) |
| **WordPress Compose (\* Lab 07)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | App1 Slotu (WordPress + MariaDB) |
| **Polyglot Web App (Lab 15)** | `19001` | `http://<IP>/app1` veya `https://student.app1.<domain>` | React SPA, Go, Node, Python, Java, .NET veya PHP uygulaması |
| **Yerel Docker Registry (\* Lab 09)**| `5000` | `http://127.0.0.1:5000` | Bağımsız hafif `registry:2` konteyneri |
| **Temel Isınma Labları (\* Lab 01-06)**| `8080-8086` | `http://localhost:<PORT>` | Öğrencinin bağımsız test konteynerleri |

---

## ⚡ Eğitmen ve Öğrenci İçin Hızlı Başlangıç

1. **Docker Servis Kontrolü:**
   ```bash
   docker version
   docker info | grep -E "Server Version|Storage Driver"
   ```

2. **Ders Akışında İlerleme:**
   * Sunumda bir bölüm anlatıldığında karşısındaki `* LAB-XX` dizinine geçin (`cd lab-01-container-lifecycle-and-cli`).
   * Adım adım `# 1. Adım: ...`, `# 2. Adım: ...` yönergelerini takip edin.
   * Gün sonunda öğrendiğiniz tüm refleksleri `* lab-14-capstone-novashop-troubleshooting` üzerinde test edin!
