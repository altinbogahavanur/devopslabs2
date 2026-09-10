# 🐳 Docker Hands-on Lab Serisi: Sıfırdan Üretim Seviyesine Konteyner Mimarisi (Öğrenci Sürümü)

Bu müfredat; modern bulut-yerel mimarilerde ve kurumsal DevOps süreçlerinde konteyner teknolojilerini en temel Linux seviyesinden başlayarak üretim standartlarına kadar derinlemesine kavramak amacıyla hazırlanmış, **Docker Foundations Sunumu ile %100 senkronize ve aşamalı** bir eğitim serisidir.

Her bir laboratuvar modülü; eksiksiz çalışan kaynak kodlar, üretim seviyesi konfigürasyon dosyaları, doğrulama betikleri ve detaylı `README.md` kılavuzları içerir. Kodlarda hiçbir yer tutucu (`placeholder`) bulunmaz.

---

## 🎓 Pedagojik Metodoloji

Her bir uygulama ve teknoloji modülünde standart bir öğrenme akışı uygulanır:
1. **Senaryo ve Problem:** Gerçek dünya ihtiyacı ve mimari gerekçeler.
2. **Klasik Linux (Ubuntu) Manuel Kurulumu:** Öğrencinin zihninde Docker komutlarını otomatikleştirebilmesi için aynı uygulamanın terminalde çıplak Linux üzerine nasıl kurulup çalıştırıldığı gösterilir.
3. **Zihinsel Eşleştirme Tablosu:** Her bir Linux komutunun (`apt install`, `cd`, `pip/npm install`, `export`, `run`) Dockerfile'daki tam karşılığı ve best practice gerekçesi eşleştirilir.
4. **Görevler ve İpuçları:** Öğrenciye adım adım hedefler ve yol gösterici ipuçları verilir.
5. **Challenge Odaklı Öğrenme:** Her laboratuvarda görevler ve ipuçları verilir; öğrenciler komutları ve yapılandırmaları bizzat kendileri uygulayarak kalıcı pratik kazanır.
6. **Doğal Doğrulama ve Otomasyon:** `curl`, `docker ps`, `docker logs` ve otomatik doğrulama betikleri ile başarı somut olarak kanıtlanır.

---

## 📚 Müfredat İçerik Haritası (Sunum ile Birebir Eşleşme)

| No | Modül Klasörü | Sunum Eşleşmesi | Seviye | Odak Konusu ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---:|:---|:---|
| **00** | [`00-linux-essentials`](00-linux-essentials/README.md) | Ön Koşul | Başlangıç | Temel Linux, Süreç Yönetimi, SSH, **16 GB Swap & 100 GB Disk Preflight** | `bash`, `ss`, `top`, `fallocate` |
| **01** | [`01-docker-installation`](01-docker-installation/README.md) | Bölüm 01 | Başlangıç | Resmi Docker Dokümanına Göre Ubuntu Kurulumu, Non-root `docker` Grubu | `docker-ce`, `docker-compose-plugin` |
| **02** | [`02-container-fundamentals`](02-container-fundamentals/README.md) | **Lab 1 & 2** | Başlangıç | Konteyner Yaşam Döngüsü, Port Eşleme, **docker cp**, **docker commit**, Exit Code 1 Teşhisi | `docker run`, `docker cp`, `stats`, `inspect` |
| **03** | [`03-dockerfile-and-caching`](03-dockerfile-and-caching/README.md) | **Lab 3** | Temel - Orta | Build Cache Optimizasyonu, `Dockerfile.baseline`, `Dockerfile.optimized`, Multi-Arch Buildx | BuildKit, `.dockerignore`, `benchmark.sh` |
| **04** | [`04-polyglot-app-dockerization`](04-polyglot-app-dockerization/README.md) | **Lab 3B** | Orta - İleri | **7 Dilin Paketlenmesi:** Node.js, Python, Go Scratch (~8MB), Java Spring Boot PetClinic, .NET 8, PHP 8.3, React SPA | Express, FastAPI, Go Scratch, Spring Boot, Vite |
| **05** | [`05-backup-restore-and-registry`](05-backup-restore-and-registry/README.md) | **Lab 3C** | Orta | **save/load vs export/import**, Helper Container ile Volume Felaket Kurtarma, OCI Registry + **Harbor** | `tar.gz`, `postgres:17`, `registry:2.8`, Harbor |
| **06** | [`06-docker-networking`](06-docker-networking/README.md) | **Lab 4** | Orta | Custom Bridge Ağları, **Dahili DNS (nslookup db)**, Port Publishing, `none` Ağ İzolasyonu | `app-net`, `busybox nslookup`, `none` network |
| **07** | [`07-docker-storage`](07-docker-storage/README.md) | **Lab 5** | Orta | **Named Volume (pgdata)**, Host Bind Mount (`$PWD:/work`), Bellek İçi `tmpfs` RAM Diski | Named Volume, Bind Mount, `tmpfs`, `--mount` |
| **08** | [`08-docker-compose-stacks`](08-docker-compose-stacks/README.md) | **Lab 6** | İleri | Compose V2, Healthcheck Zinciri, **WordPress Stack**, **3-Tier Stack**, **Voting App (5 Servis)** | `docker compose`, Nginx, Redis, PostgreSQL |
| **09** | [`09-security-and-distroless`](09-security-and-distroless/README.md) | **Lab 7 & 7B** | Uzman | **Google Distroless**, Hardening (Non-root, Read-only), **Trivy/Scout**, **OOMKilled 137**, **Tini Graceful** | `distroless`, `trivy`, `cgroups v2`, `tini` |
| **10** | [`10-cicd-container-pipelines`](10-cicd-container-pipelines/README.md) | **Lab 8** | İleri | **GitHub Actions**, **GitLab CI (dind)** ve **Jenkins** ile Lint (Hadolint), Scan (Trivy), Push | GitHub Actions, `.gitlab-ci.yml`, `Jenkinsfile` |
| **11** | [`11-final-capstone-project`](11-final-capstone-project/README.md) | **Final Project** | Uzman | **Bitirme Projesi:** Nginx Reverse Proxy + App API + PostgreSQL + Custom Bridge + Secrets + Healthcheck | Uçtan Uca Kurumsal Mikroservis Mimarisi |

---

## 🛠️ Sunucu ve Donanım Hedefi

* **Hedef Donanım:** 1 Sunucu (Ubuntu 24.04 / 22.04 LTS)
* **İşlemci & Bellek:** 4 vCPU, 16 GB Fiziksel RAM
* **Depolama:** 100 GB SSD Disk
* **Swap Güvencesi:** Modül 00'da oluşturulan **16 GB Swap** ile toplam sanal bellek alanı **32 GB** seviyesine esnetilmiş olup, ağır iş yüklerinde kilitlenme riski sıfırlanmıştır.
* **Hafifletilmiş İmajlar:** Alpine, Slim ve Google Distroless tercih edilerek bellek tüketimi minimumda tutulmuştur.

---

## 🚀 Başlangıç Adımları

Eğitime sunum akışıyla eşzamanlı olarak ilk modülden başlayarak ilerleyin:

```bash
cd 00-linux-essentials
cat README.md
```
