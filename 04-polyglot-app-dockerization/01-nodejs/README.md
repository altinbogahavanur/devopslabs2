# LAB-05-01 — Node.js (Express) Uygulamasını Dockerize Etme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Temel | 30 dakika | `node:20-alpine`, `npm`, `curl` | `3000` |

---

## 1. Uygulama Hakkında

Bu laboratuvarda, Express.js tabanlı hafif ve modern bir Node.js REST API uygulaması yer almaktadır (`server.js`). 

Uygulamanın çalışması için yalnızca Node.js runtime ortamına ve `package.json` dosyasında belirtilen `express` kütüphanesine ihtiyaç vardır.

**Amaç:** Node.js uygulamasını en sade, anlaşılır ve en iyi Docker pratiklerine (katman önbellekleme, hafif temel imaj) uygun şekilde Dockerize etmektir.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Kurulum ve Çalıştırma

Dockerfile direktiflerini kurgulamak için referans Linux çalıştırma adımları:

```bash
# 1. Node.js ve npm paket yöneticisinin kurulması
sudo apt update && sudo apt install -y nodejs npm

# 2. Çalışma dizininin açılması ve kodların kopyalanması
mkdir -p /app && cd /app
cp -r /path/to/source/* /app/

# 3. Bağımlılıkların yüklenmesi
npm install

# 4. Port ortam değişkeni
export PORT=3000

# 5. Sunucunun başlatılması
node server.js
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Neden Böyle Yapıyoruz? |
|:---|:---|:---|
| Node.js Kurulumu | `FROM node:20-alpine` | Tam Ubuntu yerine sadece ~50 MB'lık hafif Alpine tabanlı imaj seçimi |
| `cd /app` | `WORKDIR /app` | Konteyner içindeki çalışma dizinini belirler (Dizin yoksa otomatik açar) |
| Paket Dosyasını Kopyalama | `COPY package*.json ./` | **Önce sadece bağımlılık listesi kopyalanır** (Build cache avantajı) |
| `npm install` | `RUN npm install` | Kodlar değişse bile `package.json` değişmediği sürece bu adım önbellekten (`CACHED`) gelir |
| Kodları Kopyalama | `COPY . .` | Sık değişen uygulama kaynak kodları en son katmana kopyalanır |
| Port Bildirimi | `EXPOSE 3000` | Konteynerın hangi portu dinlediğini belgeler |
| Servisi Başlatma | `CMD ["node", "server.js"]` | Uygulamanın ana başlangıç komutu (Exec Form) |

---

## 4. Adım Adım Uygulama ve Doğrulama

**`Dockerfile`:**
```dockerfile
FROM node:20-alpine

WORKDIR /app

# 1. Önce bağımlılık dosyaları kopyalanır
COPY package*.json ./

# 2. Bağımlılıklar yüklenir (Önbellek katmanı)
RUN npm install

# 3. Uygulama kaynak kodları kopyalanır
COPY . .

EXPOSE 3000

# 4. Uygulama başlatılır
CMD ["node", "server.js"]
```

**Derleme ve Çalıştırma Adımları:**
```bash
# 1. İmajı derleme
docker build -t node-express-app:v1.0 .

# 2. Konteynerı arka planda (3000 portu ile) başlatma
docker run -d --name my-node-app -p 3000:3000 node-express-app:v1.0

# 3. Sağlık durumunu test etme
curl -i http://localhost:3000/api/health

# 4. Temizlik
docker rm -f my-node-app
```

---

## 5. Beklenen Sonuç ve Doğrulama

```bash
curl -s http://localhost:3000/api/info
```

* **JSON Çıktısı:**
```json
{"name":"devops-node-api","version":"1.0.0","node":"v20...","port":3000}
```
