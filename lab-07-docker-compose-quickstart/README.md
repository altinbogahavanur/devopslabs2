# * LAB-07: Docker Compose Hızlı Başlangıç (WordPress + MariaDB)

## 🎯 Labın Amacı
Tek tek uzun `docker run` komutları yazmak yerine; bir web uygulaması (WordPress) ile ilişkisel veritabanını (MariaDB) deklaratif bir `docker-compose.yaml` dosyasıyla tek komutta ayağa kaldırmak ve tarayıcıdan test etmek.

## 📋 Erişim & Port Bilgileri
- **Port:** `19001` (App1 Slotu)
- **Web Tarayıcısı Erişimi:** `http://<SUNUCU-IP>/app1` veya `https://student.app1.<domain>`
- **Terminalden Doğrulama:** `curl http://localhost:19001`

---

## 🚀 Adım Adım Uygulama

### 1. Adım: Çalışma Dizinine Geçin
Laboratuvar dizinine geçip mevcut konfigürasyon dosyalarını listeleyin:
```bash
cd lab-07-docker-compose-quickstart
ls -la
```

### 2. Adım: Compose Dosyasını İnceleyin
Web servisi, veritabanı, port eşlemesi ve volume tanımlarını okuyun:
```bash
cat docker-compose.yaml
```

### 3. Adım: Stack'i Tek Komutla Başlatın
Tüm konteynerleri, ağı ve disk birimini arka planda ayağa kaldırın:
```bash
docker compose up -d
```

### 4. Adım: Çalışan Servislerin Durumunu Denetleyin
Konteynerlerin çalıştığını ve portların eşlendiğini kontrol edin:
```bash
docker compose ps
```

### 5. Adım: Veritabanı ve Servis Loglarını İnceleyin
Veritabanının hazır hale geldiğini ve bağlantıları kabul ettiğini loglardan denetleyin:
```bash
docker compose logs --tail 30 db
```

### 6. Adım: Web Arayüzünü Test Edin
- **Terminalden:** HTTP yanıtını doğrulayın:
```bash
curl -I http://localhost:19001
```
- **Web Tarayıcısından:** Tarayıcınızı açıp `http://<SUNUCU-IP>/app1` veya `https://student.app1.<domain>` adresine gidin. WordPress kurulum ekranının geldiğini görün.

---

## ✅ Doğrulama (Verification)
`docker compose ps` komutunda hem `beginner-wordpress` hem de `beginner-mariadb` konteynerlerinin `Up` (çalışıyor) durumda olduğunu ve `0.0.0.0:19001->80/tcp` port eşlemesini teyit edin.

---

## 🧹 Temizlik
Servisleri ve oluşturulan geçici veritabanı diskini tamamen silmek için:
```bash
docker compose down -v
```
