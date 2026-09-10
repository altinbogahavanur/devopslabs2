# LAB-08 — Docker Compose Mimarileri ve Orkestrasyon (Docker Compose Stacks)

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri | 60 dakika | `docker compose v2`, `nginx`, `redis`, `postgres` | `80, 8080, 5000` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 74-85, Lab 6); çoklu konteyner mimarilerinin (Multi-Container Stacks) Docker Compose V2 kullanılarak tek bir bildirimsel YAML dosyası ile nasıl yönetildiğini, servisler arası sağlık kontrollerini (`depends_on: condition: service_healthy`), ağ izolasyonunu ve felaket kurtarma süreçlerini kavramaktır:

1. **Bildirimsel Tanımlama:** Çoklu servisleri, ağları ve volume'ları tek dosyada yönetmek.
2. **Sağlık Kontrolleri:** Servislerin doğru sıralamayla açılmasını sağlamak (`service_healthy`).
3. **Çoklu Ağ İzolasyonu:** DMZ ve veritabanı ağlarını ayırarak mimari güvenlik sağlamak.
4. **Ortam Profilleri:** Geliştirme ve üretim ortamlarını `profiles` ile tek Compose dosyasında yönetmek.

---

## 2. Ön Koşullar

* Docker Engine ve Docker Compose V2 kurulu ve çalışır durumda olmalıdır (`docker compose version`).
* Host üzerinde `80`, `8080` portları boşta olmalıdır.

---

## 3. Laboratuvar Listesi ve Mimari Kapsam

| No | Klasör | Senaryo | Öne Çıkan Mimari Yetkinlikler |
|:---:|:---|:---|:---|
| **01** | [`01-compose-fundamentals`](01-compose-fundamentals/README.md) | **Compose V2 Temelleri** | `services`, `networks`, `volumes`, `.env` yönetimi, `service_healthy` |
| **02** | [`02-wordpress-mysql`](02-wordpress-mysql/README.md) | **WordPress + MySQL Stack** | Lab 06'daki manuel CLI operasyonunun tek komutluk bildirimsel otomasyonu |
| **03** | [`03-3tier-web-api-db`](03-3tier-web-api-db/README.md) | **3-Tier Kurumsal Mimari** | Nginx Gateway (Port 80) + FastAPI + Redis 7 + PostgreSQL 16, **Çift Ağ (DMZ) İzolasyonu** |
| **04** | [`04-example-voting-app`](04-example-voting-app/README.md) | **Çok Dilli (Polyglot) Mikroservis** | Python (`vote`), Node.js (`result`), .NET (`worker`), Redis ve PostgreSQL |
| **05** | [`05-final-capstone`](05-final-capstone/README.md) | **Final Capstone Projesi** | Nginx + Hardened API + Postgres + **Docker Secrets** + CPU/RAM limitleri |
| **06** | [`06-compose-profiles-and-overrides`](06-compose-profiles-and-overrides/README.md) | **Çoklu Ortam & Profiller** | `profiles: [debug, tools]`, Dev vs Prod katmanları (`compose.prod.yaml`) |

---

## 4. Görevler (Tasks)

1. **Sözdizimi Doğrulama:** `01-compose-fundamentals` klasöründeki `docker-compose.yaml` dosyasını `docker compose config` ile derleyin ve doğrulayın.
2. **Stack Başlatma:** `docker compose up -d` komutu ile tüm stack'i tek adımda ayağa kaldırın.
3. **Dahili DNS ve İletişim:** Konteynerların birbirine servis isimleriyle erişebildiğini test edin.
4. **Volume Kalıcılık Farkı:** `docker compose down` ile kapatıldığında verinin korunduğunu, `docker compose down -v` ile kapatıldığında Named Volume'un da silindiğini gözlemleyin.
5. **3-Tier Stack Testi:** `03-3tier-web-api-db` mimarisini ayağa kaldırıp Nginx üzerinden API ve Redis bağlantısını teyit edin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: down vs down -v Arasındaki Hayati Fark</summary>

`docker compose down` servisleri ve ağları durdurup siler ancak veritabanı volume'larına (Named Volumes) **asla dokunmaz**. Eğer `-v` (`--volumes`) bayrağı eklenirse veritabanı diski de kalıcı olarak silinir. Üretimde `-v` bayrağı asla bilinçsizce kullanılmamalıdır!
</details>

<details>
<summary>💡 İpucu 2: docker compose config Neden Kullanılır?</summary>

`docker compose config` komutu ortam değişkenlerini (`.env`), kalıtım (`extends`) kurallarını ve override dosyalarını birleştirerek Docker Engine'e gönderilecek nihai birleşik YAML çıktısını ekrana basar. Sözdizimi hatalarını çalıştırmadan önce yakalar.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla çalışan compose servislerini ve port eşlemelerini teyit edin:

```bash
docker compose ps --format "table {{.Name}}\t{{.Service}}\t{{.Status}}\t{{.Ports}}"
```

* **Beklenen Başarı Çıktısı:**
  * Tüm servislerin durum sütununda `Up` veya `Up (healthy)` yazmalıdır.

---

## 7. Temizlik

Çalıştırılan stack'leri temizleyin:

```bash
docker compose down -v 2>/dev/null || true
```
