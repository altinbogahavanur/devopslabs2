# 🐳 Docker Hands-on Lab Serisi (DevOps Practitioner)

Bu çalışma serisi; Linux sistem yönetiminden ve Docker Engine kurulumundan başlayarak konteyner yaşam döngüsünü, Dockerfile optimizasyonunu, 7 farklı dilde polyglot mikroservis paketlemeyi, kullanıcı tanımlı köprü (bridge) ağlarını, kalıcı depolamayı (Volume / Bind Mounts), Docker Compose V2 çoklu servis orkestrasyonunu, Google Distroless ve Trivy ile kurumsal güvenliği, CI/CD boru hatlarını (GitHub Actions, GitLab CI, Jenkins), 5 kritik arıza senaryosunu içeren **Troubleshooting Challenge** modülünü ve uçtan uca çok katmanlı mikroservis **Final Capstone** projesini uygulamalı olarak deneyimlemek için hazırlanmış pratik rehberdir.

> **Önemli Öğrenci Erişim Notu:** Eğitim sunucunuza (`student101`) erişirken ters vekil sunucusu (Reverse Proxy) tanımlı portlar (`app1` için `19001`, `app3` için `19003` vb.) kullanılabilir. Bunların dışındaki veya yerel test portları için tarayıcınızdan doğrudan `http://<SUNUCU-IP>:<PORT>` adresini kullanabilir veya sunucu içinde `curl http://localhost:<PORT>` ile test yapabilirsiniz.

---

## 📚 Laboratuvar Listesi ve Konu Haritası

### 🛠️ 0. Altyapı Hazırlığı ve Docker Kurulumu
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **00** | [`00-linux-essentials`](00-linux-essentials/README.md) | Başlangıç | **9 Sütunlu Linux Rehberi:** Paket, Servis, Multi-Port, Kullanıcı/Sudo, Dosya, Süreç/Htop, SSH, 16 GB Swap ve Ağ/DNS Araçları (Açılır-Kapanır Başlıklar) | `bash`, `apt`, `systemd`, `htop`, `ss`, `dig`, `swap` |
| **01** | [`01-docker-installation`](01-docker-installation/README.md) | Başlangıç | Resmi Docker Engine, Buildx ve Compose V2 Kurulumu, Non-root Kullanıcı Grubu İzni, `daemon.json` Log Rotasyonu | `docker-ce`, `docker-compose-plugin`, `portainer` |

---

### 🟢 1. Konteyner Çekirdek İş Yükleri ve İmaj Üretimi
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **02** | [`02-container-fundamentals`](02-container-fundamentals/README.md) | Başlangıç - İleri | **Modüler Temeller:** Yaşam Döngüsü (`01`), `docker cp` / `commit` / Teşhis (`02`) ve **Advanced:** CPU/RAM Sınırları & Exit Code 137 OOMKilled (`03`) | `docker run`, `docker cp`, `inspect`, `cgroups-v2` |
| **03** | [`03-dockerfile-and-caching`](03-dockerfile-and-caching/README.md) | Temel - İleri | **Dockerfile Mimarisi:** Temel Direktifler (`01`), Katman Önbellekleme Optimizasyonu (`02`) ve **Advanced:** Multi-Stage Build & BuildKit (`03`) | `Dockerfile`, `BuildKit`, `.dockerignore`, `multi-stage` |
| **04** | [`04-polyglot-app-dockerization`](04-polyglot-app-dockerization/README.md) | Orta - İleri | **7 Farklı Dilin Paketlenmesi:** Node.js, Python FastAPI, Go Scratch (~8MB), Java Spring Boot Layered JAR, .NET 8, PHP 8.3, React SPA + Nginx | Express, FastAPI, Go Scratch, Spring Boot, Vite |

---

### 🌐 2. Kalıcı Depolama, Ağ ve Kayıt Defteri (Storage & Networking)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **05** | [`05-backup-restore-and-registry`](05-backup-restore-and-registry/README.md) | Orta - İleri | **Yedekleme ve Kayıt Defteri:** İmaj/Volume Yedekleme (`save`/`load`) (`01`), Yerel `registry:2` (`02`) ve **Advanced:** Kurumsal VMware Harbor Mimarisi (`03`) | `docker save`, `registry:2`, `harbor`, `robot-accounts` |
| **06** | [`06-docker-networking`](06-docker-networking/README.md) | Orta - İleri | **Ağ Sürücüleri ve İzolasyon:** Özel Bridge & Dahili DNS (`01`), Host & None Network (`02`) ve **Advanced:** Çoklu Ağ DMZ Mimarisi & Aliases (`03`) | `app-net`, `127.0.0.11`, `host`, `none`, `network-alias` |
| **07** | [`07-docker-storage`](07-docker-storage/README.md) | Orta - İleri | **Kalıcı Depolama Yönetimi:** Named Volume & Bind Mounts (`01`), Bellek İçi `tmpfs` (`02`) ve **Advanced:** Volume İzinleri (UID/GID Mismatch) Çözümü (`03`) | `named-volume`, `bind-mount`, `tmpfs`, `--user` |

---

### 📦 3. Çoklu Konteyner ve Orkestrasyon (Docker Compose V2)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **08** | [`08-docker-compose-stacks`](08-docker-compose-stacks/README.md) | Orta - İleri | **Bildirimsel Orkestrasyon:** Compose Temelleri & Healthcheck (`01`), WordPress+MySQL (`02`), 3-Tier Web-API-DB (`03`), **Advanced:** Voting App (`04`) ve Profiller/Overrides (`05`) | `docker compose`, `service_healthy`, `profiles`, Nginx, Redis |

---

### 🔒 4. Kurumsal Güvenlik, Sertleştirme ve Zafiyet Analizi
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **09** | [`09-security-and-distroless`](09-security-and-distroless/README.md) | İleri - Uzman | **Konteyner Sertleştirme:** Google Distroless & Non-Root (`01`), Aqua Security Trivy CVE Taraması (`02`) ve **Advanced:** Linux Capabilities Drop & Salt-Okunur Dosya Sistemi (`03`) | `distroless`, `trivy`, `--cap-drop=ALL`, `--read-only` |

---

### 🚀 5. Sürekli Entegrasyon ve Dağıtım (CI/CD Pipelines)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **10** | [`10-cicd-container-pipelines`](10-cicd-container-pipelines/README.md) | İleri | **Otomatik Boru Hatları:** GitHub Actions (`01`), GitLab CI Docker-in-Docker (`02`) ve **Advanced:** Jenkins Declarative Pipeline ile Trivy Kapısı ve Harbor Push (`03`) | GitHub Actions, `.gitlab-ci.yml`, `Jenkinsfile`, Trivy |

---

### 🏆 6. Hata Ayıklama ve Bitirme Projesi (Challenge & Capstone)
| No | Modül Klasörü | Seviye | Konu Başlığı ve Kapsam | Öne Çıkan Araçlar |
|:---:|:---|:---:|:---|:---|
| **11** | [`11-troubleshooting-challenge`](11-troubleshooting-challenge/README.md) | İleri | **Sorun Giderme Meydan Okuması:** Port Çakışması, Anında Kapanan Konteyner, OOMKilled (137), Volume Yetki Reddi ve Bridge DNS Kopukluğu (5 Gerçek Senaryo) | `docker logs`, `inspect`, `ss -tulpn`, `chown` |
| **12** | [`12-final-capstone-project`](12-final-capstone-project/README.md) | Uzman | **Büyük Final Projesi:** Nginx Gateway + Hardened REST API + PostgreSQL 16 + Redis 7 + Docker Secrets + Kaynak Sınırları ve Çift Ağ İzolasyonu | Uçtan Uca Kurumsal Mikroservis Mimarisi |

---

## ⚡ Hızlı Başlangıç

Tüm uygulamalara Linux sunucu hazırlıklarından başlayarak sırayla ilerleyin:

```bash
# 1. 00-linux-essentials klasörüne gidin
cd 00-linux-essentials

# 2. Rehberi inceleyin ve adımları uygulayın
cat README.md
```
