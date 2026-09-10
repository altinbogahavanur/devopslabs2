# LAB-03 — İlk Dockerfile Direktifleri, Katman Önbellekleme (Build Cache) ve .dockerignore

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `node:22-alpine`, `curl` | `3000` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 40-54, Lab 3); bir `Dockerfile` dosyasının temel direktiflerini (`FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, `CMD`) kavramak, Docker derleme motorunun (BuildKit) **katman önbellekleme (layer caching)** mekanizmasını anlamak ve talimat sırasını optimize ederek derleme sürelerini dakikalardan saniyelere indirmektir:

1. **Katman Mimarisi:** Dockerfile'daki her direktifin yeni bir salt-okunur (read-only) dosya sistemi katmanı oluşturduğunu gözlemlemek.
2. **Önbellek Geçersiz Kılma (Cache Invalidation):** Kaynak kod değiştiğinde bağımlılıkların (`npm install`) gereksiz baştan kurulmasını engellemek.
3. **.dockerignore Kullanımı:** `node_modules`, `.git` ve geçici dosyaların derleme bağlamına (build context) girmesini önlemek.
4. **Shell Form vs Exec Form:** `CMD node server.js` ile `CMD ["node", "server.js"]` arasındaki PID 1 ve Linux sinyal farkını kavramak.

---

## 2. Ön Koşullar

* Docker Engine ve BuildKit aktif olmalıdır.
* Port 3000 boşta olmalıdır.

---

## 3. Mimari ve Zihinsel Eşleştirme Modeli

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| `apt install nodejs` | `FROM node:22-alpine` | Tam Ubuntu yerine hafif Alpine/Slim seçimi |
| `mkdir -p /app && cd /app` | `WORKDIR /app` | Dizin yoksa otomatik oluşturulur, `cd` yerine kullanılır |
| Dosya Kopyalama | `COPY package*.json ./` | **Önce sadece bağımlılık listesi kopyalanır!** |
| `npm install` | `RUN npm install` | Kod değişse bile bu katman önbellekten (`CACHED`) gelir |
| Kaynak Kod Transferi | `COPY . .` | Sık değişen kodlar en alt katmanlara bırakılır |
| `export PORT=3000` | `ENV PORT=3000` | Çalışma zamanı ortam değişkeni |
| Port Bildirimi | `EXPOSE 3000` | Dokümantasyon amaçlı dinlenen port |
| `node server.js` | `CMD ["node", "server.js"]` | **Exec Form** kullanılarak sinyallerin doğrudan Node'a gitmesi sağlanır |

---

### Katman Mimarisi: Kötü Sıralama vs Optimize Önbellek

```text
SENARYO A: KÖTÜ SIRALAMA (Dockerfile.baseline)
+────────────────────────────────────+
| 1. FROM node:22-alpine             |  --> CACHED
+────────────────────────────────────+
| 2. COPY . .                        |  --> KOD DEĞİŞTİ! (CACHE BUSTED ❌)
+────────────────────────────────────+
| 3. RUN npm install                 |  --> HER SEFERİNDE ÇALIŞIR (30s Bekleme!)
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

## 4. Görevler (Tasks)

1. `app/` dizinindeki Node.js Express uygulamasını inceleyin.
2. `Dockerfile.baseline` ile imajı derleyin (`docker build --progress=plain -t demo:baseline -f Dockerfile.baseline .`) ve süreyi not edin.
3. `app/server.js` dosyasında küçük bir metin değişikliği yapıp tekrar derleyin. Bağımlılıkların gereksiz baştan kurulduğunu (`RUN npm install`) gözlemleyin.
4. `Dockerfile.optimized` dosyasını inceleyin ve aynı değişikliği yapıp derleyin. BuildKit'in `CACHED` çıktısını yakalayın.
5. `./benchmark.sh` betiğini çalıştırarak süre farkını grafiksel olarak görün.
6. **Çoklu Mimari:** `docker buildx build --platform linux/amd64,linux/arm64` komutunu inceleyin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: .dockerignore Dosyası Neden Zorunludur?</summary>

Eğer ana makinenizde yerel `node_modules/` veya `.git/` klasörleri varsa ve `.dockerignore` tanımlamazsanız, `COPY . .` komutu yüzlerce megabaytlık yerel bağımlılıkları konteyner içine kopyalar. Bu durum hem derleme önbelleğini bozar hem de işletim sistemi uyumsuzluklarına yol açar.
</details>

<details>
<summary>💡 İpucu 2: Shell Form vs Exec Form</summary>

* `CMD node server.js` (Shell Form) ➔ Konteyner `/bin/sh -c "node server.js"` olarak başlar. PID 1 kabuk olur; `docker stop` gönderildiğinde `SIGTERM` sinyali Node.js sürecine iletilmez!
* `CMD ["node", "server.js"]` (Exec Form - Köşeli Parantez) ➔ Doğrudan Node.js PID 1 olur ve sinyalleri yakalayarak veri kaybı olmadan zarifçe kapanır.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:3000/api/health
```

* **HTTP Yanıtı:** `{"status":"UP","timestamp":...}` dönmelidir.
* `benchmark.sh` çıktısında optimize derlemenin en az 10-20 kat daha hızlı olduğu kanıtlanmalıdır.

---

## 7. Temizlik

```bash
docker rm -f cache-test 2>/dev/null || true
docker rmi demo:baseline demo:optimized demo:cache 2>/dev/null || true
```
