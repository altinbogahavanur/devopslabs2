# * LAB-02: Canlı Konteyner Teftişi, Exec ve Log Yönetimi

## 🎯 Labın Amacı
Çalışan bir konteynerin içine interaktif kabuk açmak (`exec`), canlı dosya kopyalayarak sıcak yama (hotfix) uygulamak (`cp`), dosya sistemi değişikliklerini listelemek (`diff`), zaman damgalı canlı log izlemek (`logs`) ve düşük seviye metadata sorgulamak (`inspect`).

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **8081** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Test Konteynerını Başlatma
```bash
# 1. Adım: Çalışma dizinine geçin:
cd ~/docker-labs/lab-02-live-debugging-and-logging

# 2. Adım: Hata ayıklama yapacağımız Nginx konteynerini başlatın:
docker run -d --name debug-web -p 8081:80 nginx:alpine
```

### 2. Konteyner İçine Canlı Bağlanma (Exec)
```bash
# Konteyner içerisinde tek bir komut çalıştırın:
docker exec debug-web cat /etc/os-release

# Konteyner içine interaktif sh oturumu açın:
docker exec -it debug-web sh
# (Konteyner içindeyken hostname ve dizinleri inceleyip çıkın):
hostname
ls -la /usr/share/nginx/html
exit
```

### 3. Canlı Dosya Transferi (Hotfix Uygulaması)
Konteyneri durdurmadan veya yeniden başlatmadan doğrudan canlı içerik güncellemesi yapın:

```bash
# Bulunduğunuz dizindeki ornek-hotfix.html dosyasını konteyner içine aktarın:
docker cp ornek-hotfix.html debug-web:/usr/share/nginx/html/index.html

# Konteyner içindeki konfigürasyon dosyasını ana makineye çekin:
docker cp debug-web:/etc/nginx/nginx.conf ./extracted-nginx.conf
```

### 4. Dosya Sistemi Farklarını İnceleme (docker diff)
Konteynerin salt-okunur imaj katmanı üzerine yazılan değişiklikleri teftiş edin:
- `A` = Added (Eklenen)
- `C` = Changed (Değiştirilen)
- `D` = Deleted (Silinen)

```bash
docker diff debug-web
```

### 5. Canlı ve Zaman Damgalı Log İzleme
```bash
# 1. Ana makineden istekler göndererek log üretin:
curl -s http://localhost:8081 > /dev/null
curl -s http://localhost:8081/test-sayfasi > /dev/null

# 2. Son logları zaman damgalarıyla inceleyin:
docker logs --tail 20 -t debug-web
```

### 6. Proses ve Kaynak Analizi (top & stats)
```bash
# Konteyner içindeki gerçek Linux süreç tablosunu host üzerinden görün:
docker top debug-web

# Konteynerin CPU ve RAM tüketimini tek seferlik sorgulayın:
docker stats --no-stream debug-web
```

### 7. Düşük Seviye JSON Filtreleme (docker inspect)
```bash
# Konteynerin dahili IP adresini Go template ile doğrudan filtreleyin:
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' debug-web

# Konteynerin çalışma durumunu (Running/OOMKilled) sorgulayın:
docker inspect -f '{{.State.Status}} (OOMKilled: {{.State.OOMKilled}})' debug-web
```

---

## ✅ Doğrulama (Verification)
```bash
curl -s http://localhost:8081 | grep "Canlı Hotfix Başarılı"
```
Çıktıda `🚀 Canlı Hotfix Başarılı!` başlığının dönmesi dosyanın kesintisiz güncellendiğini doğrular.

---

## 🧹 Temizlik
```bash
docker rm -f debug-web
rm -f ./extracted-nginx.conf
```
