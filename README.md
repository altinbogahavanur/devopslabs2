# Docker ve Konteyner Teknolojileri Eğitim Laboratuvarı

---

## Docker Teorisi ve Mimarisi

Docker, uygulamaları bağımlılıklarıyla birlikte işletim sistemi seviyesinde izole eden (containerization) açık kaynaklı bir konteyner platformudur.

### Temel Mimari Kavramlar:

1. **Client / Server (Daemon) Mimarisi:**
   - **Docker Client (CLI):** Komutları (`docker run`, `docker build`) Unix Domain Socket (`/var/run/docker.sock`) üzerinden Docker Daemon'a (`dockerd`) iletir.
   - **containerd & runc:** `dockerd` iş yükünü OCI uyumlu `containerd` çalışma zamanına aktarır; `runc` ise Linux Namespaces ve Cgroups yapılarını kurarak konteyneri başlatır.

2. **İmaj Katmanları ve UnionFS (overlay2):**
   - Docker imajları salt-okunur (read-only) katmanlardan oluşur.
   - Konteyner başlatıldığında en üste ince bir yazılabilir katman (Container Read-Write Layer) eklenir; dosya değişiklikleri Copy-on-Write (CoW) stratejisiyle yönetilir.

3. **İzolasyon Mekanizmaları:**
   - **Namespaces:** Konteynerler için süreç (PID), ağ (NET), dosya sistemi (MNT) ve kullanıcı (USER) soyutlaması sağlar.
   - **Control Groups (cgroups v2):** Konteynerin tüketebileceği CPU, bellek (RAM) ve I/O kotalarını belirler. Sınır aşıldığında Linux kernel tarafından `Exit Code 137 (OOMKilled)` tetiklenir.

---

## 🧪 Pratik Isınma ve Canlı Teftiş Laboratuvarları (pratik-lablar)

Konteyner dünyasında cerrahi müdahale ve sorun giderme refleksleri kazandıran pratik laboratuvarlar:

| Modül | Dizin | Konu ve Kapsam | Seviye | Temel Odak |
|---|---|---|---|---|
| [**PRATİK-DOC-01**](pratik-lablar/01-exec-ve-dosya-transferi/README.md) | [`pratik-lablar/01-exec-ve-dosya-transferi`](pratik-lablar/01-exec-ve-dosya-transferi/README.md) | `exec` ve `cp` İle Canlı Konteyner Teftişi ve Dosya Transferi | Başlangıç | `exec`, `cp-in`, `cp-out`, `hotfix` |
| [**PRATİK-DOC-02**](pratik-lablar/02-log-ve-canli-teftis/README.md) | [`pratik-lablar/02-log-ve-canli-teftis`](pratik-lablar/02-log-ve-canli-teftis/README.md) | Log İnceleme (`-f`, `--tail`), Proses Dedektifliği (`top`) ve `inspect` | Temel | `logs`, `top`, `stats`, `inspect` |
| [**PRATİK-DOC-03**](pratik-lablar/03-volume-ve-network-kontrol/README.md) | [`pratik-lablar/03-volume-ve-network-kontrol`](pratik-lablar/03-volume-ve-network-kontrol/README.md) | Volume ve Network İnceleme, Ağ İzolasyonu ve Dahili DNS İletişimi | Temel - Orta | `volumes`, `networks`, `dns-ping` |

👉 **[Tüm Docker Pratik Lablar İndeksi](./pratik-lablar/README.md)**

---

## Çekirdek Laboratuvarlar (lab-01 - lab-08)

| Modül | Dizin | Konu ve Kapsam | Seviye | Temel Araçlar |
|---|---|---|---|---|
| [**LAB-DOC-01**](lab-01-docker-engine-and-warmup/README.md) | [`lab-01-docker-engine-and-warmup`](lab-01-docker-engine-and-warmup/README.md) | Docker Engine Mimarisi, Doğrulama ve 8 Aşamalı CLI Isınma Akışı | Başlangıç | `docker`, `cli-warmup`, `inspect`, `logs` |
| [**LAB-DOC-02**](lab-02-dockerfile-and-caching/README.md) | [`lab-02-dockerfile-and-caching`](lab-02-dockerfile-and-caching/README.md) | Dockerfile Mimarisi, BuildKit Katman Önbellekleme ve Multi-Stage Build | Temel - Orta | `dockerfile`, `buildkit`, `multi-stage` |
| [**LAB-DOC-03**](lab-03-polyglot-app-dockerization/README.md) | [`lab-03-polyglot-app-dockerization`](lab-03-polyglot-app-dockerization/README.md) | Çok Dilli Paketleme: Node.js, Go (Scratch 8MB), Python, Java, .NET, PHP, React | Orta | `polyglot`, `scratch`, `nodejs`, `golang` |
| [**LAB-DOC-04**](lab-04-storage-volumes-bind-mounts/README.md) | [`lab-04-storage-volumes-bind-mounts`](lab-04-storage-volumes-bind-mounts/README.md) | Kalıcı Depolama: Named Volume, Bind Mounts, `tmpfs` ve İzin Yönetimi | Orta | `volumes`, `bind-mount`, `postgres`, `tmpfs` |
| [**LAB-DOC-05**](lab-05-docker-networking-and-dns/README.md) | [`lab-05-docker-networking-and-dns`](lab-05-docker-networking-and-dns/README.md) | Konteyner Ağları: Özel Bridge, Dahili DNS (127.0.0.11) ve DMZ Çift Ağ İzolasyonu | Orta | `network`, `dns`, `bridge`, `dmz-isolation` |
| [**LAB-DOC-06**](lab-06-harbor-registry-and-images/README.md) | [`lab-06-harbor-registry-and-images`](lab-06-harbor-registry-and-images/README.md) | İmaj Yaşam Döngüsü, Yerel Registry:2 ve Kurumsal Harbor OCI Registry (18444) | Orta - İleri | `harbor`, `registry:2`, `tag-immutability` |
| [**LAB-DOC-07**](lab-07-docker-compose-orchestration/README.md) | [`lab-07-docker-compose-orchestration`](lab-07-docker-compose-orchestration/README.md) | Docker Compose V2 Orkestrasyonu: .env, Healthcheck Zinciri ve 3-Tier Stack | Orta - İleri | `compose-v2`, `service_healthy`, `voting-app` |
| [**LAB-DOC-08**](lab-08-capstone-and-troubleshooting/README.md) | [`lab-08-capstone-and-troubleshooting`](lab-08-capstone-and-troubleshooting/README.md) | NovaShop Capstone (Port 19001) ve 3 Kritik Gerçek Hayat Sorun Giderme Senaryosu | İleri / Bitirme | `novashop`, `gateway`, `oomkilled`, `ss` |
| [**Eğlence & Araç Merkezi**](eglence-merkezi/README.md) | [`eglence-merkezi`](eglence-merkezi/README.md) | Docker Arcade & DevOps Toolbox (Tetris, IT-Tools, Excalidraw, 2048, FileBrowser) | Başlangıç / Pratik | `compose`, `cli-tools`, `excalidraw`, `tetris` |

---

## Bonus Laboratuvarlar (bonus-labs)

| Modül | Dizin | Konu ve Kapsam | Seviye | Temel Odak |
|---|---|---|---|---|
| [**BONUS-DOC-01**](bonus-labs/01-linux-essentials-and-swap/README.md) | [`bonus-labs/01-linux-essentials-and-swap`](bonus-labs/01-linux-essentials-and-swap/README.md) | Temel Linux Becerileri, Port Denetimi (`ss`) ve 16 GB Swap Yapılandırması | Başlangıç | `linux`, `apt`, `systemd`, `swap-16gb` |
| [**BONUS-DOC-02**](bonus-labs/02-backup-restore-disaster-recovery/README.md) | [`bonus-labs/02-backup-restore-disaster-recovery`](bonus-labs/02-backup-restore-disaster-recovery/README.md) | İmaj ve Volume Yedekleme (`save`/`load`, `export`/`import`, `.tar.gz`) | Orta | `air-gapped`, `save-load`, `tar-helper` |
| [**BONUS-DOC-03**](bonus-labs/03-security-distroless-trivy/README.md) | [`bonus-labs/03-security-distroless-trivy`](bonus-labs/03-security-distroless-trivy/README.md) | Konteyner Güvenliği: Google Distroless, Aqua Trivy CVE Taraması ve Cap Drop | İleri | `distroless`, `trivy`, `cap-drop` |
| [**BONUS-DOC-04**](bonus-labs/04-cicd-container-pipelines/README.md) | [`bonus-labs/04-cicd-container-pipelines`](bonus-labs/04-cicd-container-pipelines/README.md) | CI/CD Konteyner Otomasyonu: GitHub Actions, GitLab CI ve Jenkins Entegrasyonu | İleri | `github-actions`, `gitlab-ci`, `pipelines` |
| [**BONUS-DOC-05**](bonus-labs/05-interactive-troubleshooting-simulator/README.md) | [`bonus-labs/05-interactive-troubleshooting-simulator`](bonus-labs/05-interactive-troubleshooting-simulator/README.md) | 5 Senaryolu İnteraktif Bash Sorun Giderme Simülatörü (`troubleshoot-menu.sh`) | Orta / İleri | `break-fix`, `troubleshoot`, `simulator` |
| [**BONUS-DOC-06**](bonus-labs/06-advanced-cgroups-oom-profiling/README.md) | [`bonus-labs/06-advanced-cgroups-oom-profiling`](bonus-labs/06-advanced-cgroups-oom-profiling/README.md) | Kaynak Sınırları, Cgroups v2, Bellek Taşması Profilleme ve Tini Init | İleri | `cgroups-v2`, `stress`, `oomkilled-137` |

---

## Platform Port Haritası

| Servis Adı | Port | Erişim Yolu / URL | Açıklama |
|---|---|---|---|
| **Nginx Master Reverse Proxy** | `80`, `443` | `http://<IP>`, `https://<IP>` | Sunucu ana giriş noktası ve SSL sonlandırma |
| **Cockpit Web Terminal** | `9090` | `https://<IP>:9090` | Tarayıcı tabanlı Linux terminali |
| **NovaShop Capstone (Lab 08)** | `19001` | `http://<IP>:19001` | App1 Slotu (Gateway -> Backend -> DB) |
| **Harbor OCI Registry (Lab 06)**| `18444` | `http://<IP>:18444/harbor` | Kurumsal Harbor OCI Registry arayüzü ve API |
| **Yerel Docker Registry (Lab 06)**| `5000` | `http://127.0.0.1:5000` | Hafif `registry:2` konteyneri |
| **Jenkins CI/CD** | `18080` | `http://<IP>:18080/jenkins` | Jenkins otomasyon sunucusu |
| **SonarQube** | `19000` | `http://<IP>:19000/sonar` | Statik kod analizi ve Quality Gate |
| **GitLab CE** | `18929` | `http://<IP>:18929/gitlab` | Kaynak kod repository'si |
| **KinD K8s API** | `6443` | `https://172.18.0.1:6443` | Yerel Kubernetes Control Plane API |

---

## Hızlı Başlangıç

### 1. Docker Motor Durumunu Denetleme
```bash
docker version
docker compose version
```

### 2. Çekirdek Laboratuvarlara Başlama
```bash
cd lab-01-docker-engine-and-warmup
cat README.md
```

### 3. Temizlik
```bash
# Compose kullanılan laboratuvarlar için:
docker compose down -v

# Bağımsız konteynerler için:
docker rm -f <konteyner-adi>
```
