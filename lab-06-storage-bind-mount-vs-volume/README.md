# * LAB-06: Depolama Temelleri: Bind Mount vs Named Volume

> 📌 **Sunum Eşleşmesi:** Bu laboratuvar, **Slayt 67 (LAB — Docker Storage)** sonrasında sınıfla birlikte uygulanır.

## 🎯 Labın Amacı
Konteynerlerin geçici (ephemeral) yapısından kaynaklanan veri kaybı riskini gözlemlemek, geliştirme ortamları için **Bind Mount**, üretim ve veritabanı kalıcılığı için **Named Volume** ve hassas veriler için **tmpfs (RAM)** depolama yöntemlerini uygulamak.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **8082** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Ephemeral Katman: Volumesiz Konteynerde Veri Kaybı
```bash
# 1. Volume bağlamadan geçici bir Alpine konteyneri başlatın ve içine dosya yazın:
docker run --name temp-container alpine sh -c "echo 'Kritik DB Verisi' > /data.txt && cat /data.txt"

# 2. Konteyneri silin:
docker rm temp-container

# 3. Yeni bir konteyner başlatıp dosyayı arayın:
docker run --rm alpine cat /data.txt || echo 'VERİ KAYBOLDU: Volumesiz yazılan veriler konteynerle birlikte silinir'
```

### 2. Canlı Geliştirme İçin Bind Mount
Host üzerindeki bir yerel dizini doğrudan konteynere bağlayarak anında kod güncellemesi yapın:

```bash
# 1. Host üzerinde web dizini ve test sayfası oluşturun:
mkdir -p ./html
echo "<h1>Canlı Bind Mount Calisiyor</h1>" > ./html/index.html

# 2. Host dizinini Nginx kök dizinine bağlayarak başlatın:
docker run -d --name web-bind -p 8082:80 -v "$(pwd)/html:/usr/share/nginx/html:ro" nginx:alpine

# 3. Web sayfasını test edin:
curl http://localhost:8082

# 4. Konteyneri yeniden başlatmadan host üzerindeki dosyayı değiştirin:
echo '<h1>Hot-Reload: Kod Degisti</h1>' > ./html/index.html

# 5. Anında güncellendiğini doğrulayın:
curl http://localhost:8082
```

### 3. Üretim ve Veri Kalıcılığı İçin Named Volume
Docker tarafından `/var/lib/docker/volumes` altında yönetilen izole bir depolama alanı oluşturun:

```bash
# 1. Kalıcı bir Named Volume oluşturun:
docker volume create app_storage

# 2. Volume'ü bir konteynere bağlayın ve içine kalıcı veri yazın:
docker run --rm -v app_storage:/storage alpine sh -c "echo 'Kurtarilan Veri: 2026-09' > /storage/musteri.db"

# 3. Konteyner silinmiş olmasına rağmen volume'ün varlığını teyit edin:
docker volume ls | grep app_storage

# 4. Tamamen yeni bir konteyner açıp aynı volume'ü bağlayarak veriyi kurtarın:
docker run --rm -v app_storage:/recovery alpine cat /recovery/musteri.db
```

### 4. Bellek İçi Depolama (tmpfs)
Disk yerine doğrudan ana makinenin RAM'ini kullanarak çalışan ve diskte iz bırakmayan güvenli depolama:

```bash
docker run -d --name ram-app --tmpfs /ramdisk:rw,noexec,nosuid,size=64m alpine sleep 3600

# RAM disk boyutunu ve mount noktasını kontrol edin:
docker exec ram-app df -h /ramdisk
```

---

## ✅ Doğrulama (Verification)
- Bind mount testinde `curl http://localhost:8082` çıktısında `Hot-Reload: Kod Degisti` görülmelidir.
- Named volume testinde ikinci konteynerden `Kurtarilan Veri: 2026-09` başarıyla okunmalıdır.

---

## 🧹 Temizlik
```bash
docker rm -f web-bind ram-app 2>/dev/null || true
docker volume rm app_storage 2>/dev/null || true
rm -rf ./html
```
