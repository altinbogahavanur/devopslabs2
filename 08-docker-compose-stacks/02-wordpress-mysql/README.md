# LAB-07-02 — WordPress + MySQL Stack'inin Docker Compose ile Otomasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 30 dakika | `docker compose`, `mysql:8.0`, `wordpress:6-apache` | `8080` |

---

## 1. Amaç

Lab 06'da saf Docker CLI komutlarıyla (network oluşturma, volume oluşturma, uzun `docker run` bayrakları yazma) kurduğumuz WordPress ve MySQL mimarisini, **tek bir bildirimsel `docker-compose.yaml` ve `.env` dosyası** ile saniyeler içinde otomatik ayağa kaldırmak ve yönetmektir:

* Manuel 15 komut yerine tek komut: `docker compose up -d`
* `.env` üzerinden şifre ve ortam değişkeni izolasyonu
* MySQL için `mysqladmin ping` tabanlı sağlık kontrolü
* WordPress'in MySQL `healthy` olmadan başlamasını engelleyen `depends_on` mekanizması

---

## 2. Mimari Karşılaştırması

```text
MANUEL CLI (Lab 06 - 15 Komut):
[docker network create] ➔ [docker volume create x2] ➔ [docker run mysql] ➔ [docker run wp]

DOCKER COMPOSE (Lab 07-02 - Tek Komut):
docker compose up -d
     │
     ├──> compose-wp-net (Bridge Ağı)
     ├──> compose-wp-db-data & compose-wp-site-data (Kalıcı Volumeler)
     ├──> compose-wp-db (MySQL 8.0 - Healthcheck devrede)
     └──> compose-wp-app (WordPress 6 - db:healthy bekler)
```

---

## 3. Görevler (Tasks)

1. `docker-compose.yaml` ve `.env` dosyalarındaki değişken eşleşmelerini inceleyin.
2. `docker compose up -d` komutuyla stack'i başlatın.
3. `docker compose ps` ile MySQL'in `healthy` olmasını ve WordPress'in hazır duruma geçmesini gözlemleyin.
4. Tarayıcınızda `http://localhost:8080` adresine giderek WordPress kurulum ekranının geldiğini teyit edin.
5. `docker compose logs -f wordpress` ile web sunucusu istek loglarını canlı izleyin.
6. Test bittikten sonra `docker compose down -v` ile tüm kaynakları temizleyin.

---

## 4. İpuçları

<details>
<summary>💡 İpucu 1: WORDPRESS_DB_HOST Değeri</summary>

Compose içinde servis adı `db` olarak tanımlandığı için, WordPress ortam değişkeni doğrudan `WORDPRESS_DB_HOST: db:3306` olur. Docker Compose otomatik olarak servis adını dahili DNS'e kaydeder.
</details>

<details>
<summary>💡 İpucu 2: Tek Bir Servisi Yeniden Başlatma</summary>

Tüm stack'i durdurup açmak yerine sadece WordPress servisini yeniden başlatmak için `docker compose restart wordpress` komutu yeterlidir.
</details>

---

## 5. Referans Çözüm

<details>
<summary>🎯 Referans Komutlar ve Doğrulama</summary>

```bash
# 1. Stack'i başlatma
docker compose up -d

# 2. Durumu kontrol etme
docker compose ps

# 3. HTTP başlığını doğrulama
curl -I http://localhost:8080/wp-admin/install.php

# 4. Temizlik
docker compose down -v
```

**Beklenen Çıktı:**
```text
NAME             IMAGE               STATUS
compose-wp-app   wordpress:6-apache  running
compose-wp-db    mysql:8.0           running (healthy)
```
</details>

---

## 6. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:8080/wp-admin/install.php | grep -i "WordPress"
```

* **HTTP Kodu:** `200 OK`
