# LAB-DOC-02-02 — Dosya Kopyalama (docker cp), Anlık Görüntü (commit) ve Teşhis

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç - Orta | `docker-ce`, `nginx:alpine`, `curl` | 8081 |

> **Önemli Erişim Notu:** Yeni imajdan başlatılan web servisini `http://<SUNUCU-IP>:8081` üzerinden tarayıcınızdan veya `curl http://localhost:8081` ile test edebilirsiniz.

---

## Amaç

- Çalışan bir konteyner ile ana makine (host) arasında çift yönlü dosya aktarımı (`docker cp`) gerçekleştirmek.
- Konteyner dosya sistemindeki farkları (`docker diff`) incelemek.
- Canlı konteyner durumundan yeni bir imaj üretmek (`docker commit`) ve bunun üretimdeki sınırlarını kavramak.
- `docker inspect`, `docker stats` ve `docker top` ile sistem kaynaklarını ve süreçlerini analiz etmek.

---

## Ön Koşullar

- LAB-DOC-02-01 tamamlanmış olmalıdır.
- Host üzerinde `8081` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
       HOST MAKİNE (Ubuntu)                          KONTEYNER (web-base)
+──────────────────────────────────+        +──────────────────────────────────+
|  ./custom-index.html             |───────>|  /usr/share/nginx/html/index.html|
|               (docker cp HOST CONTAINER)  |                                  |
|  /tmp/extracted-nginx.conf       |<───────|  /etc/nginx/nginx.conf           |
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

## Adım Adım Uygulama Rehberi

### 1. Temel Konteyneri Başlatma
```bash
docker run -d --name web-base -p 8080:80 nginx:alpine
```

### 2. Çift Yönlü Dosya Transferi (docker cp)
```bash
# 1. Host üzerinde özel bir HTML dosyası hazırlayın:
mkdir -p /tmp/custom-app
cat <<'EOF' > /tmp/custom-app/index.html
<!DOCTYPE html>
<html>
<head><title>Docker CP Dersi</title></head>
<body style="font-family:sans-serif; text-align:center; padding:50px;">
  <h1 style="color:#2563eb;">Docker CP ile Güncellendi!</h1>
  <p>Bu dosya ana makineden konteyner içerisine kopyalanmıştır.</p>
</body>
</html>
EOF

# 2. Dosyayı hosttan konteynere kopyalayın:
docker cp /tmp/custom-app/index.html web-base:/usr/share/nginx/html/index.html

# 3. Konteyner içindeki yapılandırma dosyasını hosta çekin:
docker cp web-base:/etc/nginx/nginx.conf /tmp/custom-app/nginx.conf
ls -lh /tmp/custom-app/nginx.conf
```

### 3. Dosya Sistemi Farklarını İnceleme (docker diff)
```bash
# Değişen (C), Eklenen (A) veya Silinen (D) dosyaları listeler:
docker diff web-base
```

### 4. İmaj Üretme (docker commit)
```bash
# Konteyneri yeni bir imaj olarak kaydedin:
docker commit -m "Ozel index.html eklendi" -a "DevOps Ogrencisi" web-base custom-nginx:v1.0

# İmaj listesinde yeni imajı doğrulayın:
docker images | grep custom-nginx
```

### 5. Yeni İmajı Test Etme ve Doğrulama
```bash
# Eski temel konteyneri durdurup silin:
docker rm -f web-base

# Ürettiğimiz custom-nginx:v1.0 imajını 8081 portundan başlatın:
docker run -d --name web-custom -p 8081:80 custom-nginx:v1.0

# Değişikliğin korunduğunu test edin:
curl http://localhost:8081
```

### 6. Teşhis ve Hata Ayıklama Komutları
```bash
# Çalışan süreçleri inceleme:
docker top web-custom

# Canlı CPU ve RAM tüketimi (Tek seferlik anlık çıktı):
docker stats --no-stream web-custom

# Konteyner IP adresi ve JSON detayları:
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web-custom
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:8081 | grep "Docker CP ile Güncellendi"
# Çıktıda 'Docker CP ile Güncellendi!' metni görülmelidir.
```

---

## Temizlik

```bash
docker rm -f web-custom 2>/dev/null || true
docker rmi custom-nginx:v1.0 2>/dev/null || true
rm -rf /tmp/custom-app
```
