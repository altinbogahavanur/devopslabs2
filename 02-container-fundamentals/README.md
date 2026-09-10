# LAB-02 — Konteyner Yaşam Döngüsü, docker cp, docker commit ve Teşhis Araçları

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 45 dakika | `docker-ce`, `curl` | `8080, 8081` |

---

## Mimari ve Çalışma Modeli

```text
               HOST MAKİNE (Ubuntu)                          KONTEYNER (Nginx)
        +──────────────────────────────────+        +──────────────────────────────────+
        |                                  |        |                                  |
        |  ./app/index.html                |───────>|  /usr/share/nginx/html/index.html|
        |               (docker cp HOST CONTAINER)  |                                  |
        |                                  |        |                                  |
        |  /tmp/nginx.conf                 |<───────|  /etc/nginx/nginx.conf           |
        |               (docker cp CONTAINER HOST)  |                                  |
        +──────────────────────────────────+        +──────────────────────────────────+
                         │                                           │
                         ▼                                           ▼
             +───────────────────────+                   +───────────────────────+
             |   docker commit       | ───────────────>  |  custom-nginx:v1.0    |
             |  (Anlık Durum İmajı)  |                   |  (Yeni İmaj Üretildi) |
             +───────────────────────+                   +───────────────────────+
```

---

## Adım Adım Uygulama

### Adım 1: İlk Konteyneri Başlatma ve İnceleme

```bash
# 1. Konteyneri arka planda çalıştırma
docker run -d --name my-web -p 8080:80 nginx:alpine

# 2. Çalışan konteynerları listeleme
docker ps

# 3. Web sunucusuna erişimi test etme
curl -i http://localhost:8080

# 4. Konteyner loglarını inceleme
docker logs my-web

# 5. Konteyner içinde kabuk komutu işletme
docker exec -it my-web sh -c "cat /etc/os-release"
```

---

### Adım 2: Çift Yönlü Dosya Transferi (docker cp)

```bash
# Host üzerinde özel bir HTML dosyası hazırlama
mkdir -p app
cat <<'HTML_EOF' > app/index.html
<!DOCTYPE html>
<html>
<head><title>DevOps Labs</title></head>
<body><h1>Konteyner İçi Canlı Güncellendi!</h1></body>
</html>
HTML_EOF

# 1. Host makineden çalışan konteyner içine dosya kopyalama
docker cp app/index.html my-web:/usr/share/nginx/html/index.html

# 2. Güncellenen içeriği tarayıcıdan veya curl ile doğrulama
curl -s http://localhost:8080

# 3. Konteyner içindeki yapılandırma dosyasını host makineye çekme
docker cp my-web:/etc/nginx/nginx.conf /tmp/nginx_extracted.conf
head -n 10 /tmp/nginx_extracted.conf
```

---

### Adım 3: Canlı Konteynerden Yeni İmaj Üretme (docker commit)

```bash
# 1. Değiştirilmiş konteynerdan yeni bir imaj oluşturma
docker commit -m "custom html added" -a "DevOps Engineer" my-web custom-nginx:v1.0

# 2. Üretilen imajı listeleme
docker images custom-nginx:v1.0

# 3. Orijinal konteyneri silme
docker rm -f my-web

# 4. Yeni üretilen imajdan yeni bir konteyner başlatma
docker run -d --name my-custom-web -p 8080:80 custom-nginx:v1.0

# 5. Özel HTML sayfasının korunduğunu test etme
curl -s http://localhost:8080
```

---

### Adım 4: Hata Kodu (ExitCode) ve Teşhis

```bash
# Hata ile kapanan bir test konteyneri çalıştırma
docker run --name exit-demo alpine sh -c "echo 'Süreç başladı...'; exit 1"

# Durum ve çıkış kodunu filtreleme
docker inspect -f '{{.State.Status}} ExitCode: {{.State.ExitCode}}' exit-demo
```

---

### Adım 5: Canlı Kaynak İzleme ve Süreç İnceleme

```bash
# Anlık CPU/Bellek tüketimini okuma
docker stats --no-stream

# Konteyner içi süreçleri listeleme
docker top my-custom-web
```

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker rm -f my-custom-web exit-demo 2>/dev/null || true
docker rmi custom-nginx:v1.0 2>/dev/null || true
rm -f /tmp/nginx_extracted.conf
```
