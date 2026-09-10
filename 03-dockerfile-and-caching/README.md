# LAB-03 — İlk Dockerfile Direktifleri, Katman Önbellekleme (Build Cache) ve .dockerignore

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `node:22-alpine`, `curl` | `3000` |

---

## Mimari ve Zihinsel Eşleştirme Modeli

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| `apt install nodejs` | `FROM node:22-alpine` | Tam Ubuntu yerine hafif Alpine/Slim seçimi |
| `mkdir -p /app && cd /app` | `WORKDIR /app` | Dizin yoksa otomatik oluşturulur, `cd` yerine kullanılır |
| Dosya Kopyalama | `COPY package*.json ./` | **Önce sadece bağımlılık listesi kopyalanır** |
| `npm install` | `RUN npm install` | Kod değişse bile bu katman önbellekten (`CACHED`) gelir |
| Kaynak Kod Transferi | `COPY . .` | Sık değişen kodlar en alt katmanlara bırakılır |
| `export PORT=3000` | `ENV PORT=3000` | Çalışma zamanı ortam değişkeni |
| Port Bildirimi | `EXPOSE 3000` | Dokümantasyon amaçlı dinlenen port |
| `node server.js` | `CMD ["node", "server.js"]` | **Exec Form** kullanılarak sinyallerin doğrudan Node'a gitmesi sağlanır |

```text
SENARYO A: KÖTÜ SIRALAMA (Dockerfile.baseline)
+────────────────────────────────────+
| 1. FROM node:22-alpine             |  --> CACHED
+────────────────────────────────────+
| 2. COPY . .                        |  --> KOD DEĞİŞTİ! (CACHE BOZULDU ❌)
+────────────────────────────────────+
| 3. RUN npm install                 |  --> HER SEFERİNDE ÇALIŞIR (Gereksiz Bekleme!)
+────────────────────────────────────+

SENARYO B: OPTİMİZE SIRALAMA (Dockerfile.optimized)
+────────────────────────────────────+
| 1. FROM node:22-alpine             |  --> CACHED
+────────────────────────────────────+
| 2. COPY app/package*.json ./       |  --> DEĞİŞMEDİ (CACHED ✅)
+────────────────────────────────────+
| 3. RUN npm install                 |  --> DEĞİŞMEDİ (CACHED ✅ - 0.0s!)
+────────────────────────────────────+
| 4. COPY app/ ./                    |  --> SADECE KOD KOPYALANDI (0.1s!)
+────────────────────────────────────+
```

---

## Adım Adım Uygulama

### Adım 1: Baseline Dockerfile ile İlk Derleme

Kötü katman sıralamasına sahip `Dockerfile.baseline` dosyasını derleyin:

```bash
docker build --progress=plain -t demo:baseline -f Dockerfile.baseline .
```

---

### Adım 2: Kod Değişikliği ve Katman Önbellek Bozulması (Cache Busting)

`app/server.js` dosyasında küçük bir metin değişikliği yapıp tekrar derleyin:

```bash
echo "// test change" >> app/server.js
docker build --progress=plain -t demo:baseline -f Dockerfile.baseline .
```

*Çıktıda `COPY . .` adımından sonraki `RUN npm install` adımının önbelleği kaybettiğini ve paketlerin baştan kurulduğunu gözlemleyin.*

---

### Adım 3: Optimize Sıralama ile Derleme (Dockerfile.optimized)

Bağımlılık dosyasını koddan önce kopyalayan `Dockerfile.optimized` dosyasını derleyin:

```bash
docker build --progress=plain -t demo:optimized -f Dockerfile.optimized .
```

---

### Adım 4: Optimize İmajda Kod Değiştirme ve BuildKit Hızını Görme

`app/server.js` dosyasında tekrar küçük bir değişiklik yapıp optimize Dockerfile ile derleyin:

```bash
echo "// second change" >> app/server.js
docker build --progress=plain -t demo:optimized -f Dockerfile.optimized .
```

*Çıktıda `RUN npm install` adımının `CACHED` olarak anında (0.0s) geçtiğini, yalnızca `COPY app/ ./` adımının çalıştığını gözlemleyin.*

---

### Adım 5: Konteyneri Çalıştırma ve Test Etme

```bash
# Optimize imajı başlatma
docker run -d --name node-app -p 3000:3000 demo:optimized

# Yanıtı test etme
curl -i http://localhost:3000
```

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker rm -f node-app 2>/dev/null || true
docker rmi demo:baseline demo:optimized 2>/dev/null || true
```
