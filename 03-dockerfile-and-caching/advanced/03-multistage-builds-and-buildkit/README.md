# LAB-DOC-03-03 (Advanced) — Çok Aşamalı Derleme (Multi-Stage) ve BuildKit

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker-ce`, `buildx`, `golang` | 8080 |

---

## Amaç

- Üretim ortamında derleyici, test kütüphaneleri ve SDK gibi ağır araçların imajda kalmasını önlemek.
- **Multi-Stage Build** deseni ile kaynak kodları derleyici aşamasında (`builder`) üretip, sadece çalıştırılabilir ikiliyi (binary) minimal bir runtime imajına (`alpine` veya `scratch`) taşımak.
- İmaj boyutunu **800+ MB'tan ~10 MB'a düşürmek**.
- BuildKit ile gizli bilgileri (API Token / SSH Key) imaj katmanlarına sızdırmadan güvenle kullanmak (`--mount=type=secret`).

---

## Ön Koşullar

- LAB-DOC-03-01 ve 02 tamamlanmış olmalıdır.

---

## Mimari ve Çok Aşamalı Derleme Modeli

```text
+─────────────────────────────────────────────────────────────+
| 1. AŞAMA (BUILDER): golang:1.23-alpine (~400 MB)            |
|  - Go derleyicisi, git, build araçları kuruludur.          |
|  - Kod derlenir: CGO_ENABLED=0 go build -o /app/server      |
+─────────────────────────────────────────────────────────────+
                               │
               SADECE DERLENMİŞ İKİLİ KOPYALANIR
                               ▼
+─────────────────────────────────────────────────────────────+
| 2. AŞAMA (RUNTIME): alpine:3.20 (~7 MB) veya SCRATCH (~0 MB)|
|  - Sadece /app/server ikili dosyası bulunur.                |
|  - Hiçbir derleyici veya gereksiz paket İÇERMEZ.            |
|  - Toplam İmaj Boyutu: ~12 MB! 🚀                           |
+─────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Minimal Go Uygulaması Hazırlama
```bash
mkdir -p /tmp/multistage-demo && cd /tmp/multistage-demo

cat <<'EOF' > main.go
package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Multi-Stage Go mikroservisi basariyla calisiyor!")
	})
	fmt.Println("Sunucu 8080 portunda calisiyor...")
	http.ListenAndServe(":8080", nil)
}
EOF
```

### 2. Multi-Stage Dockerfile Yazımı
```bash
cat <<'EOF' > Dockerfile
# --- 1. AŞAMA: DERLEYİCİ (BUILDER) ---
FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY main.go .
# Bağımsız statik binary derleme (CGO kapalı):
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /bin/server main.go

# --- 2. AŞAMA: MİNİMAL ÇALIŞMA ORTAMI (RUNTIME) ---
FROM alpine:3.20
WORKDIR /app
# 1. Aşamadan sadece derlenen binary dosyasını kopyalayın:
COPY --from=builder /bin/server /app/server

EXPOSE 8080
USER 10001:10001
CMD ["/app/server"]
EOF
```

### 3. İmajı Derleme ve Boyut Karşılaştırması
```bash
# Multi-stage imajı derleyin:
docker build -t multistage-app:optimized .

# Standart golang imajı ile derlenmiş olsaydı boyutunu karşılaştırın:
docker images | grep -E "golang|multistage-app"
```

### 4. Konteynerı Başlatma ve Doğrulama
```bash
docker run -d --name go-server -p 8080:8080 multistage-app:optimized
curl http://localhost:8080
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
# 1. Boyut denetimi (İmaj 25 MB'ın altında olmalıdır):
docker images multistage-app:optimized --format "{{.Size}}"

# 2. Çalışma teyidi:
curl -s http://localhost:8080 | grep "Multi-Stage Go mikroservisi basariyla calisiyor"
```

---

## Temizlik

```bash
docker rm -f go-server 2>/dev/null || true
docker rmi multistage-app:optimized 2>/dev/null || true
rm -rf /tmp/multistage-demo
```
