# * LAB-DOC-12 — Docker Final Capstone Projesi: Üretim Seviyesi Güvenli Mikroservis Platformu

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Uzman | `docker compose`, Node.js, Postgres, Redis, Nginx, Secrets | 19001 (App1 Slotu) |

> **Önemli Erişim Notu:** Nginx Gateway, platform mimarisinde katılımcı web uygulamaları için ayrılmış olan **Port 19001 (App1 Slotu)** üzerinden dışa açılır. Tarayıcınızdan doğrudan `http://<SUNUCU-IP>:19001` (veya ters vekil üzerinden `https://studentXX-app1.<domain>`) adresiyle web arayüzüne ve API'ye erişebilir veya yerel olarak `curl http://localhost:19001/api/health` komutunu çalıştırabilirsiniz.
> 
> *Not: Sunucuda Port 80 ve 443 doğrudan ana Nginx Master Reverse Proxy tarafından kullanıldığından, port çakışmasını önlemek için Compose dosyasında dış port `19001` olarak tanımlanmıştır.*

---

## 1. Amaç

Bu bitirme projesinde (Capstone), Docker eğitim serisi boyunca öğrenilen tüm mimari ve operasyonel yetkinlikler tek bir kurumsal mimaride birleştirilir:

1. **Nginx Reverse Proxy Gateway:** Dış dünyaya tek giriş kapısı (Port 19001) ve mikroservislere yönlendirme.
2. **Hardened Backend REST API:** Non-root kullanıcı (UID 10001), layer cache optimizasyonu, CPU ve RAM sınırları (`cpus: 0.5`, `memory: 256M`).
3. **Docker Secrets Entegrasyonu:** Veritabanı şifresini ortam değişkeni olarak açıkta bırakmak yerine `/run/secrets/db_password` dosyasından okuma.
4. **PostgreSQL 16 & Otomatik Tablo Başlatma:** `init.sql` ile konteyner ilk açıldığında otomatik veritabanı şemasını kurma.
5. **Redis 7 Önbellekleme:** Hızlı sorgular için bellek içi önbellek.
6. **Çift Ağ İzolasyonu (DMZ Mimarisi):** Veritabanı ve Redis dış ağdan tamamen yalıtılmış `internal-net` üzerindedir.

---

## 2. Ön Koşullar

* Docker Engine ve Docker Compose V2 çalışır durumda olmalıdır.
* Platform üzerindeki App1 slotu (`19001`) boşta olmalıdır.
* Önceki tüm modüllerin (Dockerfile, Ağ, Depolama, Compose, Güvenlik) tamamlanmış olması.

---

## 3. Mimari ve Çalışma Modeli

```text
                           KULLANICI (Web Tarayıcı)
                                      │
                                 Port: 19001 (App1)
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

## 4. Görevler (Tasks)

1. **Mimari Dosyaları İnceleme:** `docker-compose.yaml`, `secrets/db_password.txt`, `gateway/nginx.conf` ve `init.sql` dosyalarını inceleyin.
2. **Platformu Derleme ve Başlatma:** `docker compose up -d --build` komutuyla platformu ayağa kaldırın.
3. **Servis Durumu ve Sağlık Denetimi:** `docker compose ps` komutunu çalıştırarak tüm servislerin (`postgres`, `redis`, `backend`, `gateway`) durumlarının `healthy` olduğunu doğrulayın.
4. **API ve Veritabanı Testi:** `curl http://localhost:19001/api/products` adresine istek atarak veritabanındaki 3 ürünün JSON olarak döndüğünü teyit edin.
5. **Kaynak Sınırları ve Güvenlik:** `docker inspect capstone-backend` ile CPU (`0.5`) ve RAM (`256MB`) sınırlarının devrede olduğunu, non-root kullanıcının çalıştığını kontrol edin.
6. **Ağ İzolasyonunu Kanıtlama:** Veritabanının (`capstone-postgres`) host üzerinde dışa açılmış hiçbir portu olmadığını teyit edin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Docker Secrets Neden Ortam Değişkeninden Üstündür?</summary>

`environment: [POSTGRES_PASSWORD=123]` şeklinde tanımlanan şifreler, `docker inspect` komutu çalıştırıldığında veya `docker exec env` dendiğinde düz metin (plain text) olarak görünür. `secrets` kullanıldığında ise şifre RAM üzerinde geçici bir dosyaya (`/run/secrets/`) mount edilir; `inspect` çıktısında asla görünmez.
</details>

<details>
<summary>💡 İpucu 2: deploy.resources.limits Mantığı</summary>

Compose V2'de `deploy.resources.limits` blokları `docker compose up` çalıştırıldığında doğrudan uygulanır. Bu sayede bir konteyner bellek sızıntısı yaşasa bile sunucudaki diğer konteynerları etkilemez.
</details>

<details>
<summary>💡 İpucu 3: depends_on condition: service_healthy</summary>

Compose içinde backend servisinin veritabanına bağlanabilmesi için PostgreSQL'in yalnızca portunun açılması yetmez; SQL sorgularını kabul edebilecek durumda (`pg_isready`) olması gerekir. `condition: service_healthy` direktifi yarış durumlarını (race condition) sıfırlar.
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Komutlar (Tıklayınca Açılır)</summary>

### Adım 1: Çalışma Dizinine Geçiş
```bash
cd 12-final-capstone-project
```

### Adım 2: Projeyi Derleme ve Başlatma
```bash
docker compose up -d --build
```

### Adım 3: Servis Sağlık Durumlarını Denetleme
```bash
docker compose ps
```

### Adım 4: Gateway ve REST API Doğrulama
```bash
# Gateway üzerinden sistem sağlık kontrolü
curl -i http://localhost:19001/api/health

# Veritabanından gelen ürün listesini çekme
curl -i http://localhost:19001/api/products
```

### Adım 5: Kaynak Limitlerini ve İzolasyonu İnceleme
```bash
# Backend kaynak sınırları
docker inspect capstone-backend | grep -E '"Memory"|"NanoCpus"'

# PostgreSQL port durumu (Host portu olmamalıdır)
docker port capstone-postgres
```

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutla mikroservis API'sinden dönen ürün listesini denetleyin:

```bash
curl -s http://localhost:19001/api/products
```

* **Beklenen JSON Çıktısı:**
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

## 8. Temizlik

Laboratuvar tamamlandığında tüm servisleri ve oluşturulan Named Volume veritabanını temizleyin:

```bash
docker compose down -v
```
