# * LAB-14: NovaShop Capstone ve Gerçek Hayat Sorun Giderme

## 🎯 Labın Amacı
Gerçekçi bir kurumsal mikroservis mimarisi olan **NovaShop** (Nginx Gateway -> Node.js Backend -> PostgreSQL DB + Docker Secrets) stack'ini çalıştırmak ve üretimde en sık karşılaşılan **3 kritik arıza senaryosunu** (Veritabanı bağlantı kopması, 502 Bad Gateway / Port uyuşmazlığı ve OOMKilled çökmesi) terminal başında dedektif gibi teşhis edip çözmek.

## 📋 Ön Koşullar & Portlar
- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- Host üzerinde **19001** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Stack Mimarisi ve Başlatma
```bash
cd lab-14-capstone-novashop-troubleshooting

# Stack'i derleyip arka planda başlatın:
docker compose up -d --build

# Tüm konteynerlerin durumunu kontrol edin:
docker compose ps
```

### 2. Sağlık Kontrolü ve API Doğrulama
```bash
# Nginx Gateway üzerinden sağlık kontrolü sorgusu:
curl http://localhost:19001/health

# Veritabanından gelen ürün listesini çekin:
curl http://localhost:19001/api/products
```

---

## 🔍 Gerçek Hayat Sorun Giderme (Troubleshooting) Senaryoları

### ⚡ Senaryo 1: Veritabanı Bağlantı Hatası (Database Connection Failure)
- **Belirti:** `curl http://localhost:19001/api/products` çağrısı `500 Internal Server Error` dönüyor veya backend loglarında `ECONNREFUSED` yazıyor.
- **Teşhis Adımları:**
  1. Backend loglarını inceleyin: `docker compose logs backend`
  2. Backend konteynerinin veritabanı konteynerine DNS ile erişip erişemediğini test edin:
     ```bash
     docker compose exec backend ping -c 2 novashop-db
     ```
  3. Parola veya secret dosyasını denetleyin:
     ```bash
     cat secrets/db_password.txt
     ```
- **Çözüm:** `backend` ve `novashop-db` konteynerlerinin aynı `backend-net` ağında olduğunu ve `DATABASE_URL` değişkeninin doğru şifreyi okuduğunu teyit edin.

---

### ⚡ Senaryo 2: Gateway 502 Bad Gateway (Port Uyuşmazlığı)
- **Belirti:** Tarayıcıdan veya curl ile `502 Bad Gateway` alıyorsunuz ancak `docker compose ps` çıktısında tüm konteynerler `Up` görünüyor!
- **Teşhis Adımları:**
  1. Nginx hata loglarını canlı teftiş edin:
     ```bash
     docker compose logs nginx | grep error
     # Hata: "connect() failed (111: Connection refused) while connecting to upstream"
     ```
  2. Nginx'in yönlendirdiği port ile backend'in gerçekten dinlediği portu kıyaslayın:
     ```bash
     # Nginx konfigürasyonunu kontrol edin:
     cat nginx/nginx.conf | grep proxy_pass
     # Backend'in dinlediği portu kontrol edin:
     docker compose exec backend netstat -tlpn 2>/dev/null || docker compose exec backend ps aux
     ```
- **Çözüm:** Nginx `upstream` bloğundaki port ile Node.js backend'in `PORT` çevre değişkenini eşitleyin.

---

### ⚡ Senaryo 3: Bellek Sızıntısı ve Konteynerin Çökmesi (OOMKilled)
- **Belirti:** Backend konteyneri rastgele aralıklarla yeniden başlıyor (Restarting) veya aniden duruyor.
- **Teşhis Adımları:**
  1. Konteynerin çıkış kodunu sorgulayın:
     ```bash
     docker inspect -f 'ExitCode: {{.State.ExitCode}}, OOMKilled: {{.State.OOMKilled}}' novashop-backend
     ```
  2. Eğer `ExitCode: 137` ve `OOMKilled: true` ise, konteyner `docker-compose.yaml` içindeki bellek kotasını (`mem_limit`) aşmıştır.
- **Çözüm:** Ya uygulamadaki bellek sızıntısını giderin ya da `docker-compose.yaml` dosyasındaki `deploy.resources.limits.memory` kotasını artırın.

---

## ✅ Doğrulama (Verification)
- `curl -s http://localhost:19001/api/products | grep "products"` komutunun JSON ürün listesini eksiksiz döndürdüğünü görün.

---

## 🧹 Temizlik
```bash
docker compose down -v 2>/dev/null || true
```
