# LAB-07-01 — Docker Compose V2 Temelleri, .env Yönetimi ve Healthcheck Zinciri

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 35 dakika | `docker compose`, `postgres:16-alpine`, `curl` | `8000` |

---

## 1. Amaç

Bu laboratuvarın amacı; birden fazla servisten oluşan mikroservis mimarilerini tek bir bildirimsel (declarative) dosya (`docker-compose.yaml`) ile yönetmek, hassas bilgileri `.env` dosyasından okumak ve servisler arasında **sağlık kontrolü (healthcheck)** zinciri kurmaktır:

1. **Declarative Orkestrasyon:** Uzun ve karmaşık `docker run` komutlarını tek bir YAML dosyasında standartlaştırmak.
2. **Ortam Değişkenleri (.env):** Şifreleri ve portları doğrudan YAML içine gömmek yerine 12-Factor App prensibine uygun olarak `.env` dosyasından dinamik beslemek.
3. **`depends_on: condition: service_healthy`:** Veritabanı sadece açılmakla kalmayıp, TCP portundan sorgu kabul edecek duruma (healthy) gelene kadar API servisinin başlamasını bekletmek.

---

## 2. Mimari ve Başlatma Sırası

```text
                                  1. docker compose up -d
                                             │
                                             ▼
+─────────────────────────────────────────────────────────────────────────────+
| [1. ADIM] DATABASE BAŞLATILIR (postgres:16-alpine)                          |
| - Healthcheck: pg_isready -U devopsuser -d devopsdb                         |
| - Durum: starting ➔ [HEALTHY] (Yaklaşık 3-5 saniye)                         |
+─────────────────────────────────────────────────────────────────────────────+
                                             │
                            depends_on: condition: service_healthy
                                             ▼
+─────────────────────────────────────────────────────────────────────────────+
| [2. ADIM] WEB-API BAŞLATILIR (python:3.12-alpine)                           |
| - Veritabanı hazır olmadan asla başlamaz (Bağlantı hatası yaşanmaz!)        |
| - Port: 8000 (Dış dünyaya açık)                                             |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 3. Görevler (Tasks)

1. `docker-compose.yaml` ve `.env` dosyalarını inceleyin.
2. `docker compose config` komutuyla YAML sözdizimini ve `.env` değişkenlerinin doğru yerleştiğini doğrulayın.
3. `docker compose up -d` ile stack'i arka planda ayağa kaldırın.
4. `docker compose ps` komutunu çalıştırarak veritabanının `healthy` durumuna geçişini izleyin.
5. `curl http://localhost:8000` ile API'nin çalıştığını doğrulayın.
6. `docker compose down -v` ile ortamı ve volume'ları temizleyin.

---

## Adım Adım Uygulama ve Doğrulama

```bash
# 1. Konfigürasyonu doğrulama
docker compose config

# 2. Stack'i başlatma
docker compose up -d

# 3. Canlı durum ve sağlık kontrolü
docker compose ps

# 4. API testi
curl -i http://localhost:8000

# 5. Temizlik
docker compose down -v
```

---

## Beklenen Sonuç ve Doğrulama

```bash
docker compose ps
```

* **Beklenen Çıktı:**
```text
NAME         IMAGE                COMMAND                  SERVICE    STATUS
compose-api  python:3.12-alpine   "sh -c 'echo 'API ba…"   web-api    running
compose-db   postgres:16-alpine   "docker-entrypoint.s…"   database   running (healthy)
```
