# LAB-07-04 — Çok Dilli (Multi-Polyglot) 5-Mikroservis Mimarisi (Example Voting App)

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri | 45 dakika | `docker compose`, Python, Node.js, .NET, Redis, Postgres | `5000, 5001` |

---

## 1. Amaç

Docker'ın ve mikroservis dünyasının en büyük gücü **farklı programlama dillerini (Polyglot mimari)** aynı çatı altında, hiçbir bağımlılık çakışması yaşamadan birleştirebilmesidir.

Bu laboratuvarda Docker topluluğunun resmi referans projesi olan **Example Voting App** ayağa kaldırılacaktır:
1. **Python (`vote`):** Kullanıcının oy (Kedi vs Köpek) verdiği ön yüz web uygulaması.
2. **Redis (`redis`):** Gelen oyları sıraya alan (queue) yüksek hızlı bellek içi önbellek.
3. **.NET (`worker`):** Oyları Redis kuyruğundan çekip PostgreSQL veritabanına kalıcı yazan arka plan işçisi (background worker).
4. **PostgreSQL (`db`):** Oyların nihai saklandığı ilişkisel veritabanı (Kalıcı Named Volume).
5. **Node.js (`result`):** Veritabanındaki sonuçları WebSocket (Socket.io) ile gerçek zamanlı tarayıcıya yansıtan sonuç ekranı.

---

## 2. Mikroservis Veri Akış Mimarisi

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

## 3. Görevler (Tasks)

1. Klasör içerisindeki `docker-compose.yml` dosyasını ve servis yapılarını inceleyin.
2. `docker compose up -d` komutuyla 5 servisi birden ayağa kaldırın.
3. `docker compose ps` komutuyla tüm servislerin `running` olduğunu teyit edin.
4. Web tarayıcınızda `http://localhost:5000` adresine giderek bir oy verin.
5. Yeni bir sekmede `http://localhost:5001` adresine giderek verdiğiniz oyun gerçek zamanlı olarak yüzdelere yansıdığını gözlemleyin.
6. Test bittikten sonra `docker compose down -v` ile ortamı temizleyin.

---

## Adım Adım Uygulama ve Doğrulama

```bash
# 1. Stack'i derleyip başlatma
docker compose up -d

# 2. Çalışan servisleri listeleme
docker compose ps

# 3. Logları canlı izleme (Özellikle worker akışını görmek için)
docker compose logs -f worker

# 4. Temizlik
docker compose down -v
```

---

## Beklenen Sonuç ve Doğrulama

```bash
curl -I http://localhost:5000
curl -I http://localhost:5001
```

* **Vote Uygulaması:** `HTTP/1.1 200 OK` (Port 5000)
* **Result Uygulaması:** `HTTP/1.1 200 OK` (Port 5001)
