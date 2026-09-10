# LAB-07-05 — Docker Final Capstone Projesi: Üretim Seviyesi Güvenli Mikroservis Platformu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri / Uzman | 90 dakika | `docker compose`, Node.js, Postgres, Redis, Nginx, Secrets | `80` |

---

## 1. Amaç

Bu bitirme projesinde (Capstone), Docker eğitim serisi boyunca öğrenilen tüm yetkinlikler tek bir kurumsal mimaride birleştirilir:
1. **Nginx Reverse Proxy Gateway:** Dış dünyaya tek giriş kapısı (Port 80).
2. **Hardened Backend REST API:** Non-root kullanıcı (UID 10001), layer cache optimizasyonu, CPU ve RAM sınırları (`cpus: 0.5`, `memory: 256M`).
3. **Docker Secrets Entegrasyonu:** Veritabanı şifresini ortam değişkeni olarak açıkta bırakmak yerine `/run/secrets/db_password` dosyasından okuma.
4. **PostgreSQL 16 & Otomatik Tablo Başlatma:** `init.sql` ile konteyner ilk açıldığında otomatik veritabanı şemasını kurma.
5. **Redis 7 Önbellekleme:** Hızlı sorgular için bellek içi önbellek.
6. **Çift Ağ İzolasyonu (DMZ):** Veritabanı ve Redis dış ağdan tamamen yalıtılmış `internal-net` üzerindedir.

---

## 2. Uçtan Uca Capstone Mimarisi

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

## 3. Görevler (Tasks)

1. `docker-compose.yaml`, `secrets/db_password.txt` ve `init.sql` dosyalarını inceleyin.
2. `docker compose up -d --build` komutuyla platformu ayağa kaldırın.
3. `docker compose ps` komutunu çalıştırarak sağlık kontrollerinin sırasıyla `healthy` olduğunu doğrulayın.
4. `curl http://localhost/api/products` adresine istek atarak veritabanındaki 3 ürünün JSON olarak döndüğünü teyit edin.
5. `docker inspect capstone-backend` ile CPU ve RAM sınırlarının devrede olduğunu kontrol edin.
6. Test bittikten sonra `docker compose down -v` ile ortamı temizleyin.

---

## Adım Adım Uygulama ve Doğrulama

```bash
# 1. Projeyi derleme ve başlatma
docker compose up -d --build

# 2. Canlı durum kontrolü
docker compose ps

# 3. Sağlık kontrolü
curl -i http://localhost/api/health

# 4. Ürün listesini API üzerinden çekme
curl -i http://localhost/api/products

# 5. Temizlik
docker compose down -v
```

---

## Beklenen Sonuç ve Doğrulama

```bash
curl -s http://localhost/api/products
```

* **JSON Çıktısı:**
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
