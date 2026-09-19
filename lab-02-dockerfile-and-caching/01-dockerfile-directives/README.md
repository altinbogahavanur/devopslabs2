# LAB-DOC-03-01 — Dockerfile Direktifleri ve Temel İmaj Derleme

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Temel | `docker-ce`, `curl` | 3000 |

---

## Amaç

- Bir `Dockerfile` dosyasının temel direktiflerini (`FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`, `CMD`, `ENTRYPOINT`) kavramak.
- `CMD` ve `ENTRYPOINT` arasındaki kritik farkı (varsayılan argüman vs sabit komut) uygulamalı olarak görmek.
- `docker build -t` ile yerel imaj derlemek.

---

## Ön Koşullar

- LAB-DOC-02 tamamlanmış olmalıdır.
- Host üzerinde `3000` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
[Dockerfile] ──(docker build)──> [İmaj Katmanları] ──> [docker run] ──> [Konteyner:3000]
 - FROM node:20-alpine              (Salt Okunur)
 - WORKDIR /app
 - COPY . .
 - CMD ["node", "app.js"]
```

---

## Adım Adım Uygulama Rehberi

### 1. Basit Bir Node.js Uygulaması Hazırlama
```bash
mkdir -p /tmp/node-basic && cd /tmp/node-basic

cat <<'EOF' > app.js
const http = require('http');
const port = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'application/json'});
  res.end(JSON.stringify({ message: "Dockerfile direktifleri basariyla calisti!", env: process.env.APP_ENV }));
});
server.listen(port, () => console.log(`Sunucu port ${port} uzerinde dinliyor`));
EOF
```

### 2. Standart Dockerfile Oluşturma
```bash
cat <<'EOF' > Dockerfile
FROM node:20-alpine
WORKDIR /usr/src/app
ENV APP_ENV=production
COPY app.js .
EXPOSE 3000
CMD ["node", "app.js"]
EOF
```

### 3. İmajı Derleme ve Çalıştırma
```bash
# İmajı derleyin:
docker build -t my-node-app:1.0 .

# Konteynerı başlatın:
docker run -d --name node-demo -p 3000:3000 my-node-app:1.0

# Servisi test edin:
curl http://localhost:3000
```

### 4. CMD vs ENTRYPOINT Farkını Deneyimleme
```bash
# CMD parametresi dışarıdan kolayca ezilebilir:
docker run --rm my-node-app:1.0 node -e "console.log('CMD ezildi!')"
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:3000 | grep "Dockerfile direktifleri basariyla calisti"
# JSON yanıtında başarı mesajı ve APP_ENV: production görülmelidir.
```

---

## Temizlik

```bash
docker rm -f node-demo 2>/dev/null || true
docker rmi my-node-app:1.0 2>/dev/null || true
rm -rf /tmp/node-basic
```
