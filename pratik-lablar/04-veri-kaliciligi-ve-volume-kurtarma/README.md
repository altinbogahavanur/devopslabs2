# Pratik Lab 04: Docker Veri Kalıcılığı — Ephemeral (Geçici) vs Named Volume ile MySQL Kurtarma

Bu pratik laboratuvarda, Docker konteynerlerinin neden varsayılan olarak "uçucu" (ephemeral) olduğunu, disk birimi (volume) olmadan çalışan bir veritabanı silindiğinde verilerin nasıl kaybolduğunu ve **Named Volume** kullanarak konteyner silinse bile verilerin nasıl %100 kurtarıldığını test edeceksiniz.

---

## Deney 1: Volumesiz Konteyner (Acı Tecrübe — Veri Kaybı)

### Adım 1: Disksiz Bir MySQL Konteyneri Başlatalım
```bash
docker run -d --name mysql-gecici \
  -e MYSQL_ROOT_PASSWORD=DevOps123! \
  mysql:8.0

# MySQL'in hazır olmasını bekleyin (yaklaşık 15-20 saniye):
sleep 15
docker logs mysql-gecici | grep -i "ready for connections"
```

### Adım 2: MySQL İçinde Veritabanı ve Tablo Oluşturalım
Konteynerin içine girmeden `docker exec -i` ile SQL komutları gönderelim:
```bash
docker exec -i mysql-gecici mysql -u root -pDevOps123! << 'EOF'
CREATE DATABASE magaza;
USE magaza;
CREATE TABLE urunler (id INT AUTO_INCREMENT PRIMARY KEY, ad VARCHAR(50), fiyat DECIMAL(10,2));
INSERT INTO urunler (ad, fiyat) VALUES ('Laptop', 25000.00), ('Mekanik Klavye', 1500.00);
SELECT * FROM urunler;
EOF
```
* Ekranda `Laptop` ve `Mekanik Klavye` kayıtlarını gördünüz.

### Adım 3: Konteyneri Silelim (Simüle Edilmiş Kaza / Çökme)
```bash
docker rm -f mysql-gecici
```

### Adım 4: Yepyeni Bir Konteyner Başlatalım ve Veriyi Arayalım
```bash
docker run -d --name mysql-yeni \
  -e MYSQL_ROOT_PASSWORD=DevOps123! \
  mysql:8.0

sleep 15
docker exec -i mysql-yeni mysql -u root -pDevOps123! -e "SHOW DATABASES;"
```
* **Sonuç:** `magaza` veritabanı **yok oldu!** Konteyner silinince konteyner katmanındaki (writable layer) tüm veriler geri dönülemez şekilde silindi.
* Temizlik:
```bash
docker rm -f mysql-yeni
```

---

## Deney 2: Named Volume ile Veri Kalıcılığı (DevOps Çözümü)

### Adım 1: Kalıcı Bir Docker Volume Oluşturalım
```bash
docker volume create mysql-kalici-veri
docker volume inspect mysql-kalici-veri
```
* `Mountpoint` kısmında diskin ana makinedeki fiziksel yerini inceleyin.

### Adım 2: MySQL'i Volume İle Başlatalım
MySQL veritabanı dosyalarını `/var/lib/mysql` dizininde saklar. Bu dizini oluşturduğumuz volume'a bağlıyoruz (`-v`):
```bash
docker run -d --name mysql-guvenli \
  -e MYSQL_ROOT_PASSWORD=DevOps123! \
  -v mysql-kalici-veri:/var/lib/mysql \
  mysql:8.0

sleep 15
docker logs mysql-guvenli | grep -i "ready for connections"
```

### Adım 3: Veritabanı ve Tablomuzu Oluşturalım
```bash
docker exec -i mysql-guvenli mysql -u root -pDevOps123! << 'EOF'
CREATE DATABASE sirket_db;
USE sirket_db;
CREATE TABLE musteriler (id INT AUTO_INCREMENT PRIMARY KEY, isim VARCHAR(50), bakiye INT);
INSERT INTO musteriler (isim, bakiye) VALUES ('Ahmet Yilmaz', 5000), ('Ayse Demir', 8500);
SELECT * FROM musteriler;
EOF
```

### Adım 4: Acımasız Konteyner Katliamı
Çalışan konteyneri zorla silelim:
```bash
docker rm -f mysql-guvenli
```
* Şu an çalışan hiçbir MySQL konteyneri yok!

### Adım 5: Kurtarma Operasyonu (Aynı Volume ile Yeni Konteyner)
Yepyeni bir konteyneri (`mysql-kurtarilan`) aynı `mysql-kalici-veri` volume'u ile başlatın:
```bash
docker run -d --name mysql-kurtarilan \
  -e MYSQL_ROOT_PASSWORD=DevOps123! \
  -v mysql-kalici-veri:/var/lib/mysql \
  mysql:8.0

sleep 10
```

### Adım 6: Verinin Korunduğunu Doğrulayalım
```bash
docker exec -i mysql-kurtarilan mysql -u root -pDevOps123! -e "SELECT * FROM sirket_db.musteriler;"
```
* **Çıktı:**
  ```text
  +----+--------------+---------+
  | id | isim         | bakiye  |
  +----+--------------+---------+
  |  1 | Ahmet Yilmaz |    5000 |
  |  2 | Ayse Demir   |    8500 |
  +----+--------------+---------+
  ```
* **Ders:** Konteyner öldü ama veriler diske kazındığı için hiçbir kayıp yaşanmadı!

---

## 3. Temizlik

```bash
docker rm -f mysql-kurtarilan
docker volume rm mysql-kalici-veri
```
