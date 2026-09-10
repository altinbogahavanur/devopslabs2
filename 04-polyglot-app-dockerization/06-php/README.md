# LAB-05-06 — PHP 8.3 Uygulamasını Composer ve OPcache ile Dockerize Etme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 35 dakika | `php:8.3-cli-alpine`, `composer:2`, `curl` | `8000` |

---

## 1. Uygulama Hakkında

PHP dünyasında web uygulamaları ve mikroservisler Composer paket yöneticisi ve OPcache optimizasyonları ile çalıştırılır.

PHP'yi Dockerize ederken:
* Composer ikili aracını (`composer:2`) doğrudan resmi builder imajından çekmek (Multi-stage),
* Geliştirme araçlarını dışarıda tutarak autoloader'ı optimize etmek (`composer install --no-dev --optimize-autoloader`),
* PHP yerleşik OPcache eklentisini aktif ederek bytecode önbelleklemesi sağlamak,
* `www-data` gibi yetkisiz kullanıcı ile çalıştırmak esastır.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Kurulum ve Çalıştırma

Dockerfile direktiflerini kurgulamak için referans Linux çalıştırma adımları:

```bash
# 1. PHP 8.3 ve Composer kurulumu
sudo apt update && sudo apt install -y php8.3-cli php8.3-opcache composer

# 2. Çalışma dizini ve kodların yerleşimi
mkdir -p /var/www/html && cd /var/www/html
cp -r /path/to/source/* /var/www/html/

# 3. YALNIZCA üretim bağımlılıklarının optimize kurulması
composer install --no-dev --optimize-autoloader --no-interaction

# 4. Standart www-data kullanıcısı ile web sunucusunun başlatılması
php -S 0.0.0.0:8000 -t public/
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| Composer Kurulumu | `COPY --from=composer:2 /usr/bin/composer /usr/bin/composer` | Composer'ı sıfırdan kurmak yerine resmi imajdan alma |
| PHP 8.3 Kurulumu | `FROM php:8.3-cli-alpine` | Hafif Alpine tabanlı PHP motoru |
| OPcache Aktifleştirme | `RUN docker-php-ext-install opcache` | Bytecode önbelleklemesi ile 3-5 kat hız artışı |
| Bağımlılık Yükleme | `RUN composer install --no-dev -o` | Dev paketleri atlanır, sınıf haritası derlenir |
| İzinler ve Kullanıcı | `USER www-data` | Web sunucusu güvenlik kullanıcısı |
| Başlatma | `CMD ["php", "-S", "0.0.0.0:8000", "-t", "public"]` | Dahili web sunucusu veya FPM |

---

## 4. Adım Adım Uygulama ve Doğrulama

**`Dockerfile`:**
```dockerfile
FROM php:8.3-cli-alpine

WORKDIR /var/www/html

# 1. OPcache eklentisini kurma
RUN docker-php-ext-install opcache

# 2. Composer ikili aracını resmi imajdan kopyalama (Multi-stage pattern)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 3. Bağımlılık dosyasını kopyalama ve yükleme
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# 4. Kaynak kodları kopyalama
COPY . .

# 5. İzinleri www-data kullanıcısına verme
RUN chown -R www-data:www-data /var/www/html
USER www-data

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public/"]
```

**Derleme ve Çalıştırma:**
```bash
# 1. İmajı derleme
docker build -t php-devops-api:v1.0 .

# 2. Konteynerı başlatma
docker run -d --name my-php-app -p 8000:8000 php-devops-api:v1.0

# 3. Test etme
curl -i http://localhost:8000/health
```

---

## 5. Beklenen Sonuç ve Doğrulama

```bash
curl -s http://localhost:8000/
```

* **JSON Çıktısı:**
```json
{
  "message": "PHP 8.3 Web API Basariyla Calisiyor!",
  "php_version": "8.3...",
  "sapi": "cli-server",
  "opcache_enabled": true,
  "timestamp": "..."
}
```
