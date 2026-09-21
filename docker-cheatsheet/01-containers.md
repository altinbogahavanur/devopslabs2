# 📦 Docker Konteyner Yönetimi Komutları (Container Cheatsheet)

Konteynerlerin yaşam döngüsünü başlatma, durdurma, canlı hata ayıklama ve kaynak izleme komutları.

---

## 1. Konteyner Başlatma ve Çalıştırma (`docker run`)

Yeni bir imajdan izole bir konteyner oluşturur ve başlatır.

### En Sık Kullanılan Temel Başlatma
```bash
docker run -d --name web-server -p 8080:80 nginx:alpine
```
* **Açıklama:** `nginx:alpine` imajını arka planda (`-d`), `web-server` adıyla ve sunucunun 8080 portunu konteynerin 80 portuna bağlayarak çalıştırır.

### Etkileşimli Terminal ile Çalıştırma
```bash
docker run -it --rm ubuntu:24.04 bash
```
* **Açıklama:** Terminali doğrudan konteynerin içine bağlar (`-it`). Konteynerden çıkıldığında (`exit`) konteyneri otomatik siler (`--rm`).

### Ortam Değişkeni (Environment Variable) Tanımlama
```bash
docker run -d --name my-db -e POSTGRES_PASSWORD=secret123 postgres:16-alpine
```
* **Açıklama:** `-e` parametresiyle konteyner içine ortam değişkeni enjekte eder.

### Otomatik Yeniden Başlatma (Restart Policy)
```bash
docker run -d --name critical-api --restart always -p 3000:3000 my-api:1.0
```
* **Açıklama:** Konteyner çökerse veya Docker daemon yeniden başlarsa konteyneri otomatik olarak yeniden ayağa kaldırır (`always` / `unless-stopped`).

---

## 2. Konteyner Listeleme ve Durum Kontrolü (`docker ps`)

### Çalışan Konteynerleri Listeleme
```bash
docker ps
```

### Durmuş (Exited) Dahil Tüm Konteynerleri Listeleme
```bash
docker ps -a
```

### Özel Formatla Listeleme (Yalnızca İsim, Durum ve Port)
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Yalnızca Konteyner ID'lerini Listeleme (Toplu İşlemler İçin)
```bash
docker ps -q
```

---

## 3. Yaşam Döngüsü: Durdurma, Başlatma ve Silme

### Konteyneri Nazikçe Durdurma (SIGTERM ➔ SIGKILL)
```bash
docker stop web-server
```
* **Açıklama:** Konteynerdeki ana sürece `SIGTERM` gönderir, 10 saniye içinde kapanmazsa `SIGKILL` ile zorlar.

### Konteyneri Anında Zorla Durdurma (SIGKILL)
```bash
docker kill web-server
```

### Durmuş Konteyneri Yeniden Başlatma
```bash
docker start web-server
```

### Konteyneri Yeniden Başlatma (Restart)
```bash
docker restart web-server
```

### Konteyneri Geçici Olarak Dondurma ve Çözme (cgroups Freezer)
```bash
docker pause web-server
docker unpause web-server
```
* **Açıklama:** Süreci RAM'de dondurur, CPU tüketimini sıfırlar; durdurmadan bekletir.

### Durmuş Konteyneri Silme
```bash
docker rm web-server
```

### Çalışan Konteyneri Zorla Silme
```bash
docker rm -f web-server
```

### Tüm Durmuş Konteynerleri Tek Komutla Temizleme
```bash
docker container prune -f
```

---

## 4. Canlı Teftiş ve Hata Ayıklama (Troubleshooting)

### Çalışan Konteynerin İçine Canlı Kabuk Açma
```bash
docker exec -it web-server sh
```
* **Açıklama:** Konteyner içine girip komut çalıştırmayı sağlar (Alpine imajlarında `sh`, Debian/Ubuntu imajlarında `bash`).

### Konteyner İçinde Tek Bir Komut Çalıştırıp Çıktısını Alma
```bash
docker exec web-server nginx -t
```
* **Açıklama:** Konteynerin içine girmeden Nginx konfigürasyon sözdizimini test eder.

### Konteyner Loglarını İnceleme
```bash
docker logs web-server
```

### Canlı Log Takibi (Tail -f Gibi)
```bash
docker logs -f --tail 50 web-server
```

### Dosya Kopyalama (Host ➔ Konteyner veya Konteyner ➔ Host)
```bash
# Host'tan konteynere dosya kopyalama:
docker cp index.html web-server:/usr/share/nginx/html/index.html

# Konteynerden host'a dosya kopyalama:
docker cp web-server:/etc/nginx/nginx.conf ./nginx.conf
```

### Konteyner Dosya Sistemindeki Değişiklikleri İnceleme (`diff`)
```bash
docker diff web-server
```
* **Açıklama:** İmajın orijinal haline göre eklenen (`A`), silinen (`D`) veya değiştirilen (`C`) dosyaları gösterir.

### Konteyner İçindeki Süreçleri (Process) Görme
```bash
docker top web-server
```

### Anlık CPU ve Bellek Tüketimi (Canlı İstatistik)
```bash
docker stats --no-stream
```

### Konteynerin Tüm JSON Metadata Bilgilerini İnceleme (`inspect`)
```bash
# Tüm yapılandırmayı okuma:
docker inspect web-server

# Yalnızca IP adresini filtreleme:
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web-server

# Konteynerin OOMKilled durumunu okuma:
docker inspect -f '{{.State.OOMKilled}}' web-server
```
