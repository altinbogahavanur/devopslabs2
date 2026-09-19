# Docker Hands-on Lab Serisi (DevOps Practitioner)

Bu laboratuvar serisi; Linux sistem yönetiminden ve Docker Engine mimarisinden başlayarak konteyner yaşam döngüsünü, Dockerfile katman önbellekleme optimizasyonunu, çok dilli (polyglot) mikroservis paketlemeyi, kullanıcı tanımlı köprü (bridge) ağlarını, kalıcı depolama yönetimini (Volume / Bind Mounts), Docker Compose V2 orkestrasyonunu, Google Distroless ve Trivy ile kurumsal güvenliği, 5 kritik arıza senaryosunu içeren **Troubleshooting Challenge** modülünü ve Port 19001 üzerinde çalışan uçtan uca çok katmanlı **Final Capstone** projesini uygulamalı olarak öğretmek üzere tasarlanmıştır.

> **Platform Mimarisi ve Port Erişim Kuralı:** 
> Azure eğitim sanal makinesinde Host **Port 80 (HTTP)** ve **Port 443 (HTTPS)** doğrudan **Nginx Master Reverse Proxy** tarafından kullanılmaktadır. Bu nedenle web arayüzü sunan laboratuvar uygulamaları (Modül 08 3-Tier Stack, Modül 12 Final Capstone vb.) platformda ayrılmış olan **Port 19001 (App1 Slotu)** üzerinden dışa açılır.
> Servislere tarayıcınızdan `http://<SUNUCU-IP>:19001` (veya Reverse Proxy üzerinden `https://studentXX-app1.<domain>`) adresiyle erişebilir ya da sunucu içinden `curl http://localhost:19001` komutuyla test edebilirsiniz.

---

## Müfredat ve Laboratuvar Modülleri

> **Eğitmen İçin Hızlandırılmış Rota (Fast-Track) Notu:**
> İsminin başında **`*`** bulunan modüller, sıfırdan başlayan katılımcılar için eğitim süresinin (1.5 - 2 gün) kısıtlı olduğu durumlarda öncelikli olarak tamamlanması gereken **olmazsa olmaz çekirdek** laboratuvarlarıdır. İşaretsiz modüller (`00`, `01`, `10`) ise ön hazırlık, platform doğrulaması veya tamamlayıcı referans konulardır.

### 🛠️ 0. Altyapı Hazırlığı ve Docker Kurulumu
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**00**](00-linux-essentials/README.md) | [`00-linux-essentials`](00-linux-essentials/README.md) | Başlangıç | **Linux Ön Hazırlığı:** Paket, Servis, Multi-Port (`ss`), Kullanıcı/Sudo, Süreç (`htop`), 16 GB Swap ve Ağ/DNS Araçları | *Ön Hazırlık / Hızlı Kontrol* |
| [**01**](01-docker-installation/README.md) | [`01-docker-installation`](01-docker-installation/README.md) | Başlangıç | Resmi Docker Engine, Buildx ve Compose V2 Mimarisi, Non-root İzni, `daemon.json` Log Rotasyonu | *Platform Doğrulama (Zaten Kurulu)* |

---

### 🟢 1. Konteyner Çekirdek İş Yükleri ve İmaj Üretimi
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**`*` 02**](02-container-fundamentals/README.md) | [`02-container-fundamentals`](02-container-fundamentals/README.md) | Başlangıç - İleri | **Konteyner Temelleri:** Yaşam Döngüsü (`run`, `exec`, `logs`, port mapping), `docker cp` / `commit` ve CPU/RAM Sınırları & Exit Code 137 OOMKilled | **Çekirdek Zorunlu** |
| [**`*` 03**](03-dockerfile-and-caching/README.md) | [`03-dockerfile-and-caching`](03-dockerfile-and-caching/README.md) | Temel - İleri | **Dockerfile Mimarisi:** Temel Direktifler, Katman Önbellekleme Optimizasyonu (BuildKit), Multi-Stage Build & Minimal İmajlar | **Çekirdek Zorunlu** |
| [**`*` 04**](04-polyglot-app-dockerization/README.md) | [`04-polyglot-app-dockerization`](04-polyglot-app-dockerization/README.md) | Orta - İleri | **Çok Dilli Paketleme (Fast-Track: Node.js & Go Scratch):** Web runtime ve ultra hafif (~8MB) Go derlemesi. *(Python, Java, .NET, PHP, React referans)* | **Çekirdek Zorunlu** |

---

### 🌐 2. Kalıcı Depolama, Ağ ve Registry (Storage & Networking)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**`*` 05**](05-backup-restore-and-registry/README.md) | [`05-backup-restore-and-registry`](05-backup-restore-and-registry/README.md) | Orta - İleri | **Yedekleme ve Registry:** İmaj/Volume Yedekleme (`save`/`load`), Yerel `registry:2` (`5000`) ve Kurumsal Harbor Registry (`18444`) Push/Pull | **Çekirdek Zorunlu** |
| [**`*` 06**](06-docker-networking/README.md) | [`06-docker-networking`](06-docker-networking/README.md) | Orta - İleri | **Ağ Sürücüleri ve İzolasyon:** Özel Bridge & Dahili DNS (`127.0.0.11`), Host & None Network, Çoklu Ağ DMZ Mimarisi | **Çekirdek Zorunlu** |
| [**`*` 07**](07-docker-storage/README.md) | [`07-docker-storage`](07-docker-storage/README.md) | Orta - İleri | **Kalıcı Depolama Yönetimi:** Named Volume & Bind Mounts, Bellek İçi `tmpfs`, Volume İzinleri (UID/GID Mismatch) Çözümü | **Çekirdek Zorunlu** |

---

### 📦 3. Çoklu Konteyner ve Orkestrasyon (Docker Compose V2)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**`*` 08**](08-docker-compose-stacks/README.md) | [`08-docker-compose-stacks`](08-docker-compose-stacks/README.md) | Orta - İleri | **Bildirimsel Orkestrasyon:** Compose V2 Temelleri & Healthcheck, 3-Tier Web-API-DB Stack (`19001`), Profiller ve Çevre Değişkenleri | **Çekirdek Zorunlu** |

---

### 🔒 4. Kurumsal Güvenlik, Sertleştirme ve Zafiyet Analizi
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**`*` 09**](09-security-and-distroless/README.md) | [`09-security-and-distroless`](09-security-and-distroless/README.md) | İleri - Uzman | **Konteyner Sertleştirme:** Google Distroless & Non-Root Kullanıcı, Aqua Security Trivy CVE Taraması, Linux Capabilities Drop | **Çekirdek Zorunlu** |

---

### 🚀 5. Sürekli Entegrasyon ve Dağıtım (CI/CD Pipelines)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**10**](10-cicd-container-pipelines/README.md) | [`10-cicd-container-pipelines`](10-cicd-container-pipelines/README.md) | İleri | **Konteyner Pipeline'ları (CI/CD):** GitHub Actions, GitLab CI ve Jenkins Entegrasyonu *(Bu konular bağımsız Jenkins ve GitLab modüllerinde detaylı işlenir)* | *Seçmeli / Crossover* |

---

### 🏆 6. Hata Ayıklama ve Bitirme Projesi (Challenge & Capstone)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Durum |
|:---:|:---|:---:|:---|:---:|
| [**`*` 11**](11-troubleshooting-challenge/README.md) | [`11-troubleshooting-challenge`](11-troubleshooting-challenge/README.md) | İleri | **Sorun Giderme Simülatörü:** Port Çakışması, Anında Kapanan Konteyner, OOMKilled (137), Volume Yetki Reddi ve Bridge DNS Kopukluğu | **Çekirdek Zorunlu** |
| [**`*` 12**](12-final-capstone-project/README.md) | [`12-final-capstone-project`](12-final-capstone-project/README.md) | Uzman | **Büyük Final Projesi:** Nginx Gateway (`19001`) + Hardened REST API + PostgreSQL 16 + Redis 7 + Docker Secrets + Kaynak Sınırları ve Çift Ağ İzolasyonu | **Büyük Final** |

---

## Platform Port ve Servis Haritası

Laboratuvar uygulamalarının çakışma yaşamadan çalışabilmesi için Azure VM üzerindeki port düzeni:

| Servis / Uygulama | Port | Protokol | Açıklama |
|---|---|---|---|
| **Nginx Master Reverse Proxy** | `80`, `443` | HTTP / HTTPS | Sunucu ana giriş noktası ve wildcard SSL |
| **Cockpit Web Terminal** | `9090` | HTTPS | Tarayıcı tabanlı Linux terminali |
| **Docker Labs Capstone / App1** | `19001` | HTTP | **Lab 12 Capstone & Lab 08 3-Tier Gateway** |
| **Docker Labs App2 Slotu** | `19002` | HTTP | Yedek mikroservis slotu |
| **Docker Labs App3 Slotu** | `19003` | HTTP | Yedek mikroservis slotu |
| **Harbor OCI Registry** | `18444` | HTTP | Kurumsal OCI image registry'si (`Lab 05`) |
| **Yerel Registry:2** | `5000` | HTTP | Hafif test image registry'si (`Lab 05`) |
| **Jenkins CI/CD** | `18080` | HTTP | Jenkins otomasyon sunucusu |
| **SonarQube** | `19000` | HTTP | Statik kod analizi ve Quality Gate |
| **GitLab CE** | `18929` | HTTP | SCM kaynak kod repository'si (GitLab) |
| **KinD K8s API** | `6443` | HTTPS | Yerel Kubernetes Control Plane API |

---

## ⚡ Hızlı Başlangıç

1. Sunucu kaynaklarını ve Docker motor durumunu doğrulayın:
   ```bash
   docker version
   docker compose version
   free -h
   ```

2. Çekirdek rota üzerinden ilk zorunlu laboratuvara ([`02-container-fundamentals/01-container-lifecycle`](02-container-fundamentals/01-container-lifecycle/README.md)) geçin:
   ```bash
   cd 02-container-fundamentals/01-container-lifecycle
   cat README.md
   ```

3. Her laboratuvar bitiminde oluşturulan konteynerleri durdurup temizleyin:
   ```bash
   docker compose down -v 2>/dev/null || docker rm -f $(docker ps -q --filter "name=lab-") 2>/dev/null || true
   ```
