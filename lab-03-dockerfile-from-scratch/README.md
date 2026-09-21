# * LAB-03: Sıfırdan Dockerfile Hazırlama ve İmaj Derleme

> 📌 **Sunum Eşleşmesi:** Bu laboratuvar, **Slayt 50 (LAB — Image Build & Optimization)** ilk aşamasında sınıfla birlikte uygulanır.

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
cd lab-03-dockerfile-from-scratch
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

### 5. Adım: CMD vs ENTRYPOINT Farkını Uygulamalı Olarak Kavrayın

Docker'da en çok karıştırılan iki direktif arasındaki fark şudur:
* **`CMD` (Varsayılan Komut):** Konteyner çalışırken ne yapılacağını söyler. Ancak kullanıcı `docker run` komutunun sonuna herhangi bir şey yazarsa, **CMD tamamen çöpe atılır** ve kullanıcının yazdığı yeni komut çalışır.
* **`ENTRYPOINT` (Sabit Ana Program):** Konteyneri tek bir amaca hizmet eden bağımsız bir CLI aracına (örneğin `ping`, `python`, `node`) dönüştürür. Kullanıcı `docker run` sonuna ne yazarsa yazsın, ana komut **asla değişmez**, yazılanlar ana komutun arkasına **parametre** olarak eklenir.

---

#### 🧪 Deney A: Yalnızca CMD Varken (Varsayılanı Tamamen Ezme)
Mevcut imajımızda `CMD ["node", "server.js"]` tanımlıdır:

```bash
# 1. Komut vermeden çalıştırırsanız varsayılan CMD çalışır (Node.js API başlar):
# docker run my-node-api:1.0  --> 'node server.js' çalışır.

# 2. Sona başka bir komut yazarsanız, CMD tamamen ezilir ve Node yerine o komut çalışır:
docker run --rm my-node-api:1.0 echo 'CMD ezildi, Node yerine echo calisti'
# Gözlem: Node.js hiç başlamadı; ekrana sadece echo çıktısı basıldı!
```

---

#### 🧪 Deney B: ENTRYPOINT + CMD Birlikte (Kurumsal Standart Kalıp)
Dizindeki `app/Dockerfile.entrypoint` dosyasını inceleyin:
```dockerfile
FROM alpine:3.20
ENTRYPOINT ["ping", "-c", "2"]
CMD ["127.0.0.1"]
```
Burada:
- **Sabit Program (`ENTRYPOINT`):** `ping -c 2` (Konteyner her zaman ping atacaktır).
- **Varsayılan Argüman (`CMD`):** `127.0.0.1` (Kullanıcı hedef belirtmezse yerel loopback pinglenir).

İmajı derleyip 2 farklı şekilde çalıştırarak farkı görün:

```bash
# 1. Adım: Entrypoint test imajını derleyin:
docker build -f app/Dockerfile.entrypoint -t my-ping-tool:1.0 ./app

# 2. Adım: Parametresiz çalıştırın (CMD devreye girer -> 127.0.0.1 pinglenir):
docker run --rm my-ping-tool:1.0
# Çıktı: PING 127.0.0.1 (127.0.0.1): 56 data bytes

# 3. Adım: Sona hedef yazarak çalıştırın (CMD ezilir, ENTRYPOINT'e parametre olur):
docker run --rm my-ping-tool:1.0 localhost
# Çıktı: PING localhost (127.0.0.1): 56 data bytes

# 4. Adım: Peki ENTRYPOINT zorla ezilmek istenirse ne yapılır?
# '--entrypoint' bayrağı ile ana program geçici olarak değiştirilebilir:
docker run --rm --entrypoint echo my-ping-tool:1.0 'Entrypoint bayrak ile zorla ezildi'
```

---

#### 📊 Özet Karşılaştırma Tablosu

| Özellik | `CMD` | `ENTRYPOINT` | `ENTRYPOINT` + `CMD` (Birlikte) |
|---|---|---|---|
| **Temel Görevi** | Varsayılan komut belirler | Konteynerin ana programını sabitler | Sabit programa varsayılan argüman verir |
| **`docker run <imaj>`** | CMD çalışır | ENTRYPOINT çalışır | ENTRYPOINT + CMD birleşip çalışır |
| **`docker run <imaj> <arg>`**| CMD tamamen çöpe atılır, `<arg>` çalışır | ENTRYPOINT'in arkasına `<arg>` eklenir | CMD ezilir, yerine `<arg>` eklenir |
| **Kullanım Amacı** | Web servisi, DB (esnek başlatma) | CLI araçları (`trivy`, `curl`, `ping`) | Esnek ve profesyonel üretim imajları |

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
docker rmi my-node-api:1.0 my-ping-tool:1.0 2>/dev/null || true
```
