# LAB-06: Sıfırdan Dockerfile Hazırlama ve İmaj Derleme

## 🎯 Labın Amacı
Geleneksel bir Linux sunucusuna SSH ile bağlanıp elle çalıştırdığımız komutları (`mkdir`, `cd`, `scp`, `apt/npm install`, `export ENV`, servis başlatma) kod olarak altyapı (IaC) prensibiyle bir `Dockerfile` haline getirmek; temel direktifleri (`FROM`, `WORKDIR`, `COPY`, `ENV`, `EXPOSE`, `CMD`, `ENTRYPOINT`) uygulamak ve yerel imaj derlemek.

---

## 💡 Temel Zihinsel Model: Linux Sunucusu vs Dockerfile

Dockerfile uzaydan gelen sihirli bir yapı değildir; **normal bir Linux sunucusuna terminalden yazdığınız komutların satır satır otomasyonudur:**

| Normal Linux Sunucusunda (Elle Yapılan) | Dockerfile Direktifi (Konteyner - IaC) | Açıklama |
|---|---|---|
| 1. Temiz bir Ubuntu/Alpine makine açarsınız | `FROM node:20-alpine` | Taban işletim sistemi ve çalışma zamanı |
| 2. Terminalde `mkdir /app && cd /app` yaparsınız | `WORKDIR /app` | Konteyner içi varsayılan çalışma dizini |
| 3. Kodları sunucuya atarsınız (`scp` / `rsync`) | `COPY server.js .` | Host dosyalarını konteyner içine aktarma |
| 4. Ortam değişkeni girersiniz (`export PORT=3000`) | `ENV PORT=3000` | Çalışma zamanı çevre değişkenleri |
| 5. Güvenlik duvarından port açarsınız (`ufw allow 3000`) | `EXPOSE 3000` | Konteynerin dinlediği port belgelemesi |
| 6. Terminalden uygulamayı başlatırsınız (`node server.js`)| `CMD ["node", "server.js"]` | Konteyner ayağa kalktığında çalışan ana süreç |

---

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **3000** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Adım: Çalışma Dizinine Geçin ve Dosyaları İnceleyin
```bash
cd lab-06-dockerfile-from-scratch
cat app/Dockerfile
```

### 2. Adım: İmajı Derleyin (docker build)
Terminal komutlarını imaj katmanlarına dönüştürün:
```bash
docker build -t my-node-api:1.0 ./app

# Derlenen imajı ve katman boyutunu denetleyin:
docker images | grep my-node-api
```

### 3. Adım: Konteyneri Çalıştırın ve Test Edin
Linux'ta arka planda bir servis çalıştırmak gibi (`systemctl start` yerine `docker run -d`):
```bash
docker run -d --name node-api -p 3000:3000 my-node-api:1.0

# API servisine HTTP isteği gönderip yanıtı doğrulayın:
curl http://localhost:3000
```

### 4. Adım: Çalışma Zamanı Değişkenini (ENV) Dışarıdan Değiştirin
Linux'ta `export APP_ENV=staging` yapmakla aynı mantıkta, konteyneri çalıştırırken değişkeni ezin:
```bash
docker run -d --name node-staging -p 3001:3000 -e APP_ENV=staging my-node-api:1.0

curl http://localhost:3001
# Çıktıda '"environment":"staging"' dönecektir.
```

### 5. Adım: CMD vs ENTRYPOINT Farkını Deneyimleyin
- `CMD`: Konteyner çalıştırılırken dışarıdan verilen argümanlarla **tamamen ezilebilir** (Linux'taki varsayılan komut).
- `ENTRYPOINT`: Konteynerin sabit yürütülebilir dosyasıdır (Linux'taki binary alias).

```bash
# CMD ezme deneyi: 'node server.js' yerine 'echo' çalıştırın:
docker run --rm my-node-api:1.0 echo "CMD ezildi ve bu metin ekrana basildi!"
```

---

## ✅ Doğrulama (Verification)
```bash
curl -s http://localhost:3000 | grep "Dockerfile direktifleri basariyla calisti"
```
JSON yanıtında `status: success` ve başarı mesajının dönmesi imajın doğru paketlendiğini kanıtlar.

---

## 🧹 Temizlik
```bash
docker rm -f node-api node-staging 2>/dev/null || true
docker rmi my-node-api:1.0 2>/dev/null || true
```
