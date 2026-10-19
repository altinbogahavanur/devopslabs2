# LAB-DOC-03-03 — Go (Golang) Mikroservisini Multi-Stage ve Scratch ile Dockerize Etme

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `golang:1.23-alpine`, `scratch`, `curl` | 8080 |

---

## 1. Uygulama Hakkında

Go (Golang), derlendiğinde harici hiçbir kütüphaneye veya runtime motoruna (JVM, Node.js, Python yorumlayıcısı vb.) ihtiyaç duymayan **statik ikili (binary)** dosyalar üretebilir.

Eğer Go uygulamasını tek aşamalı (`golang:1.23`) imaj içinde çalıştırırsanız, nihai imaj boyutu **800 MB - 1 GB** civarında olur. Oysa üretimde Go SDK'sına, derleyicisine veya paket yöneticisine ihtiyaç yoktur; sadece üretilen birkaç megabaytlık binary yeterlidir.

**Amaç:** **Multi-Stage Build** kullanarak, birinci aşamada derlenen ikili dosyayı tamamen boş bir imaj olan **`scratch`** veya hafif **`distroless`** katmanına aktarmak ve imaj boyutunu **~8 MB** seviyesine indirmektir.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Derleme ve Çalıştırma

Dockerfile direktiflerini kurgulamak için referans Linux akışı:

```bash
# 1. Ubuntu'ya Go SDK kurulması (Geliştirme / Derleme Aşaması)
sudo apt update && sudo apt install -y golang-go

# 2. Çalışma dizini ve kodların yerleşimi
mkdir -p /app && cd /app
cp -r /path/to/source/* /app/

# 3. Bağımlılıkların çözümlenmesi
go mod download

# 4. Statik CGO bağımlılığı olmayan optimize ikili dosya derleme
CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server main.go

# 5. DERLEYİCİYE ARTIK İHTİYAÇ YOKTUR!
# Üretim makinesine sadece 'server' binary dosyası kopyalanır ve çalıştırılır:
PORT=8080 ./server
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Multi-Stage Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| Derleyici Kurulumu | `FROM golang:1.23-alpine AS builder` | 1. Aşama (Builder): Sadece derleme için kullanılır |
| Bağımlılık İndirme | `COPY go.mod go.sum* ./ && RUN go mod download` | Bağımlılık katmanı önbelleğe alınır |
| Statik Derleme | `RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o server .` | `-s -w` ile debug sembolleri silinir, binary küçülür |
| **Aşama Değişimi** | **`FROM scratch`** | 2. Aşama (Runtime): 0 baytlık tertemiz temel |
| Binary Aktarımı | `COPY --from=builder /app/server /server` | **Sadece 8 MB'lık binary kopyalanır!** |
| Başlatma | `ENTRYPOINT ["/server"]` | Kabuksuz doğrudan binary çalıştırılır |

---

## 4. Görevler (Tasks)

1. `main.go` ve `go.mod` dosyalarını inceleyin.
2. 2 aşamalı bir `Dockerfile` yazın:
   * **1. Aşama:** `golang:1.23-alpine AS builder` (Derleme aşaması)
   * **2. Aşama:** `scratch` (Çalışma zamanı)
3. İmajı `go-microservice:v1.0` adıyla derleyin.
4. `docker images go-microservice:v1.0` ile imaj boyutunun **10 MB'ın altında** olduğunu doğrulayın.
5. Konteyneri başlatın ve `curl http://localhost:8080/health` ile doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: CGO_ENABLED=0 Neden Zorunludur?</summary>

Go varsayılan olarak bazı C sistem kütüphanelerini (`glibc`) dinamik bağlar. `CGO_ENABLED=0` dendiğinde tüm işletim sistemi çağrıları saf Go ile derlenir; böylece içinde hiçbir Linux kütüphanesi bulunmayan boş `scratch` imajında bile sorunsuz çalışır.
</details>

<details>
<summary>💡 İpucu 2: -ldflags="-s -w" Parametresi</summary>

`-s` sembol tablosunu (symbol table), `-w` ise DWARF debug bilgilerini kaldırır. Bu bayraklar binary dosya boyutunu yaklaşık %30-40 oranında küçültür.
</details>

---

## 6. Referans Çözüm

<details>
<summary>🎯 Referans Multi-Stage Dockerfile</summary>

**`Dockerfile`:**
```dockerfile
# ==========================================
# 1. AŞAMA: DERLEYİCİ (BUILDER)
# ==========================================
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Bağımlılıkları önbelleğe alma
COPY go.mod go.sum* ./
RUN go mod download

# Kaynak kodları kopyalama
COPY . .

# Statik ve hafif binary derleme
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server .

# ==========================================
# 2. AŞAMA: ÇALIŞMA ZAMANI (RUNTIME - SCRATCH)
# ==========================================
FROM scratch

# Güvenli SSL/TLS sertifikaları için builder'dan ca-certificates kopyalanabilir
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Sadece derlenen binary dosya aktarılır
COPY --from=builder /app/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
```

**Derleme ve Doğrulama:**
```bash
# 1. İmajı derleme
docker build -t go-microservice:v1.0 .

# 2. İmaj boyutunu inceleme (yaklaşık 7-9 MB olmalıdır!)
docker images go-microservice:v1.0

# 3. Konteyneri çalıştırma
docker run -d --name my-go-app -p 8080:8080 go-microservice:v1.0

# 4. İstek atma
curl -i http://localhost:8080/health
```
</details>

---

## 7. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:8080/
```

* **JSON Çıktısı:**
```json
{
  "message": "Go Microservice Basariyla Calisiyor! (Multi-Stage / Scratch)",
  "go_version": "go1.23...",
  "os": "linux",
  "arch": "...",
  "timestamp": "..."
}
```
* **İmaj Boyut Başarısı:** `docker images go-microservice:v1.0` çıktısında `SIZE` sütunu **< 10MB** olmalıdır.
