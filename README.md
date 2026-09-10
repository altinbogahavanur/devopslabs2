# 🐳 Docker Hands-on Lab Serisi

Bu çalışma serisi; Linux temellerinden başlayarak Docker konteyner motorunu, çok dilli uygulama paketlemeyi, ağ ve depolama yönetimini, çoklu konteyner mimarilerini (Compose), konteyner güvenliğini ve CI/CD süreçlerini uygulamalı olarak deneyimlemek için hazırlanmış uçtan uca pratik rehberidir.

---

## 📚 Laboratuvar Listesi

| No | Modül Klasörü | Seviye | Odak Konusu ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **00** | [`00-linux-essentials`](00-linux-essentials/README.md) | Başlangıç | Temel Linux Komutları, Süreç ve Disk Yönetimi, SSH, 16 GB Swap Yapılandırması | `bash`, `ss`, `top`, `fallocate` |
| **01** | [`01-docker-installation`](01-docker-installation/README.md) | Başlangıç | Resmi Docker Engine, Buildx ve Compose V2 Kurulumu, Non-root Kullanıcı İzni | `docker-ce`, `docker-compose-plugin` |
| **02** | [`02-container-fundamentals`](02-container-fundamentals/README.md) | Başlangıç | Konteyner Yaşam Döngüsü, Port Eşleme, Dosya Kopyalama (`docker cp`), İmaj Üretme (`commit`) | `docker run`, `docker cp`, `stats`, `inspect` |
| **03** | [`03-dockerfile-and-caching`](03-dockerfile-and-caching/README.md) | Temel - Orta | Dockerfile Direktifleri, Katman Önbellekleme (Layer Caching) Optimizasyonu, .dockerignore | BuildKit, `.dockerignore` |
| **04** | [`04-polyglot-app-dockerization`](04-polyglot-app-dockerization/README.md) | Orta - İleri | 7 Farklı Dilin Paketlenmesi: Node.js, Python, Go Scratch (~8MB), Java Spring Boot, .NET 8, PHP, React | Express, FastAPI, Go Scratch, Spring Boot, Vite |
| **05** | [`05-backup-restore-and-registry`](05-backup-restore-and-registry/README.md) | Orta | İmaj ve Volume Yedekleme/Geri Yükleme (`save`/`load`), Yerel OCI Registry | `docker save`, `docker load`, `registry:2` |
| **06** | [`06-docker-networking`](06-docker-networking/README.md) | Orta | Özel Bridge Ağları, Dahili DNS Çözümleme (`nslookup`), Port Publishing, `none` Ağ İzolasyonu | `app-net`, `busybox nslookup` |
| **07** | [`07-docker-storage`](07-docker-storage/README.md) | Orta | Named Volume Kalıcılığı, Host Bind Mount Dizin Paylaşımı, Bellek İçi `tmpfs` RAM Diski | Named Volume, Bind Mount, `tmpfs`, `--mount` |
| **08** | [`08-docker-compose-stacks`](08-docker-compose-stacks/README.md) | İleri | Compose V2 Bildirimsel Tanımlama, Sağlık Kontrolleri (`service_healthy`), 3-Tier Web-API-DB Stack | `docker compose`, Nginx, Redis, PostgreSQL |
| **09** | [`09-security-and-distroless`](09-security-and-distroless/README.md) | Uzman | Google Distroless, Non-root Kullanıcı, Salt-Okunur Dosya Sistemi, Cgroups OOMKilled, Tini | `distroless`, `trivy`, `cgroups v2`, `tini` |
| **10** | [`10-cicd-container-pipelines`](10-cicd-container-pipelines/README.md) | İleri | GitHub Actions, GitLab CI (dind) ve Jenkins ile Otomatik Konteyner Derleme ve Güvenlik Taraması | GitHub Actions, `.gitlab-ci.yml`, `Jenkinsfile` |
| **11** | [`11-final-capstone-project`](11-final-capstone-project/README.md) | Uzman | Bitirme Projesi: Nginx Gateway + Backend API + PostgreSQL + Docker Secrets + Kaynak Sınırları | Uçtan Uca Kurumsal Mikroservis Platformu |

---

## 🛠️ Sunucu ve Ortam Gereksinimleri

* **İşletim Sistemi:** Ubuntu 24.04 veya 22.04 LTS
* **Önerilen Donanım:** 4 vCPU, 16 GB RAM, 50+ GB Disk
* **Swap Alanı:** Modül 00'da oluşturulan 16 GB Swap alanı ile ağır iş yüklerinde sistem kilitlenmesi önlenir.

---

## 🚀 Başlangıç

Uygulamalara ilk modülden başlayarak sırayla ilerleyin:

```bash
cd 00-linux-essentials
cat README.md
```
