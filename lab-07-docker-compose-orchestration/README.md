# LAB-DOC-07 — Docker Compose Mimarileri ve Orkestrasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker compose v2`, `nginx`, `redis`, `postgres` | 8000, 8080, 5000, 19001 |

---

## Amaç

Bu laboratuvarda çoklu konteyner mimarilerinin (Multi-Container Stacks) Docker Compose V2 kullanılarak tek bir bildirimsel YAML dosyası (`docker-compose.yaml`) ile nasıl orkestre edildiği uygulamalı olarak ele alınır:

- **Declarative Stack Yönetimi:** Çok sayıda bağımsız `docker run` komutu yerine tüm servisleri, ağları ve volume'ları tek bir dosyada tanımlamak.
- **Sağlık Kontrolü Zinciri:** `depends_on` direktifini `condition: service_healthy` ile birleştirerek veritabanı sorgu kabul etmeden API servisinin başlamasını önlemek (CrashLoop engelleme).
- **12-Factor App & .env:** Konfigürasyon ve gizli değişkenleri Compose dosyasına gömmek yerine `.env` dosyasından dinamik beslemek.
- **Çift Ağ (DMZ) İzolasyonu:** Frontend ve backend servislerini ayrı bridge ağlarına bağlayarak veritabanının dış dünyadan erişilemez olmasını sağlamak.
- **Compose Profiles:** Geliştirme, debug veya migration servislerini yalnızca ihtiyaç anında (`--profile debug`) ayağa kaldırmak.

---

## Ön Koşullar

- Docker Engine 24+ ve Docker Compose V2 eklentisi (`docker compose version`).
- `curl` ve `jq` yardımcı araçları.
- Çalışma dizininde port çakışması olmaması (`8000`, `8080`, `5000`, `19001`).

```bash
docker compose version
```

---

## Mimari ve Çalışma Modeli

```text
                                  docker compose up -d
                                           │
             ┌─────────────────────────────┴─────────────────────────────┐
             ▼                                                           ▼
+─────────────────────────+                                 +─────────────────────────+
|      public-net         |                                 |       internal-net      |
|  (Dış Dünyaya Açık Ağ)   |                                 | (Dış Dünyaya Kapalı Ağ) |
+────────────┬────────────+                                 +────────────┬────────────+
             │                                                           │
             ▼                                                           ▼
     [ web / nginx ] ───────────────────────────────────────────► [ postgres-db ]
      (Port: 19001)            proxy_pass: api:8000               (Port: 5432 - Gizli)
             ▲                                                           ▲
             │                                                           │
             └─────────────────────► [ api-backend ] ────────────────────┘
                                   (depends_on: db healthy)
```

---

## Modül Laboratuvarları

Bu laboratuvar dizini, aşamalı 5 alt uygulamadan oluşur:

| No | Laboratuvar Dizini | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-compose-fundamentals`](01-compose-fundamentals/README.md) | Orta | Temel `docker-compose.yaml`, `.env` yönetimi ve `service_healthy` bağımlılık zinciri. |
| **02** | [`02-wordpress-mysql`](02-wordpress-mysql/README.md) | Orta | Klasik 2-katmanlı CMS mimarisi ve Named Volume kalıcılığı. |
| **03** | [`03-3tier-web-api-db`](03-3tier-web-api-db/README.md) | Orta - İleri | Nginx Gateway + FastAPI + Redis + PostgreSQL ile Çift Ağ (DMZ) izolasyonu. |
| **04** | [`advanced/04-example-voting-app`](advanced/04-example-voting-app/README.md) | İleri | 5 bileşenli polyglot mikroservis mimarisi (Python, Node.js, .NET, Redis, Postgres). |
| **05** | [`advanced/05-compose-profiles-and-overrides`](advanced/05-compose-profiles-and-overrides/README.md) | İleri | `profiles: [debug]`, çoklu ortam (`compose.prod.yaml`) ezme (override) mekanizması. |

---

## Adım Adım Uygulama Rehberi

### Adım 1: Compose V2 Temel Yapısını Doğrulama

İlk uygulamaya geçerek Compose dosyasını derleme öncesi doğrulayın:

```bash
cd 01-compose-fundamentals
docker compose config
```

Çıktıda ortam değişkenlerinin `.env` dosyasından okunup yerleştiğini inceleyin.

### Adım 2: Sağlık Kontrolü Zinciri ile Başlatma

Servisleri arka planda ayağa kaldırın ve sağlık durumlarını izleyin:

```bash
docker compose up -d
docker compose ps
```

Veritabanının `starting` durumundan `healthy` durumuna geçişini ve ardından API servisinin başladığını gözlemleyin.

### Adım 3: Çok Katmanlı Stack Çalıştırma (3-Tier DMZ)

3 katmanlı mikroservis mimarisini başlatın:

```bash
cd ../03-3tier-web-api-db
docker compose up -d --build
docker compose ps
```

### Adım 4: Servis Sağlığını ve Ağ İzolasyonunu Doğrulama

Nginx Gateway üzerinden API uç noktasına istek atın:

```bash
curl -i http://localhost:19001/health
```

Veritabanı portunun host üzerinde açılmadığını doğrulayın:

```bash
docker port compose-postgres 2>/dev/null || echo "Veritabanı portu izole ve dışa kapalı."
```

---

## Doğal Doğrulama ve Beklenen Sonuç

1. **Çalışan Servisleri Listeleme:**
   ```bash
   docker compose ps
   ```
   Tüm servislerin `STATUS` sütununda `Up` ve tanımlı ise `(healthy)` ifadesi yer almalıdır.

2. **Servis Loglarını İnceleme:**
   ```bash
   docker compose logs -f --tail=20
   ```

3. **HTTP Endpoint Doğrulama:**
   ```bash
   curl -s http://localhost:19001/health
   ```
   Beklenen Çıktı: `{"status":"healthy","service":"ecommerce-api","cache":"connected","db":"connected"}`

---

## Temizlik

Oluşturulan stack'leri, ağları ve volume'ları tamamen temizleyin:

```bash
docker compose down -v
```
