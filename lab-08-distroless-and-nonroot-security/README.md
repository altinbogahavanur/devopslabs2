# LAB-08: Konteyner Güvenliği: Non-Root, Distroless ve Zafiyet Taraması

## 🎯 Labın Amacı
Üretim ortamlarında konteynerleri `root` olarak çalıştırmanın getirdiği güvenlik risklerini önlemek, `USER nonroot` direktifiyle en az ayrıcalık ilkesini uygulamak, Google **Distroless** imajları ile saldırı yüzeyini sıfırlamak (kabuksuz çalışma) ve **Trivy** ile CVE güvenlik taraması yapmak.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **8080** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Kötü Pratik: Root Yetkisiyle Çalışan Konteyner
Varsayılan olarak Dockerfile'lar `root` (UID 0) ile çalışır:

```bash
cd lab-08-distroless-and-nonroot-security/app

# Güvensiz imajı derleyin:
docker build -f Dockerfile.bad -t sec-demo:root .

# Konteyneri başlatıp içerideki kullanıcıyı teftiş edin:
docker run -d --name test-root sec-demo:root
docker exec test-root whoami
# Çıktı: root (Güvensiz! Konteynerden kaçış olursa host root yetkisi tehlikeye girer)
```

### 2. Güvenli Pratik: Non-Root Kullanıcı Tanımlama
`Dockerfile.hardened` dosyasında `USER 10001:10001` tanımlanmıştır:

```bash
# Güçlendirilmiş imajı derleyin:
docker build -f Dockerfile.hardened -t sec-demo:hardened .

# Konteyneri başlatıp kullanıcıyı teftiş edin:
docker run -d --name test-hardened sec-demo:hardened
docker exec test-hardened whoami
# Çıktı: appuser (veya UID 10001)
```

### 3. Sıfır Saldırı Yüzeyi: Google Distroless İmajı
Google Distroless imajlarında paket yöneticisi (`apt`, `apk`), derleyici ve hatta komut kabuğu (`sh`, `bash`) bulunmaz. Sadece uygulamanız ve bağımlılıkları yer alır.

```bash
# Distroless imajı derleyin:
docker build -f Dockerfile.distroless -t sec-demo:distroless .

# Distroless konteyneri başlatın:
docker run -d --name test-distroless -p 8080:8080 sec-demo:distroless

# Servisi test edin (Uygulama kusursuz çalışır):
curl http://localhost:8080
```

### 4. Distroless Güvenlik Kanıtı (Kabuk Yok Deneyi)
Bir saldırgan bu konteynere sızmaya çalışsa bile komut çalıştıracak bir kabuk bulamaz:

```bash
# Konteyner içine sh veya bash ile girmeyi deneyin:
docker exec -it test-distroless sh || echo "GÜVENLİK KANITI: Konteyner içinde sh veya bash bulunmuyor!"
```

### 5. Trivy ile Zafiyet (CVE) Taraması
İmaj katmanlarındaki bilinen güvenlik açıklarını denetleyin:

```bash
# Trivy konteyneri ile yerel imajı tarayın:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --severity HIGH,CRITICAL sec-demo:hardened
```

---

## ✅ Doğrulama (Verification)
- `docker exec test-hardened id` çıktısında UID'nin `0` değil `10001` olduğunu teyit edin.
- `docker exec test-distroless sh` komutunun `executable file not found in $PATH` hatasıyla başarısız olduğunu teyit edin.
- `curl http://localhost:8080` çıktısında `Distroless Guvenli Konteyner Calisiyor!` mesajını görün.

---

## 🧹 Temizlik
```bash
docker rm -f test-root test-hardened test-distroless 2>/dev/null || true
docker rmi sec-demo:root sec-demo:hardened sec-demo:distroless 2>/dev/null || true
```
