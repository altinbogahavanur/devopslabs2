# LAB-08 — Docker Compose Mimarileri ve Orkestrasyon (Docker Compose Stacks)

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri | 60 dakika | `docker compose v2`, `nginx`, `redis`, `postgres` | `80, 8080, 5000` |

---

## Laboratuvar Listesi

| No | Klasör | Senaryo | Öne Çıkan Mimari Yetkinlikler |
|:---:|:---|:---|:---|
| **01** | [`01-compose-fundamentals`](01-compose-fundamentals/README.md) | Compose V2 Temelleri | `services`, `networks`, `volumes`, `.env` yönetimi, `service_healthy` |
| **02** | [`02-wordpress-mysql`](02-wordpress-mysql/README.md) | WordPress + MySQL Stack | Tek komutluk bildirimsel veritabanı ve web uygulaması |
| **03** | [`03-3tier-web-api-db`](03-3tier-web-api-db/README.md) | 3-Tier Kurumsal Mimari | Nginx Gateway (Port 80) + FastAPI + Redis 7 + PostgreSQL 16 |
| **04** | [`04-example-voting-app`](04-example-voting-app/README.md) | Çok Dilli (Polyglot) Mikroservis | Python (`vote`), Node.js (`result`), .NET (`worker`), Redis ve PostgreSQL |
| **05** | [`05-final-capstone`](05-final-capstone/README.md) | Final Capstone Projesi | Nginx + Hardened API + Postgres + Docker Secrets + CPU/RAM limitleri |
| **06** | [`06-compose-profiles-and-overrides`](06-compose-profiles-and-overrides/README.md) | Çoklu Ortam & Profiller | `profiles: [debug, tools]`, Dev vs Prod katmanları (`compose.prod.yaml`) |

---

## Adım Adım Uygulama

### Adım 1: Compose Fundamentals Stack'ini Başlatma

```bash
cd 01-compose-fundamentals

# 1. YAML sözdizimini ve değişkenleri denetleme
docker compose config

# 2. Servisleri arka planda ayağa kaldırma
docker compose up -d

# 3. Çalışan servisleri ve portları listeleme
docker compose ps

# 4. Servis loglarını canlı izleme
docker compose logs --tail=20

cd ..
```

---

### Adım 2: 3-Tier Web-API-DB Mimarisini Başlatma

```bash
cd 03-3tier-web-api-db

# Stack'i derleyip başlatma
docker compose up -d --build

# Servis sağlık durumlarını denetleme
docker compose ps

# Nginx Gateway üzerinden API yanıtını test etme
curl -i http://localhost/health

cd ..
```

---

### Adım 3: Stack Kapatma ve Veri Yönetimi

```bash
# Sadece servisleri ve ağları durdurup siler; Named Volume verilerini korur:
docker compose down

# Veritabanı disklerini de kalıcı olarak sıfırlamak istendiğinde:
docker compose down -v
```

---

## Temizlik

Çalıştırılan compose servislerini ve disklerini temizleyin:

```bash
cd 01-compose-fundamentals && docker compose down -v 2>/dev/null || true
cd ../03-3tier-web-api-db && docker compose down -v 2>/dev/null || true
```
