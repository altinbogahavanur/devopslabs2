# * LAB-12: Felaket Kurtarma: İmaj ve Volume Yedekleme (Disaster Recovery)

## 🎯 Labın Amacı
İnternetsiz (air-gapped) ortamlara imaj taşımak için `docker save` ve `docker load` komutlarını kullanmak; üretim ortamında veri kaybını önlemek amacıyla geçici bir yardımcı (helper) konteyner ile Docker Named Volume'lerini sıkıştırılmış `.tar.gz` olarak yedeklemek ve sıfırdan geri yüklemek.

## 📋 Ön Koşullar
- Docker Engine çalışır durumda olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. İmajları Arşivleme ve Geri Yükleme (save / load)
```bash
# 1. Mevcut bir imajı diske tar arşivi olarak kaydedin:
docker pull alpine:3.20
docker save -o /tmp/alpine-backup.tar alpine:3.20

# 2. İmajı yerel Docker motorundan tamamen silin:
docker rmi alpine:3.20

# 3. İmajı arşiv dosyasından tüm katmanlarıyla geri yükleyin:
docker load -i /tmp/alpine-backup.tar

# Doğrulama:
docker images | grep alpine
```

### 2. Volume Verisini Yedekleme (Alpine Helper Pattern)
Çalışan bir veritabanı veya uygulamanın volume içeriğini ana makineye `.tar.gz` olarak çekin:

```bash
# 1. Test verisi barındıran bir volume oluşturun:
docker volume create prod-database
docker run --rm -v prod-database:/data alpine sh -c "echo 'Kritik Siparis Tablosu: 2026' > /data/orders.sql"

# 2. Yardımcı Alpine konteyneri bağlayarak salt-okunur (ro) yedeği alın:
mkdir -p /tmp/backups
docker run --rm \
  -v prod-database:/source:ro \
  -v /tmp/backups:/target \
  alpine tar -czf /target/prod-database-backup.tar.gz -C /source .

# Yedek dosyasını denetleyin:
ls -lh /tmp/backups/prod-database-backup.tar.gz
```

### 3. Felaket Simülasyonu: Orijinal Volume'ü Silme
```bash
# Volume'ü tamamen yok edin:
docker volume rm prod-database
```

### 4. Sıfırdan Geri Yükleme (Disaster Recovery)
```bash
# 1. Yeni bir kurtarma volume'ü oluşturun:
docker volume create recovered-database

# 2. Yedek arşivini yeni volume içine açın:
docker run --rm \
  -v recovered-database:/target \
  -v /tmp/backups:/source \
  alpine tar -xzf /source/prod-database-backup.tar.gz -C /target

# 3. Yeni bir konteyner bağlayıp verinin kurtarıldığını test edin:
docker run --rm -v recovered-database:/data alpine cat /data/orders.sql
```

---

## ✅ Doğrulama (Verification)
- `docker run --rm -v recovered-database:/data alpine cat /data/orders.sql` komutunun `Kritik Siparis Tablosu: 2026` çıktısını eksiksiz verdiğini teyit edin.

---

## 🧹 Temizlik
```bash
docker volume rm recovered-database 2>/dev/null || true
rm -rf /tmp/alpine-backup.tar /tmp/backups
```
