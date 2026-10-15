# 🖼️ Docker İmaj Yönetimi Komutları (Image Cheatsheet)

İmaj derleme, etiketleme, katman analizi, kayıt defterine gönderme ve imaj arşivleme komutları.

---

## 1. İmaj Derleme (`docker build`)

Dockerfile talimatlarını okuyarak katmanlı bir Docker imajı üretir.

### Temel İmaj Derleme
```bash
docker build -t my-app:1.0 .
```
* **Açıklama:** Bulunduğunuz dizindeki (`.`) Dockerfile'ı kullanarak `my-app:1.0` adında imaj derler.

### Farklı Bir Dockerfile Konumu Belirtme (`-f`)
```bash
docker build -f docker/Dockerfile.prod -t my-app:prod .
```

### Önbelleği Devre Dışı Bırakarak Sıfırdan Derleme (`--no-cache`)
```bash
docker build --no-cache -t my-app:fresh .
```
* **Açıklama:** Tüm katmanları (`RUN apt-get update` vb.) önbellekten okumadan yeniden çalıştırır.

### Multi-Stage Build İçinden Belirli Bir Aşamayı Derleme (`--target`)
```bash
docker build --target builder -t my-app:builder .
```
* **Açıklama:** Yalnızca `AS builder` aşamasına kadar derleme yapar (test veya derleme artefaktlarını incelemek için).

### Derleme Sırasında Değişken Geçme (`--build-arg`)
```bash
docker build --build-arg APP_VERSION=2.4.0 -t my-app:2.4.0 .
```

---

## 2. İmajları Listeleme ve İnceleme

### Yerel Sistemdeki İmajları Listeleme
```bash
docker images
```

### Yalnızca İsim ve Boyut Bilgisi Görme
```bash
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Boşta Kalan (Dangling - `<none>`) İmajları Filtreleme
```bash
docker images -f "dangling=true"
```

### İmajın Katmanlarını ve Boyut Dağılımını İnceleme (`history`)
```bash
docker history my-app:1.0
```
* **Açıklama:** İmajın her bir katmanının hangi komutla (`COPY`, `RUN` vb.) üretildiğini ve boyutunu gösterir.

### İmaj Metadata Bilgilerini Okuma (`inspect`)
```bash
# İmajın çalışma kullanıcısını (User) görme:
docker inspect -f '{{.Config.User}}' my-app:1.0

# İmajın varsayılan CMD ve ENTRYPOINT bilgisini görme:
docker inspect -f 'Entrypoint: {{.Config.Entrypoint}}, Cmd: {{.Config.Cmd}}' my-app:1.0
```

---

## 3. İmaj Etiketleme ve Registry (Push / Pull)

### İmajı Docker Hub İçin Etiketleme
```bash
docker tag my-app:1.0 <KULLANICI_ADI>/devops-app-pub:nginx-1.0
```
* **Format:** `<KULLANICI_ADI>/<REPO_ADI>:<ETİKET>`

### İmajı Özel Registry (Örn: Harbor) İçin Etiketleme
```bash
docker tag my-app:1.0 127.0.0.1:18444/devops-public/my-app:1.0
```
* **Format:** `<REGISTRY_HOST>:<PORT>/<PROJE_ADI>/<IMAJ_ADI>:<ETİKET>`

### İmajı Registry'ye Yükleme (`push`)
```bash
# Docker Hub'a gönderme:
docker push <KULLANICI_ADI>/devops-app-pub:nginx-1.0

# Harbor'a gönderme:
docker push 127.0.0.1:18444/devops-public/my-app:1.0
```

### İmajı Registry'den İndirme (`pull`)
```bash
docker pull alpine:3.20
docker pull 127.0.0.1:18444/devops-public/my-app:1.0
```

---

## 4. İmaj Silme ve Temizlik

### Belirli Bir İmajı Silme
```bash
docker rmi my-app:1.0
```

### İmajı Zorla Silme (Konteyner Tarafından Kullanılıyorsa)
```bash
docker rmi -f my-app:1.0
```

### Kullanılmayan (Dangling) İmajları Temizleme
```bash
docker image prune -f
```

### Konteynerler Tarafından Kullanılmayan Tüm İmajları Temizleme
```bash
docker image prune -a -f
```

---

## 5. İmaj Arşivleme ve Çevrimdışı Taşıma (Air-Gapped)

İnternet erişimi olmayan kapalı devre sunuculara imaj aktarmak için kullanılır.

### İmajı `.tar` Arşivi Olarak Kaydetme (`docker save`)
```bash
docker save -o my-app.tar my-app:1.0
```

### `.tar.gz` Olarak Sıkıştırarak Kaydetme
```bash
docker save my-app:1.0 | gzip > my-app.tar.gz
```

### `.tar` Arşivinden İmajı Geri Yükleme (`docker load`)
```bash
docker load -i my-app.tar
# Veya sıkıştırılmış dosyadan:
docker load < my-app.tar.gz
```
