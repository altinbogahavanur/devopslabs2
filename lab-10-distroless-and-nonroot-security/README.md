# * LAB-10: Konteyner Güvenliği: Non-Root, Distroless ve Trivy Zafiyet Taraması

## 🎯 Labın Amacı
Üretim ortamlarında konteynerleri `root` olarak çalıştırmanın getirdiği güvenlik risklerini önlemek, `USER nonroot` direktifiyle en az ayrıcalık (least privilege) ilkesini uygulamak, Google **Distroless** imajları ile saldırı yüzeyini sıfırlamak (kabuksuz çalışma) ve **Trivy** güvenlik tarayıcısı ile imajlardaki CVE zafiyetlerini denetleyip CI/CD güvenlik kapısı (`--exit-code 1`) simülasyonu yapmak.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **8080** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Kötü Pratik: Root Yetkisiyle Çalışan Konteyner
Varsayılan olarak Dockerfile'lar `root` (UID 0) yetkisiyle çalışır:

```bash
cd lab-10-distroless-and-nonroot-security/app

# 1. Güvensiz imajı derleyin:
docker build -f Dockerfile.bad -t sec-demo:root .

# 2. Konteyneri başlatıp içerideki kullanıcıyı teftiş edin:
docker run -d --name test-root sec-demo:root
docker exec test-root whoami
# Çıktı: root (Güvensiz! Konteynerden kaçış olursa ana makinenin root yetkisi tehlikeye girer).
```

---

### 2. Güvenli Pratik: Non-Root Kullanıcı Tanımlama
`Dockerfile.hardened` dosyasında `USER 10001:10001` tanımlanmıştır:

```bash
# 1. Güçlendirilmiş imajı derleyin:
docker build -f Dockerfile.hardened -t sec-demo:hardened .

# 2. Konteyneri başlatıp kullanıcıyı teftiş edin:
docker run -d --name test-hardened sec-demo:hardened
docker exec test-hardened whoami
# Çıktı: appuser (veya UID 10001 - Artık root değil!)
```

---

### 3. Sıfır Saldırı Yüzeyi: Google Distroless İmajı
Google Distroless imajlarında paket yöneticisi (`apt`, `apk`), derleyici ve hatta komut kabuğu (`sh`, `bash`) bulunmaz. Sadece uygulamanız ve bağımlılıkları yer alır.

```bash
# 1. Distroless imajı derleyin:
docker build -f Dockerfile.distroless -t sec-demo:distroless .

# 2. Distroless konteyneri başlatın:
docker run -d --name test-distroless -p 8080:8080 sec-demo:distroless

# 3. Servisi test edin (Uygulama kusursuz çalışır):
curl http://localhost:8080
```

---

### 4. Distroless Güvenlik Kanıtı (Kabuk Yok Deneyi)
Bir saldırgan bu konteynere sızmaya çalışsa bile komut çalıştıracak bir kabuk (`sh` / `bash`) bulamaz:

```bash
# Konteyner içine sh veya bash ile girmeyi deneyin:
docker exec -it test-distroless sh || echo 'GÜVENLİK KANITI: Konteyner içinde sh veya bash bulunmuyor'
# Hata: "executable file not found in $PATH"
```

---

### 5. Trivy ile Güvenlik ve CVE Zafiyet Taraması

Konteyner imajlarındaki işletim sistemi ve kütüphane açıklarını (CVE) tespit etmek için sektör standardı **Aqua Security Trivy** kullanılır.

#### A. Trivy CLI Konteynerini Doğrulama
Ana makineye hiçbir şey kurmadan, Docker soketini bağlayarak Trivy'yi çalıştırın:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest --version
```

#### B. Zafiyetli Eski Bir İmajı Tarama
İçinde bilinen güvenlik açıkları bulunan eski bir imaj çekip tarayalım:
```bash
# 1. Eski bir Node.js imajı çekin:
docker pull node:14-alpine

# 2. İmajı Trivy ile tarayın (Özet CVE tablosunu görün):
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image node:14-alpine
```
*(Gözlem: Terminalde CVE kodları, ciddiyet dereceleri [CRITICAL, HIGH] ve hangi sürümde düzeltildiği [Fixed in] renkli bir tablo olarak basılır).*

#### C. CI/CD Güvenlik Kapısı (Build Kırma Simülasyonu)
CI/CD boru hatlarında kritik açık tespit edildiğinde derlemenin durdurulmasını (`--severity CRITICAL --exit-code 1`) simüle edin:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity CRITICAL \
  --exit-code 1 \
  node:14-alpine || echo 'CI/CD Güvenlik Kapısı Devreye Girdi! Kritik CVE Tespit Edildi, Pipeline Durduruldu 🛑'
```

#### D. Güvenli Distroless İmajı Tarama (0 Kritik Açık)
Hazırladığımız güvenli distroless imajı tarayarak güvenlik farkını teyit edin:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity CRITICAL \
  --exit-code 1 \
  sec-demo:distroless
```
*(Gözlem: 0 Critical açık bulunur ve süreç başarıyla [Exit Code 0] tamamlanır).*

---

## ✅ Doğrulama (Verification)
- `docker exec test-hardened id` çıktısında UID'nin `0` değil `10001` olduğunu teyit edin.
- `docker exec test-distroless sh` komutunun kabuk bulunamadığı için başarısız olduğunu görün.
- Trivy taramasında `node:14-alpine` imajının kritik açıklar nedeniyle `Exit Code 1` döndürdüğünü, `sec-demo:distroless` imajının ise temiz çıktığını gözlemleyin.

---

## 🧹 Temizlik
```bash
docker rm -f test-root test-hardened test-distroless 2>/dev/null || true
docker rmi sec-demo:root sec-demo:hardened sec-demo:distroless node:14-alpine 2>/dev/null || true
```
