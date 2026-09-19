# LAB-07-03 — 3-Tier Mikroservis Mimarisi (Nginx Gateway + FastAPI + Redis + PostgreSQL)

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri | 45 dakika | `docker compose`, `nginx`, `fastapi`, `redis:7`, `postgres:16` | `19001 (App1 Slotu)` |

> **Önemli Erişim Notu:** Sunucumuzda Port 80 ve 443 doğrudan Nginx Master Reverse Proxy tarafından dinlendiğinden, port çakışmasını engellemek amacıyla Gateway portu `.env` dosyasında `GATEWAY_PORT=19001` olarak yapılandırılmıştır. Servislere tarayıcınızdan `http://<SUNUCU-IP>:19001` veya Reverse Proxy üzerinden `https://studentXX-app1.<domain>` ile erişebilirsiniz.

---

## 1. Amaç

Bu laboratuvarın amacı; kurumsal prodüksiyon seviyesinde **3-Tier (Üç Katmanlı) Güvenli Mikroservis Mimarisini** Docker Compose ile ayağa kaldırmaktır:

1. **Katman 1 (Sunum / Gateway):** Nginx Reverse Proxy (Dış dünyaya tek açık nokta: Port 19001).
2. **Katman 2 (Uygulama Mantığı):** Python FastAPI mikroservisi (İş mantığı ve API endpoint'leri).
3. **Katman 3 (Veri & Önbellek):** PostgreSQL 16 ve Redis 7.
4. **Çift Ağ İzolasyonu (DMZ Modeli):**
   * `public-net`: Yalnızca Nginx ve API bağlıdır.
   * `internal-net`: Yalnızca API, Redis ve PostgreSQL bağlıdır.
   * **Sonuç:** Veritabanı ve önbellek dış ağdan tamamen yalıtılmıştır; hacker Nginx'i ele geçirse bile veritabanına doğrudan TCP erişimi sağlayamaz!

---

## 2. Mimari ve Ağ İzolasyon Modeli

```text
                           İNTERNET / WEB TARAYICI
                                     │
                                Port: 19001
                                     ▼
+─────────────────────────────────────────────────────────────────────────────+
| PUBLIC NETWORK (Dışa Açık Ağ)                                               |
|                                                                             |
|  [ NGINX REVERSE PROXY: compose-gateway ] (Port 19001)                      |
|                   │                                                         |
|                   │ proxy_pass http://api:8000/                             |
|                   ▼                                                         |
|  [ FASTAPI MİKROSERVİSİ: compose-api ]                                      |
+─────────────────────────────────────────────────────────────────────────────+
                    │
                    ▼ (İki Ağa da Bağlı Köprü)
+─────────────────────────────────────────────────────────────────────────────+
| INTERNAL NETWORK (İzole İç Ağ - DIŞ DÜNYAYA TAMAMEN KAPALI!)                |
|                                                                             |
|                   │                                 │                       |
|                   ▼                                 ▼                       |
|  [ REDIS 7 ÖNBELLEK: compose-redis ]   [ POSTGRESQL 16: compose-postgres ]  |
|  - Sadece iç ağdan erişilebilir       - Sadece iç ağdan erişilebilir        |
|  - Healthcheck: redis-cli ping         - Healthcheck: pg_isready            |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## 3. Görevler (Tasks)

1. `docker-compose.yaml`, `.env` ve `services/` dizinindeki Nginx/FastAPI kodlarını inceleyin.
2. `public-net` ve `internal-net` ayrımını analiz edin.
3. `./test-stack.sh` betiğini çalıştırarak stack'i başlatın ve otomatik sağlık testlerini yürütün.
4. `http://localhost:19001/api/v1/products` adresine istek atarak veritabanından veri çekildiğini ve Redis'e önbelleklendiğini doğrulayın.
5. Veritabanı portunun (5432) ana makinede açık olmadığını (`curl localhost:5432` veya `nc -zv localhost 5432`) teyit edin.

---

## 4. İpuçları

<details>
<summary>💡 İpucu 1: Neden 2 Ayrı Network?</summary>

Geleneksel tek network kullanımında tüm konteynerlar aynı yayın (broadcast) alanındadır. DMZ (Demilitarized Zone) deseniyle Nginx'i yalnızca API'ye, API'yi ise veritabanına bağlamak kurumsal güvenlik standartlarının (PCI-DSS, ISO 27001) temel gereksinimidir.
</details>

<details>
<summary>💡 İpucu 2: Çift Healthcheck ile Bağımlılık Zinciri</summary>

API servisi hem `db` hem de `cache` (Redis) servislerinin `service_healthy` durumunu bekler. Bu sayede ilk başlatmada hiçbir connection refused hatası alınmaz.
</details>

---

## 5. Referans Çözüm

<details>
<summary>🎯 Referans Otomasyon Betiği ve Komutlar</summary>

```bash
# 1. Otomatik test ve başlatma
chmod +x test-stack.sh
./test-stack.sh

# 2. Manuel Başlatma Komutları:
docker compose up -d --build
docker compose ps

# 3. Nginx üzerinden API'ye istek atma
curl -i http://localhost:19001/api/v1/products

# 4. Temizlik
docker compose down -v
```
</details>

---

## 6. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:19001/health
curl -s http://localhost:19001/api/v1/products
```

* **Gateway Yanıtı:** `{"status": "healthy", "service": "ecommerce-api", "cache": "connected", "db": "connected"}`
