# * LAB-08: Docker Compose ile 3-Tier Mimari: Frontend, Backend, Database, Network ve Volume

## 🎯 Labın Amacı
Docker Compose ile modern bir kurumsal mikroservis yığınını (Stack) tek bir deklaratif dosya üzerinden ayağa kaldırmak; **Frontend**, **Backend**, **Database**, **İzole Ağlar (Network Segregation)** ve **Kalıcı Depolama (Named Volume)** bileşenlerini uygulamalı olarak kavramak.

## 📋 Ön Koşullar & Portlar
- Docker Engine ve Docker Compose v2 (`docker compose version`).
- Host üzerinde **19001** (veya `.env` dosyasında belirleyeceğiniz) port boşta olmalıdır.

---

## 🏛️ Mimari ve Çalışma Modeli

Bu laboratuvarda kurulan sistem 4 konteyner, 2 izole ağ ve 1 kalıcı disk biriminden oluşur:

```text
[İNTERNET / KULLANICI]
         │ (HTTP İstekleri: Port 19001)
         ▼
 ┌────────────────────────────────────────────────────────┐
 │ PUBLIC-NET (compose_public_net)                        │
 │                                                        │
 │  ┌──────────────────────┐    ┌──────────────────────┐  │
 │  │ FRONTEND (Nginx)     │───>│ BACKEND (FastAPI/API)│  │
 │  │ Port: 19001:80       │    │ Port: İzole          │  │
 │  └──────────────────────┘    └──────────┬───────────┘  │
 └─────────────────────────────────────────┼──────────────┘
                                           │ (İç Veri Trafiği)
 ┌─────────────────────────────────────────┼──────────────┐
 │ INTERNAL-NET (compose_internal_net)     ▼              │
 │                              ┌──────────────────────┐  │
 │                              │ CACHE (Redis:7.4)    │  │
 │                              └──────────────────────┘  │
 │                              ┌──────────────────────┐  │
 │                              │ DATABASE (Postgres)  │  │
 │                              │  [NAMED VOLUME]      │  │
 │                              │  compose_product_data│  │
 │                              └──────────────────────┘  │
 └────────────────────────────────────────────────────────┘
```

### 🛡️ Güvenlik Kuralı (Ağ Segmentasyonu):
- **Frontend** sadece `public-net` üzerindedir. Veritabanına doğrudan ASLA erişemez (erişim denendiğinde engellenir).
- **Backend** her iki ağa da bağlıdır (`public-net` ve `internal-net`). Frontend'den gelen istekleri karşılar, veritabanına sorar ve yanıtı döner.
- **Database ve Redis** sadece `internal-net` üzerindedir. Dış dünyaya ve Frontend'e kapalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Çalışma Dizinine Geçiş ve Dosyaları İnceleme
```bash
cd lab-08-docker-compose-stack/03-3tier-web-api-db

# docker-compose.yaml dosyasındaki services, networks ve volumes bloklarını inceleyin:
cat docker-compose.yaml
```

**Bileşenlerin Analizi:**
1. `services.gateway`: **Frontend** (Nginx ters proxy). Port `19001` üzerinden dış dünyayı dinler.
2. `services.api`: **Backend** (Python FastAPI). Veri işleme katmanıdır.
3. `services.db`: **Database** (PostgreSQL). Verilerin kalıcı tutulduğu yerdir.
4. `services.cache`: **Cache** (Redis). Hızlı önbellek katmanıdır.
5. `networks`: `public-net` (Dış ağ) ve `internal-net` (İç güvenli ağ).
6. `volumes`: `postgres_data` (Kalıcı veri diski).

---

### 2. Stack'i Başlatma ve Sıralı Açılışı İzleme
Veritabanı hazır olmadan backend'in başlamaması için `depends_on: condition: service_healthy` kuralı devrededir:

```bash
# Tüm servisleri arka planda derleyip başlatın:
docker compose up -d --build

# Konteynerlerin sağlık durumlarını (healthy) izleyin:
docker compose ps
```
*Gözlem: `compose-postgres` ve `compose-redis` konteynerleri `healthy` durumuna geldikten sonra `compose-api` ve `compose-gateway` başlar.*

---

### 3. Fonksiyonel Test: Veri Ekleme ve Okuma
Hazır test betiğini çalıştırarak tüm zincirin çalıştığını doğrulayın:

```bash
bash test-stack.sh
```

**Manuel Adımlar:**
```bash
# 1. Frontend Gateway üzerinden yeni ürün ekleyin (Veritabanına yazılır):
curl -X POST "http://localhost:19001/products?title=DevOps%20Kitabi&price=450"

# 2. Ürünleri listeleyin (İlk istek doğrudan PostgreSQL'den okunur):
curl http://localhost:19001/products

# 3. İkinci kez listeleyin (Redis cache devreye girer ve anında yanıt döner):
curl http://localhost:19001/products
```

---

### 4. Network İzolasyonu Testi (Frontend -> DB Erişilemezlik Kanıtı)
Frontend konteynerinin doğrudan veritabanına ulaşamadığını test edin:

```bash
# Gateway (Nginx) içinden DB konteynerine ping atmayı deneyin:
docker compose exec gateway ping -c 2 compose-postgres || echo 'GÜVENLİK KANITI: Gateway veritabanına erişemez, ağlar izoledir'
```

---

### 5. Volume Veri Kalıcılığı Testi (Disaster Test)
Konteynerler tamamen silinse bile `postgres_data` Named Volume sayesinde verilerin kaybolmadığını kanıtlayın:

```bash
# 1. Konteynerleri durdurun ve silin (Volume'e DOKUNMADAN):
docker compose down

# 2. Konteynerler yokken volume'ün diskte durduğunu teyit edin:
docker volume ls | grep compose_product_data

# 3. Stack'i tekrar ayağa kaldırın:
docker compose up -d

# 4. Daha önce eklediğimiz ürünün veritabanında durduğunu teyit edin:
sleep 5
curl http://localhost:19001/products
# Eklenen 'DevOps Kitabi' eksiksiz geri gelecektir!
```

---

## ✅ Doğrulama (Verification)
- `docker compose ps` komutunda 4 servisin de çalıştığını görün.
- `docker volume ls` çıktısında `compose_product_data` Named Volume'ünün varlığını teyit edin.
- `docker network ls` çıktısında `compose_public_net` ve `compose_internal_net` köprülerinin oluştuğunu görün.

---

## 🧹 Temizlik
```bash
# Hem servisleri hem de kalıcı volume'leri tamamen temizlemek için:
docker compose down -v
```
