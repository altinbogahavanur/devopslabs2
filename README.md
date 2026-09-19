# Docker Hands-on Lab Serisi (DevOps Practitioner)

Bu laboratuvar serisi; uluslararası DevOps Practitioner standartlarına uygun olarak Docker Engine mimarisinden başlayarak konteyner yaşam döngüsünü, Dockerfile katman önbellekleme optimizasyonunu, çok dilli (polyglot) mikroservis paketlemeyi, kalıcı depolama yönetimini (Volume & Bind Mounts), kullanıcı tanımlı bridge ağlarını ve dahili DNS çözümlemesini, kurumsal OCI Registry (Harbor) entegrasyonunu, Docker Compose V2 bildirimsel orkestrasyonunu, gerçek hayat sorun giderme senaryolarını ve Port 19001 üzerinde çalışan çok katmanlı **NovaShop Final Capstone** projesini uygulamalı olarak öğretmek üzere yapılandırılmıştır.

---

## Docker Motor Mimarisi ve Çalışma Modeli

Docker, istemci-sunucu (Client-Server) mimarisinde çalışır. Kullanıcının çalıştırdığı her komut doğrudan çekirdeğe değil, arka plandaki servis mimarisine iletilir:

```text
+─────────────────────────────────────────────────────────────────────────────+
| DOCKER CLIENT (CLI)                                                         |
| docker run / docker build / docker compose                                 |
+──────────────────────────────────────┬──────────────────────────────────────+
                                       │ Unix Domain Socket (/var/run/docker.sock)
                                       ▼
+─────────────────────────────────────────────────────────────────────────────+
| DOCKER DAEMON (dockerd)                                                     |
| - API Endpoint, Güvenlik, Ağ Yönetimi, İmaj Yönetimi                        |
+──────────────────────────────────────┬──────────────────────────────────────+
                                       │ gRPC
                                       ▼
+─────────────────────────────────────────────────────────────────────────────+
| CONTAINER RUNTIME (containerd)                                              |
| - OCI İmaj Dağıtımı, Snapshot Yönetimi (overlay2)                           |
+──────────────────────────────────────┬──────────────────────────────────────+
                                       │ OCI Runtime Spec
                                       ▼
+─────────────────────────────────────────────────────────────────────────────+
| LOW-LEVEL RUNTIME (runc)                                                    |
| - Linux Namespaces (PID, NET, IPC, MNT, UTS, USER)                          |
| - Linux Control Groups (cgroups v2: CPU, Memory, I/O Limitleri)             |
| - Linux Capabilities & Seccomp                                              |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## Eğitim Metodolojisi ve Modül Mimarisi

Müfredat, katılımcıların sınıf içi eğitim süresinde (1.5 - 2 gün) bilişsel aşırı yüklenme (cognitive overload) yaşamadan sağlam refleksler kazanmasını sağlayacak şekilde iki temel katmana ayrılmıştır:

1. **Sınıf İçi Temel Eğitim Hattı (8 Sıralı Lab):** Sıfırdan başlayarak Docker Engine, CLI ısınma komutları, Dockerfile, Polyglot paketleme, Depolama, Ağ, Harbor ve Compose orkestrasyonunu doğrudan Capstone projesine bağlayan omurga.
2. **İleri Seviye ve Tamamlayıcı Bonus Laboratuvarlar (6 Modül):** Erken bitiren, Linux altyapısını güçlendirmek isteyen, air-gapped ortamlarda offline yedekleme yapan, Trivy ile zafiyet tarayan, CI/CD pipeline'ı kurgulayan veya interaktif simülatörle arıza çözen katılımcılar için tasarlanmış bağımsız modüller.

---

## 1. Sınıf İçi Temel Eğitim Hattı (Sıralı 8 Lab)

Tüm katılımcıların sınıfta eğitmen eşliğinde sırayla tamamlaması gereken çekirdek laboratuvarlar:

| No | Laboratuvar Dizini | Seviye | Odak Konusu ve Uygulama | Açık Portlar |
|:---:|:---|:---:|:---|:---:|
| **01** | [`lab-01-docker-engine-and-warmup`](lab-01-docker-engine-and-warmup/README.md) | Başlangıç | **Engine Doğrulama ve 8 Aşamalı CLI Isınma:** `run`, `-d`, `-p`, `ps`, `top`, `logs -f`, `exec -it`, `cp`, `diff`, `inspect`, `stats`, `stop`, `rm`, `prune`. | `8080`, `8081` |
| **02** | [`lab-02-dockerfile-and-caching`](lab-02-dockerfile-and-caching/README.md) | Temel - Orta | **Dockerfile Mimarisi ve Önbellek:** BuildKit katman sırası, `COPY package*.json`, `.dockerignore`, Multi-Stage Build ile imaj küçültme. | `3000` |
| **03** | [`lab-03-polyglot-app-dockerization`](lab-03-polyglot-app-dockerization/README.md) | Orta | **Çok Dilli Uygulama Paketleme:** Node.js, Go (Scratch ile 8MB ultra-küçük imaj), Python, Java, .NET, PHP ve React paketleme. | `3000`, `8080`, `5000` |
| **04** | [`lab-04-storage-volumes-bind-mounts`](lab-04-storage-volumes-bind-mounts/README.md) | Orta | **Kalıcı Depolama Yönetimi:** Named Volume ile veritabanı kalıcılığı, geliştirici Bind Mounts (hot-reload), `tmpfs` ve UID/GID izinleri. | `5432`, `8080` |
| **05** | [`lab-05-docker-networking-and-dns`](lab-05-docker-networking-and-dns/README.md) | Orta | **Konteyner Ağları ve DNS:** Custom bridge ağı, Dahili DNS (`127.0.0.11`), host/none ağları ve DMZ çift ağ izolasyonu. | `8080` |
| **06** | [`lab-06-harbor-registry-and-images`](lab-06-harbor-registry-and-images/README.md) | Orta - İleri | **Harbor Registry ve İmaj Yaşam Döngüsü:** Semantik etiketleme, yerel `registry:2` (`5000`), kurumsal Harbor (`18444`), Robot Account, Tag Immutability ve Digest (`@sha256`). | `5000`, `18444` |
| **07** | [`lab-07-docker-compose-orchestration`](lab-07-docker-compose-orchestration/README.md) | Orta - İleri | **Docker Compose V2 Orkestrasyonu:** Bildirimsel stack yönetimi, `.env`, `condition: service_healthy` zinciri, 3-Tier DMZ stack ve Voting App. | `8000`, `8080`, `5000` |
| **08** | [`lab-08-capstone-and-troubleshooting`](lab-08-capstone-and-troubleshooting/README.md) | İleri - Uzman | **Büyük Final Capstone & Sorun Giderme:** Nginx Gateway (**Port 19001**), Hardened REST API, PostgreSQL 16, Redis 7, Secrets, cgroup limitleri + 3 Kritik Arıza Çözümü (Port conflict, PID 1 exit, OOMKilled 137). | `19001` (App1 Slotu) |

---

## 2. İleri Seviye ve Tamamlayıcı Bonus Laboratuvarlar (6 Modül)

Eğitimi erken bitiren, konuları derinleştirmek isteyen veya spesifik kurumsal ihtiyaçları olan katılımcılar için tamamlayıcı modüller:

| No | Modül Dizini | Seviye | Odak Konusu ve Kapsam | Kullanım Amacı |
|:---:|:---|:---:|:---|:---|
| **BONUS-01** | [`bonus-labs/01-linux-essentials-and-swap`](bonus-labs/01-linux-essentials-and-swap/README.md) | Başlangıç | Paket yönetimi, port denetimi (`ss`), kullanıcı/sudo, `htop` ve OOM önleyici 16 GB Swap yapılandırması. | Linux hazırlığı ve donanım optimizasyonu |
| **BONUS-02** | [`bonus-labs/02-backup-restore-disaster-recovery`](bonus-labs/02-backup-restore-disaster-recovery/README.md) | Orta | İmaj ve Named Volume yedekleme (`docker save/load`, `docker export/import`, helper pattern ile `.tar.gz`). | Air-gapped / internetsiz ortamlara aktarım |
| **BONUS-03** | [`bonus-labs/03-security-distroless-trivy`](bonus-labs/03-security-distroless-trivy/README.md) | İleri | Google Distroless taban imajları, non-root zorunluluğu, Aqua Trivy CVE analizi ve Linux Capabilities drop (`--cap-drop=ALL`). | Kurumsal güvenlik ve DevSecOps |
| **BONUS-04** | [`bonus-labs/04-cicd-container-pipelines`](bonus-labs/04-cicd-container-pipelines/README.md) | İleri | GitHub Actions, GitLab CI ve Jenkins üzerinde otomatik Docker derleme, Trivy taraması ve Registry push pipeline'ları. | CI/CD otomasyonu entegrasyonu |
| **BONUS-05** | [`bonus-labs/05-interactive-troubleshooting-simulator`](bonus-labs/05-interactive-troubleshooting-simulator/README.md) | Orta - İleri | 5 senaryolu interaktif bash simülatörü (`troubleshoot-menu.sh`): Break, Diagnose, Remediate, Verify döngüsü. | Arıza teşhis ve pratik refleks geliştirme |
| **BONUS-06** | [`bonus-labs/06-advanced-cgroups-oom-profiling`](bonus-labs/06-advanced-cgroups-oom-profiling/README.md) | İleri | Cgroups v2 çekirdek limitleri, bellek taşması simülasyonu, Exit Code 137 OOMKilled ve Tini init yöneticisi. | Çekirdek seviyesinde kaynak profilleme |

---

## Platform Port ve Servis Haritası

Eğitim ortamında tüm laboratuvarların port çakışması yaşamadan çalışabilmesi için belirlenen standart port eşleştirmeleri:

| Servis / Uygulama | Port | Protokol | Açıklama |
|---|---|---|---|
| **Nginx Master Reverse Proxy** | `80`, `443` | HTTP / HTTPS | Sunucu ana giriş kapısı ve SSL sonlandırma |
| **Cockpit Web Terminal** | `9090` | HTTPS | Tarayıcı tabanlı Linux terminali |
| **NovaShop Final Capstone (Lab 08)** | `19001` | HTTP | **App1 Slotu** (Gateway -> Backend -> DB) |
| **Harbor OCI Registry (Lab 06)** | `18444` | HTTP | Kurumsal Harbor OCI Registry arayüzü ve API |
| **Yerel Docker Registry (Lab 06)** | `5000` | HTTP | Hafif `registry:2` konteyneri |
| **Jenkins CI/CD** | `18080` | HTTP | Jenkins otomasyon sunucusu |
| **SonarQube** | `19000` | HTTP | Kod kalite ve statik güvenlik kapısı |
| **GitLab CE** | `18929` | HTTP | Kurumsal GitLab sunucusu |
| **KinD K8s API** | `6443` | HTTPS | Yerel Kubernetes Control Plane API |

---

## Hızlı Başlangıç

1. Docker motor durumunu ve Compose V2 sürümünü kontrol edin:
   ```bash
   docker version
   docker compose version
   ```

2. Sınıf içi çekirdek hattın ilk laboratuvarına geçerek başlayın:
   ```bash
   cd lab-01-docker-engine-and-warmup
   cat README.md
   ```

3. Her laboratuvar tamamlandığında ilgili dizinde temizlik komutunu çalıştırın:
   ```bash
   # Compose kullanılan laboratuvarlar için:
   docker compose down -v
   
   # Bağımsız konteynerler için:
   docker rm -f <konteyner-adi>
   ```
