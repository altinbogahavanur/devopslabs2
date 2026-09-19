# LAB-DOC-03-02 — Katman Önbellekleme (Layer Caching) ve Optimizasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Temel - Orta | `docker-ce`, `buildkit`, `benchmark` | 3000 |

---

## Amaç

- Docker BuildKit katman önbellekleme (layer cache) mekanizmasını derinlemesine anlamak.
- Önbellek bozulması (cache invalidation) sorununu önlemek için komut sıralamasını optimize etmek.
- `.dockerignore` kullanarak derleme bağlamını (build context) gereksiz dosyalardan arındırmak.
- Katmanları birleştirerek (`&&`) imaj boyutunu küçültmek.

---

## Ön Koşullar

- LAB-DOC-03-01 tamamlanmış olmalıdır.

---

## Mimari ve Önbellek Modeli

```text
KÖTÜ SIRALAMA (Her kod değişiminde npm install baştan çalışır!):
COPY . .                  ──> [Kod değişti! Önbellek BOZULDU ❌]
RUN npm install           ──> [Yavaş: 45 saniye sürer!]

OPTİMİZE SIRALAMA (Sadece bağımlılık değiştiğinde npm install çalışır):
COPY package*.json .      ──> [Bağımlılık değişmediyse CACHED ✅]
RUN npm install           ──> [CACHED: 0.1 saniyede geçer! ⚡]
COPY . .                  ──> [Sadece kod kopyalanır: Hızlı!]
```

---

## Adım Adım Uygulama Rehberi

### 1. Çalışma Dizinini Hazırlama
```bash
mkdir -p /tmp/cache-demo && cd /tmp/cache-demo

cat <<'EOF' > package.json
{
  "name": "caching-demo",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.19.2"
  }
}
EOF

cat <<'EOF' > server.js
const express = require('express');
const app = express();
app.get('/', (req, res) => res.json({ status: "Cache optimized!" }));
app.listen(3000);
EOF
```

### 2. .dockerignore Dosyası Oluşturma
```bash
cat <<'EOF' > .dockerignore
node_modules
npm-debug.log
.git
.env
*.md
EOF
```

### 3. Hatalı vs Optimize Dockerfile Karşılaştırması

```bash
# Optimize edilmiş Dockerfile:
cat <<'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /app

# 1. Önce sadece bağımlılık dosyalarını kopyala (Önbelleği korur)
COPY package*.json ./
RUN npm install --only=production

# 2. Kaynak kodları en son kopyala
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

### 4. Derleme Hızını Test Etme
```bash
# İlk derleme (Önbelleksiz - bağımlılıklar indirilir):
time docker build -t cache-test:v1 .

# Şimdi sadece server.js dosyasına bir boşluk veya yorum satırı ekleyin:
echo "// kucuk degisiklik" >> server.js

# İkinci derleme (npm install önbellekten (CACHED) gelir, anında tamamlanır!):
time docker build -t cache-test:v2 .
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker build -t cache-test:v2 . | grep -E "CACHED.*npm install|cached"
# Çıktıda npm install adımının 'CACHED' olduğunu teyit edin.
```

---

## Temizlik

```bash
docker rmi cache-test:v1 cache-test:v2 2>/dev/null || true
rm -rf /tmp/cache-demo
```
