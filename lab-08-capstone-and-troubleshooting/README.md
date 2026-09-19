# LAB-DOC-08 — Büyük Final Capstone Projesi ve Gerçek Hayat Sorun Giderme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 90 dakika | `docker compose`, `nginx`, `nodejs`, `postgres`, `redis`, `ss`, `curl` | `19001 (App1 Slotu)` |

[lab-08-capstone-and-troubleshooting.zip](lab-08-capstone-and-troubleshooting.zip)

## Amaç

Bu bitirme ve sorun giderme laboratuvarında, Docker eğitim serisi boyunca öğrenilen tüm mimari ve operasyonel yetkinlikler kurumsal bir mikroservis platformunda birleştirilir:

- **Üretim Seviyesi Capstone Platformu:**
  1. **Nginx Reverse Proxy Gateway:** Dış dünyaya açılan tek giriş noktası (**Port 19001 / App1 Slotu**).
  2. **Hardened Backend REST API:** Non-root kullanıcı (UID 10001), layer caching optimizasyonu, CPU ve RAM sınırları (`cpus: 0.5`, `memory: 256M`).
  3. **Docker Secrets Entegrasyonu:** Hassas veritabanı şifresini ortam değişkeni yerine `/run/secrets/db_password` dosyasından okuma.
  4. **PostgreSQL 16 & init.sql:** Konteyner ilk başladığında otomatik veritabanı şemasını ve örnek verileri yükleme.
  5. **Redis 7 Önbellekleme:** Hızlı sorgular için in-memory veri deposu.
  6. **Çift Ağ (DMZ) İzolasyonu:** Veritabanı ve Redis servislerinin dış ağdan tamamen yalıtılmış `internal-net` üzerinde tutulması.
- **Gerçek Hayat Sorun Giderme (3 Kritik Arıza Senaryosu):**
  1. **Senaryo 1:** Port Çakışması (`bind: address already in use`) tespiti ve `ss -tulpn` ile çözümü.
  2. **Senaryo 2:** PID 1 Erken Çıkış (Immediate Exit / Daemon vs Foreground) tespiti ve Dockerfile düzeltmesi.
  3. **Senaryo 3:** Exit Code 137 (OOMKilled) tespiti ve cgroup bellek sınırlarının analizi.

---

## Ön Koşullar

- Docker Engine 24+ ve Docker Compose V2 eklentisi.
- Port 19001'in kullanılabilir olması (`ss -tulpn | grep 19001`).
- `curl` ve `jq` yardımcı araçları.

```bash
docker compose version
```

---

## Mimari ve Çalışma Modeli

```text
                           KULLANICI (Web Tarayıcı / curl)
                                       │
                                  Port: 19001 (App1)
                                       ▼
+─────────────────────────────────────────────────────────────────────────────+
| CAPSTONE PUBLIC NETWORK (Dışa Açık Ağ)                                      |
|                                                                             |
|  [ NGINX GATEWAY: capstone-gateway ]                                        |
|                   │                                                         |
|                   │ proxy_pass http://backend:3000/api/                     |
|                   ▼                                                         |
|  [ BACKEND REST API: capstone-backend ]                                      |
|  - Non-root UID: 10001, Limit: 256MB RAM / 0.5 CPU                          |
|  - Secret Mount: /run/secrets/db_password                                   |
+─────────────────────────────────────────────────────────────────────────────+
                    │
                    ▼ (İç İletişim Köprüsü)
+─────────────────────────────────────────────────────────────────────────────+
| CAPSTONE INTERNAL NETWORK (İç Güvenlik Ağı - DIŞA TAMAMEN KAPALI)           |
|                                                                             |
|                   │                                 │                       |
|                   ▼                                 ▼                       |
|  [ REDIS 7 ÖNBELLEK: capstone-redis ]    [ POSTGRESQL 16: capstone-postgres ]|
|  - In-memory data store                 - POSTGRES_PASSWORD_FILE=/run/...   |
|  - Healthcheck: redis-cli ping          - Volume: capstone-pgdata           |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### Bölüm 1: Capstone Mimarisi Dağıtımı ve Testi

#### Adım 1: Çalışma Dizinini İnceleme

```bash
cd lab-08-capstone-and-troubleshooting
cat docker-compose.yaml
```

Dosyada yer alan `secrets`, `deploy.resources.limits`, `condition: service_healthy` ve `networks` tanımlarını inceleyin.

#### Adım 2: Stack'i Derleme ve Başlatma

Platformu arka planda derleyip ayağa kaldırın:

```bash
docker compose up -d --build
```

#### Adım 3: Servis Sağlık Durumlarını İzleme

Tüm servislerin ayağa kalkışını ve sağlık durumlarını denetleyin:

```bash
docker compose ps
```

Tüm servislerin `STATUS` değerinde `(healthy)` ifadesinin belirmesini bekleyin.

#### Adım 4: Gateway ve REST API Doğrulama

Gateway (Port 19001) üzerinden sağlık kontrolü ve ürün listesini çekin:

```bash
# Sistem sağlık kontrolü
curl -i http://localhost:19001/api/health

# Veritabanından gelen ürün listesi
curl -s http://localhost:19001/api/products | jq .
```

#### Adım 5: Kaynak Sınırlarını ve Ağ İzolasyonunu Kanıtlama

Konteyner cgroup sınırlarını ve host port izolasyonunu doğrulayın:

```bash
# Backend CPU ve RAM sınırları
docker inspect capstone-backend | grep -E '"Memory"|"NanoCpus"'

# PostgreSQL port durumu (Host portu OLMAMALIDIR)
docker port capstone-postgres
```

---

### Bölüm 2: Gerçek Hayat Sorun Giderme (3 Kritik Senaryo)

Bu bölümde üretim ortamlarında en sık yaşanan 3 hata senaryosunu bilinçli olarak canlandırıp teşhis ve onarımını yapacağız.

#### Senaryo 1: Port Çakışması (`bind: address already in use`)

1. **Hata Oluşturma:** Host üzerinde boş bir portu simüle eden bir konteyner başlatın:
   ```bash
   docker run -d --name conflict-test -p 19005:80 nginx:alpine
   ```
2. **Çakışmayı Tetikleme:** Aynı porta ikinci bir konteyner bağlamaya çalışın:
   ```bash
   docker run -d --name conflict-fail -p 19005:80 httpd:alpine
   ```
   *Hata Çıktısı:* `Bind for 0.0.0.0:19005 failed: port is already allocated`
3. **Teşhis (Diagnostic):** Hangi sürecin portu dinlediğini bulun:
   ```bash
   ss -tulpn | grep 19005
   # veya Docker üzerinden:
   docker ps --filter "publish=19005"
   ```
4. **Onarım (Remediation):** Çakışan konteyneri durdurun ve silin:
   ```bash
   docker rm -f conflict-test
   ```

#### Senaryo 2: PID 1 Erken Çıkış (Immediate Exit / Foreground vs Background)

1. **Hata Oluşturma:** Nginx'i arka plan (daemon) modunda başlatan bir konteyner çalıştırın:
   ```bash
   docker run -d --name pid1-exit-test nginx:alpine nginx
   ```
2. **Teşhis (Diagnostic):** Konteyner durumunu kontrol edin:
   ```bash
   docker ps -a --filter "name=pid1-exit-test"
   ```
   *Gözlem:* Konteyner `Exited (0)` durumundadır çünkü `nginx` komutu arka plana geçmiş, PID 1 süreci sonlanmıştır.
   Logları inceleyin:
   ```bash
   docker logs pid1-exit-test
   ```
3. **Onarım (Remediation):** Konteyner ana sürecinin foreground modda çalıştırılması gerektiğini belirleyin:
   ```bash
   docker rm -f pid1-exit-test
   docker run -d --name pid1-fixed -p 19006:80 nginx:alpine nginx -g "daemon off;"
   docker ps --filter "name=pid1-fixed"
   docker rm -f pid1-fixed
   ```

#### Senaryo 3: Exit Code 137 (OOMKilled - Out Of Memory)

1. **Hata Oluşturma:** 32 MB bellek limiti verilmiş bir konteynerde 100 MB bellek tüketimi başlatın:
   ```bash
   docker run -d --name oom-test --memory="32m" polinux/stress stress --vm 1 --vm-bytes 100M
   ```
2. **Teşhis (Diagnostic):** Konteynerin durumunu ve çıkış kodunu denetleyin:
   ```bash
   docker ps -a --filter "name=oom-test"
   ```
   *Gözlem:* `Exited (137)`. (128 + 9 = 137, SIGKILL sinyali ile Linux kernel tarafından sonlandırılmıştır).
   OOM durumunu doğrulamak için `inspect` komutunu çalıştırın:
   ```bash
   docker inspect oom-test --format 'OOMKilled: {{.State.OOMKilled}}, ExitCode: {{.State.ExitCode}}'
   ```
   *Beklenen Çıktı:* `OOMKilled: true, ExitCode: 137`
3. **Onarım (Remediation):** Konteyneri temizleyip bellek sınırını yeterli seviyeye yükselterek çalıştırın:
   ```bash
   docker rm -f oom-test
   ```

---

## Doğal Doğrulama ve Beklenen Sonuç

Tüm adımlar tamamlandığında Capstone API'sinden gelen JSON verisini doğrulayın:

```bash
curl -s http://localhost:19001/api/products | jq .
```

* **Beklenen Başarılı Çıktı:**
```json
{
  "success": true,
  "count": 3,
  "data": [
    {"id": 1, "name": "Kubernetes & Docker El Kitabi", "price": "350.00", "stock": 100},
    {"id": 2, "name": "DevOps Pipeline Mimarisi", "price": "450.00", "stock": 50},
    {"id": 3, "name": "Linux Sistem Yonetimi", "price": "280.00", "stock": 75}
  ]
}
```

---

## Temizlik

Laboratuvar tamamlandığında Capstone stack'ini ve veritabanı volume'unu temizleyin:

```bash
docker compose down -v
```
