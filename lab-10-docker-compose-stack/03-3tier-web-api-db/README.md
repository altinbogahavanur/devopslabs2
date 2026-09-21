# LAB-DOC-07-03 — 3-Tier Mikroservis Mimarisi (Nginx Gateway + FastAPI + Redis + PostgreSQL)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker compose`, `nginx`, `fastapi`, `redis:7`, `postgres:16` | 19001 (App Slot 1) |

> **Önemli Erişim Notu:** Host üzerindeki 80 ve 443 port çakışmalarını önlemek için Nginx Gateway portu `.env` dosyasında `GATEWAY_PORT=19001` olarak yapılandırılmıştır. Tarayıcıdan `http://<SUNUCU-IP>:19001` üzerinden erişebilirsiniz.

---

## Amaç

Kurumsal prodüksiyon seviyesinde **3-Tier (Üç Katmanlı) Güvenli Mikroservis Mimarisini** Docker Compose ile ayağa kaldırmak ve yönetmektir:

- **Katman 1 (Gateway / Reverse Proxy):** Nginx Reverse Proxy (Dış dünyaya tek açık nokta: Port 19001).
- **Katman 2 (Uygulama Mantığı):** Python FastAPI mikroservisi (İş mantığı ve API uç noktaları).
- **Katman 3 (Veri ve Önbellek):** PostgreSQL 16 ve Redis 7 servisleri.
- **Çift Ağ İzolasyonu (DMZ Deseni):**
  - `public-net`: Yalnızca Nginx Gateway ve FastAPI servisleri bağlıdır.
  - `internal-net`: Yalnızca FastAPI, Redis ve PostgreSQL servisleri bağlıdır.
  - Veritabanı ve önbellek katmanı dış dünyaya tamamen kapatılarak doğrudan TCP erişimi engellenir.

---

## Ön Koşullar

- Docker Engine 24+ ve Docker Compose V2 (`docker compose version`).
- Host üzerinde `19001` portunun boşta olması.
- `curl` ve `jq` araçlarının kurulu olması.

---

## Mimari ve Çalışma Modeli

```text
                           İNTERNET / WEB TARAYICI
                                     │
                                Port: 19001
                                     ▼
+─────────────────────────────────────────────────────────────────────────────+
| PUBLIC NETWORK (Dışa Açık Ağ: public-net)                                   |
|                                                                             |
|  [ NGINX GATEWAY: compose-gateway ] (Port 19001)                            |
|                   │                                                         |
|                   │ proxy_pass http://api:8000/                             |
|                   ▼                                                         |
|  [ FASTAPI MİKROSERVİSİ: compose-api ]                                      |
+─────────────────────────────────────────────────────────────────────────────+
                    │
                    ▼ (İki Ağa da Bağlı Köprü)
+─────────────────────────────────────────────────────────────────────────────+
| INTERNAL NETWORK (İzole İç Ağ: internal-net - DIŞ DÜNYAYA TAMAMEN KAPALI!)   |
|                                                                             |
|                   │                                 │                       |
|                   ▼                                 ▼                       |
|  [ REDIS 7 ÖNBELLEK: compose-redis ]   [ POSTGRESQL 16: compose-postgres ]  |
|  - Sadece iç ağdan erişilebilir       - Sadece iç ağdan erişilebilir        |
|  - Healthcheck: redis-cli ping         - Healthcheck: pg_isready            |
+─────────────────────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Yapılandırmayı ve DMZ Ağlarını Doğrulama

`.env` dosyasını ve Compose dosyasındaki çift ağ tanımlarını inceleyin:

```bash
cat .env
docker compose config
```

### 2. Stack'i Derleyip Arka Planda Başlatma

API imajını derleyip tüm 4 servisi ayağa kaldırın:

```bash
docker compose up -d --build
```

### 3. Servislerin Sağlık Durumunu ve Konteynerları Doğrulama

PostgreSQL ve Redis servislerinin `healthy` duruma geçmesini ve API ile Gateway'in aktifleşmesini gözlemleyin:

```bash
docker compose ps
```

### 4. Otomasyon Test Betiğini Çalıştırma

Tüm katmanların (Gateway -> API -> Redis -> PostgreSQL) entegrasyon testlerini çalıştırın:

```bash
chmod +x test-stack.sh
./test-stack.sh
```

---

## Doğal Doğrulama ve Beklenen Sonuç

### 1. Sağlık Uç Noktası Kontrolü

```bash
curl -s http://localhost:19001/health
```

Beklenen çıktı:
```json
{"status": "healthy", "service": "ecommerce-api", "cache": "connected", "db": "connected"}
```

### 2. Ürün API ve Önbellek Doğrulaması

```bash
curl -s http://localhost:19001/api/v1/products
```

Beklenen çıktı:
```json
{"source": "database", "products": [{"id": 1, "name": "Laptop", "price": 1500.0}, ...]}
```

Aynı isteği tekrar attığınızda verinin Redis üzerinden geldiğini gözlemleyin:
```json
{"source": "cache", "products": [{"id": 1, "name": "Laptop", "price": 1500.0}, ...]}
```

### 3. Ağ İzolasyonu Doğrulaması

PostgreSQL (5432) portunun host üzerinden erişilemediğini teyit edin:

```bash
curl -m 2 http://localhost:5432 || echo "PostgreSQL portu dışarıya kapalı (DMZ Güvenliği Doğrulandı)"
```

---

## Temizlik

Test tamamlandıktan sonra tüm konteynerları, ağları ve Named Volume verilerini temizleyin:

```bash
docker compose down -v
```
