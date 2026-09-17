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

Öğrencinin Dockerfile direktiflerini kurgulayabilmesi için referans Linux akışı:

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

## 4. Görevler (Tasks)

1. Klasör içerisindeki `package.json` ve `server.js` dosyalarını inceleyin.
2. Klasör kök dizininde bir `Dockerfile` oluşturun.
3. Yukarıdaki eşleştirme rehberini takip ederek adımları Dockerfile içine yazın.
4. İmajı `node-express-app:v1.0` adıyla derleyin (`docker build`).
5. Konteyneri başlatın (`docker run`) ve `http://localhost:3000/api/health` adresinden çalıştığını doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Neden Önce package.json Kopyalanır?</summary>

Eğer doğrudan `COPY . .` yapıp ardından `RUN npm install` derseniz, `server.js` dosyasında yapacağınız en ufak 1 harflik değişiklikte bile Docker tüm paketleri internetten baştan indirmek zorunda kalır. `package*.json` dosyasını önce kopyalamak derleme süresini 30 saniyeden 0.5 saniyeye düşürür.
</details>

<details>
<summary>💡 İpucu 2: Profesyonel Üretim İpuçları (npm ci ve non-root)</summary>

* **npm ci:** Kurumsal CI/CD ortamlarında `npm install` yerine `npm ci` komutu tercih edilir; çünkü `package-lock.json` dosyasındaki kilitli sürümleri birebir kurar.
* **Non-root Kullanıcı:** Güvenliği artırmak için `CMD` komutundan hemen önce `USER node` satırı eklenerek root yetkisi olmadan çalıştırılabilir.
</details>

---

## 6. Referans Çözüm

<details>
<summary>🎯 Referans Dockerfile ve Çalıştırma Komutları</summary>

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
</details>

---

## 7. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:3000/api/info
```

* **JSON Çıktısı:**
```json
{"name":"devops-node-api","version":"1.0.0","node":"v20...","port":3000}
```
