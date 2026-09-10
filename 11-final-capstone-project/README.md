# LAB-11 — Docker Final Capstone Projesi: Üretim Seviyesi Güvenli Mikroservis Platformu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri / Uzman | 90 dakika | `docker compose`, Node.js, Postgres, Redis, Nginx, Secrets | `80` |

---

## Mimari ve Çalışma Modeli

```text
                           KULLANICI (Web Tarayıcı)
                                      │
                                  Port: 80
                                      ▼
+─────────────────────────────────────────────────────────────────────────────+
| CAPSTONE PUBLIC NETWORK (Dışa Açık Ağ)                                      |
|                                                                             |
|  [ NGINX REVERSE PROXY: capstone-gateway ]                                  |
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

## Adım Adım Uygulama

### Adım 1: Projeyi Derleme ve Başlatma

```bash
# 1. Platformu derleme ve arka planda başlatma
docker compose up -d --build

# 2. Tüm servislerin sağlıklı (healthy) olduğunu denetleme
docker compose ps
```

---

### Adım 2: Gateway ve REST API Doğrulama

```bash
# Gateway üzerinden sistem sağlık kontrolü
curl -i http://localhost/api/health

# Veritabanından gelen ürün listesini çekme
curl -i http://localhost/api/products
```

---

### Adım 3: Güvenlik, Secrets ve Kaynak Sınırlarını İnceleme

```bash
# Backend kaynak sınırlarının devrede olduğunu kontrol etme
docker inspect capstone-backend | grep -E '"Memory"|"NanoCpus"'

# PostgreSQL port durumu (Host portu açık olmamalıdır)
docker port capstone-postgres
```

---

## Temizlik

Platformu ve oluşturulan Named Volume diskini temizleyin:

```bash
docker compose down -v
```
