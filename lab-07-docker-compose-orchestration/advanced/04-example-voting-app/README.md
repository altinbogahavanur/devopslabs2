# LAB-DOC-07-04 (Advanced) — Çok Dilli (Multi-Polyglot) 5-Mikroservis Mimarisi (Example Voting App)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker compose`, Python, Node.js, .NET, Redis, Postgres | 5000 (Vote), 5001 (Result) |

---

## Amaç

Docker'ın ve mikroservis mimarisinin en büyük gücü **farklı programlama dillerini (Polyglot mimari)** aynı çatı altında, hiçbir bağımlılık çakışması yaşamadan birleştirebilmesidir.

Bu laboratuvarda resmi Docker referans mimarisi olan **Example Voting App** 5 mikroservis ile ayağa kaldırılır:

- **Python (`vote`):** Kullanıcının oy (Cats vs Dogs) verdiği ön yüz web uygulaması.
- **Redis (`redis`):** Gelen oyları sıraya alan (in-memory queue) yüksek hızlı bellek içi önbellek.
- **.NET (`worker`):** Oyları Redis kuyruğundan çekip PostgreSQL veritabanına kalıcı yazan arka plan işçisi.
- **PostgreSQL (`db`):** Oyların nihai saklandığı ilişkisel veritabanı (Kalıcı Named Volume).
- **Node.js (`result`):** Veritabanındaki sonuçları WebSocket (Socket.io) ile gerçek zamanlı tarayıcıya yansıtan sonuç ekranı.

---

## Ön Koşullar

- Docker Engine 24+ ve Docker Compose V2 (`docker compose version`).
- Host üzerinde `5000` ve `5001` portlarının boşta olması.
- `curl` yardımcı aracının kurulu olması.

---

## Mimari ve Çalışma Modeli

```text
                  KULLANICI (Oy Veren)                 KULLANICI (Sonuç İzleyen)
                           │                                       │
                      Port: 5000                              Port: 5001
                           ▼                                       ▼
                  +─────────────────+                     +─────────────────+
                  |  VOTE (Python)  |                     | RESULT (Node.js)|
                  +─────────────────+                     +─────────────────+
                           │                                       ▲
                   Oyu Kuyruğa Atar                                │ Canlı Sonuçları Okur
                           ▼                                       │
                  +─────────────────+                              │
                  |  REDIS (Kuyruk) |                              │
                  +─────────────────+                              │
                           │                                       │
                   Oyları Çeker                                    │
                           ▼                                       │
                  +─────────────────+                              │
                  |  WORKER (.NET)  | ─── Oyları DB'ye Yazar ──> +─────────────────+
                  +─────────────────+                           |  DB (Postgres)  |
                                                                +─────────────────+
                                                                         │
                                                                         ▼
                                                                  [ NAMED VOLUME ]
```

---

## Adım Adım Uygulama Rehberi

### 1. Yapılandırmayı ve Servisleri İnceleme

`docker-compose.yml` dosyasındaki 5 servisi, ağları ve Named Volume tanımını doğrulayın:

```bash
docker compose config
```

### 2. Stack'i Arka Planda Başlatma

5 mikroservisi birden ayağa kaldırın:

```bash
docker compose up -d
```

### 3. Servislerin Durumunu Doğrulama

Tüm konteynerların çalıştığını teyit edin:

```bash
docker compose ps
```

### 4. Worker Arka Plan Loglarını İzleme

Worker servisinin Redis ve PostgreSQL ile TCP üzerinden bağlantı kurduğunu gözlemleyin:

```bash
docker compose logs --tail=20 worker
```

---

## Doğal Doğrulama ve Beklenen Sonuç

### 1. Konteyner Durumlarını Doğrulama

```bash
docker compose ps
```

Beklenen çıktı:
```text
NAME                     IMAGE                                    COMMAND                  SERVICE   STATUS
04-example-voting-app-db-1       postgres:15-alpine                       "docker-entrypoint.s…"   db        Up (running)
04-example-voting-app-redis-1    redis:alpine                             "docker-entrypoint.s…"   redis     Up (running)
04-example-voting-app-result-1   dockersamples/examplevotingapp_result    "node server.js"         result    Up (running)
04-example-voting-app-vote-1     dockersamples/examplevotingapp_vote      "gunicorn app:app -b…"   vote      Up (running)
04-example-voting-app-worker-1   dockersamples/examplevotingapp_worker    "/entrypoint.sh"         worker    Up (running)
```

### 2. HTTP Uç Noktalarını Test Etme

Vote (5000) ve Result (5001) servislerinin yanıt verdiğini doğrulayın:

```bash
curl -I http://localhost:5000
curl -I http://localhost:5001
```

Beklenen HTTP yanıtları:
```text
HTTP/1.1 200 OK
```

---

## Temizlik

Test tamamlandıktan sonra tüm konteynerları, ağları ve Named Volume'u temizleyin:

```bash
docker compose down -v
```
