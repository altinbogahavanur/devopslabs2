# LAB-17: Docker ile SonarQube Kod Kalitesi ve Güvenlik Taraması (SAST)

## 🎯 Labın Amacı
Ana makineye veya sunucuya Java, Maven veya yerel Sonar Scanner kurma zahmetine girmeden; doğrudan Docker üzerindeki resmi `sonarsource/sonar-scanner-cli` konteyneri ile kaynak kodları **Port 19000 SonarQube** sunucusuna taratmak, zafiyetleri (Vulnerabilities), kod kokularını (Code Smells) ve Kalite Kapısını (Quality Gate) incelemek.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Platform SonarQube servisi **Port 19000** üzerinde (`http://127.0.0.1:19000/sonar`) aktif olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. SonarQube Arayüzüne Giriş ve Token Üretme
1. Tarayıcınızdan `http://<SUNUCU-IP>:19000/sonar` (veya yerelde `http://localhost:19000/sonar`) adresine gidin.
2. Giriş yapın (Varsayılan: `admin / admin`).
3. Sağ üstteki profil simgesinden **My Account → Security** sekmesine gidin.
4. **Generate Token** diyerek `cli-scanner` adında bir User Token oluşturun ve kopyalayın.

---

### 2. Proje Dosyalarını İnceleme
Lab dizinindeki örnek JavaScript kodunu ve SonarQube ayarlarını inceleyin:

```bash
cd lab-17-code-quality-sonarqube-cli

# Konfigürasyon dosyasını görüntüleyin:
cat sonar-project.properties

# Taranacak örnek kodu inceleyin (İçinde kasıtlı kod kokuları ve güvenlik açık noktaları vardır):
cat src/app.js
```

---

### 3. Docker Konteyneri ile Kod Taramasını Başlatma
Hiçbir şey kurmadan, yerel kod dizinini (`/usr/src`) resmi Sonar Scanner imajına bağlayarak taramayı başlatın:

```bash
SONAR_TOKEN="<1_ADIMDA_ALDIĞINIZ_TOKEN>"

# Docker ile tarayıcı konteynerini çalıştırın:
docker run --rm \
  --network host \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.host.url="http://127.0.0.1:19000/sonar" \
  -Dsonar.token="${SONAR_TOKEN}"
```

*(Alternatif olarak `./scan.sh` betiğini de kullanabilirsiniz).*

---

### 4. SonarQube Arayüzünde Raporu İnceleme
Tarama tamamlandıktan sonra terminal çıktısında bir dashboard linki belirir. Tarayıcınızdan projeyi açın:
- **Quality Gate:** Projenin kalite standardını geçip geçmediğini (`Passed` / `Failed`) görün.
- **Issues (Bugs & Code Smells):** Kod içindeki gereksiz karmaşık mantıkları inceleyin.
- **Security Hotspots:** `console.log` içine basılan kredi kartı bilgisinin SonarQube tarafından güvenlik riski olarak yakalandığını teyit edin.

---

### 5. Opsiyonel: İzole Ortamda Sıfırdan SonarQube Başlatma
Eğer sunucunuzda hazır SonarQube yoksa, tek bir Docker komutuyla geçici olarak başlatabilirsiniz:

```bash
docker run -d --name sonarqube-standalone \
  -p 19000:9000 \
  -e SONAR_WEB_CONTEXT=/sonar \
  sonarqube:community
```

---

## ✅ Doğrulama (Verification)
- Terminalde `EXECUTION SUCCESS` mesajının basıldığını görün.
- SonarQube Web Arayüzünde `DevOps Docker Labs App` adlı projenin oluştuğunu ve analiz sonuçlarının görüntülendiğini teyit edin.

---

## 🧹 Temizlik
```bash
# Sadece standalone konteyner açtıysanız silin:
docker rm -f sonarqube-standalone 2>/dev/null || true
rm -rf .scannerwork
```
