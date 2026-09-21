# * LAB-03: Sıfırdan Dockerfile Hazırlama ve İmaj Derleme

## 🎯 Labın Amacı
Geleneksel bir Linux sunucusuna SSH ile bağlanıp elle çalıştırdığımız komutları (`mkdir`, `cd`, `scp`, `apt/npm install`, `export ENV`, servis başlatma) kod olarak altyapı (IaC) prensibiyle bir `Dockerfile` haline getirmek; temel direktifleri (`FROM`, `WORKDIR`, `COPY`, `ENV`, `EXPOSE`, `CMD`, `ENTRYPOINT`) uygulamak ve yerel imaj derlemek.

---

## 💡 Temel Zihinsel Model: Linux Sunucusu vs Dockerfile

**Dockerfile, normal bir Linux sunucusuna terminalden yazdığınız komutların satır satır kod olarak altyapı (IaC) prensibiyle otomasyonudur:**

| Normal Linux Sunucusunda (Elle Yapılan) | Dockerfile Direktifi (Konteyner - IaC) | Açıklama |
|---|---|---|
| 1. Temiz bir Ubuntu/Alpine makine açarsınız | `FROM node:20-alpine` | Taban işletim sistemi ve çalışma zamanı |
| 2. Terminalde `mkdir /app && cd /app` yaparsınız | `WORKDIR /app` | Konteyner içi varsayılan çalışma dizini |
| 3. Kodları sunucuya atarsınız (`scp` / `rsync`) | `COPY server.js .` | Host dosyalarını konteyner içine aktarma |
| 4. Ortam değişkeni girersiniz (`export PORT=3000`) | `ENV PORT=3000` | Çalışma zamanı çevre değişkenleri |
| 5. Güvenlik duvarından port açarsınız (`ufw allow 3000`) | `EXPOSE 3000` | Konteynerin dinlediği port belgelemesi |
| 6. Terminalden uygulamayı başlatırsınız (`node server.js`)| `CMD ["node", "server.js"]` | Konteyner ayağa kalktığında çalışan ana süreç |

---

### 1. Kavramların Rolleri ve Aralarındaki Farklar

JavaScript, Node.js ve Express üçlüsünün Docker üzerindeki çalışma prensibi, Go gibi derlenen dillerden tamamen farklıdır. Go tek bir çalıştırılabilir ikili dosya (static binary) üretirken; Node.js yorumlanan (interpreted/JIT) bir dildir ve uygulamanın çalışması için kaynak kodların yanı sıra çalıştırma ortamına (runtime) ve kütüphane klasörüne (`node_modules`) ihtiyaç duyar.

| Bileşen | Görevi | Konteyner İçindeki Rolü |
| :--- | :--- | :--- |
| **JavaScript** | Programlama dili | Yazdığınız mantık, fonksiyonlar ve dosyalardır (`server.js`). |
| **Node.js** | Çalışma ortamı (Runtime Environment) | Konteyner içine kurulan V8 motorudur (`FROM node:20-alpine`). JS kodunu işletim sistemi üzerinde çalıştırır. |
| **npm** | Paket yöneticisi (Node Package Manager) | Docker imajı derlenirken (`docker build`) dış kütüphaneleri (`node_modules`) indiren araçtır. |
| **Express** | Web çatısı (Framework) | HTTP sunucusu kurmayı, route/endpoint yönetmeyi ve middleware kullanımını sağlayan npm paketidir. |

---

### 2. Node.js ve Express'in Docker Mimarisi
Bir Node.js uygulaması Docker'da çalıştırılırken mimari şu sırayla işler:
1. **Katmanlı İmaj (Base Image):** Temel olarak hafif bir Linux ve kurulu bir Node.js içeren imaj (`node:20-alpine`) kullanılır.
2. **Bağımlılık İndirme (package.json):** `npm` kullanılarak Express ve diğer modüller konteyner katmanına (`node_modules`) indirilir.
3. **Konteyner Süreci (Process):** `CMD ["node", "server.js"]` çağrıldığında, Node.js tek iş parçacıklı (single-threaded event loop) yapısıyla Linux çekirdeğinden bir port (örneğin 3000) dinlemeye başlar.
4. **Port Yönlendirme:** Gelen HTTP istekleri Docker köprü ağı üzerinden Express uygulamasının dinlediği porta aktarılır.

---

### 3. Docker'da Node.js Çalıştırırken Bilinmesi Gereken Kritik Noktalar
- **`.dockerignore` Şarttır:** Ana makinedeki `node_modules` klasörü asla Docker içine kopyalanmamalıdır. Çünkü Mac veya Windows üzerinde derlenen yerel C++ modülleri Linux konteynerinde çalışmaz. `.dockerignore` dosyasına mutlaka `node_modules` yazılmalıdır.
- **`npm ci` vs `npm install`:** Konteyner derlerken `npm install` yerine `npm ci --only=production` kullanılır. Bu, `package-lock.json` dosyasına birebir sadık kalarak deterministik ve tutarlı sürümler yükler.
- **`npm start` Yerine Doğrudan `node server.js`:** `CMD ["npm", "start"]` kullanıldığında, npm süreci sinyalleri (SIGTERM, SIGINT) düzgün iletmez. Konteyneri `docker stop` ile durdurmak istediğinizde 10 saniye bekleyip zorla öldürür (`SIGKILL`). Doğrudan `node server.js` çağırmak zarif kapanmayı (graceful shutdown) sağlar.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **3000** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Adım: Çalışma Dizinine Geçin ve Dosyaları İnceleyin
```bash
# Lab çalışma dizinine geçin:
cd ~/docker-labs/lab-03-dockerfile-from-scratch

# Dockerfile dosyasını inceleyin:
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

> 🎙️ **Slayt 42 & 43: CMD vs ENTRYPOINT Analizi:**
> *"Mülakatların bir numaralı sorusu: 'CMD ile ENTRYPOINT arasındaki fark nedir?'  
> Çok basit! **ENTRYPOINT** konteynerin sabit kimliğidir, ne yapacağını kesinleştirir.  
> **CMD** ise ona verilen varsayılan parametredir; dışarıdan kolayca ezilebilir.  
> Örneğin ENTRYPOINT'e `ping` yazarsanız, CMD'ye `google.com` dersiniz. Kullanıcı konteyneri çalıştırırken sonuna `yahoo.com` yazarsa CMD ezilir ama konteyner yine ping atmaya devam eder. ENTRYPOINT amiraldir, CMD emir eri!"*

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

#### 🧪 Deney B: ENTRYPOINT + CMD Birlikte (Sabit Program + Değişebilir Parametre)
Dizindeki `app/Dockerfile.entrypoint` dosyasını inceleyin:
```dockerfile
FROM alpine:3.20
ENTRYPOINT ["ping", "-c", "2"]
CMD ["google.com"]
```
Burada:
- **Sabit Program (`ENTRYPOINT`):** `ping -c 2` (Konteyner her zaman ping atacaktır).
- **Varsayılan Argüman (`CMD`):** `google.com` (Kullanıcı hedef belirtmezse varsayılan olarak google.com pinglenir).

İmajı derleyip 2 farklı şekilde çalıştırarak farkı görün:

```bash
# 1. Adım: Entrypoint test imajını derleyin:
docker build -f app/Dockerfile.entrypoint -t my-ping-tool:1.0 ./app

# 2. Adım: Parametresiz çalıştırın (CMD devreye girer -> google.com pinglenir):
docker run --rm my-ping-tool:1.0
# Çıktı: PING google.com (142.250.x.x): 56 data bytes

# 3. Adım: Sona hedef yazarak çalıştırın (CMD ezilir, ENTRYPOINT sabit kalır):
docker run --rm my-ping-tool:1.0 yahoo.com
# Çıktı: PING yahoo.com (98.137.x.x): 56 data bytes
# (Gözlem: CMD ezildi, ancak ENTRYPOINT amiral gibi sabit kalarak ping atmaya devam etti!)

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
