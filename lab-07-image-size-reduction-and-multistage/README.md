# LAB-07: İmaj Boyutu Küçültme ve Multi-Stage Build

## 🎯 Labın Amacı
Üretim ortamında derleyici ve SDK gibi ağır bileşenlerin nihai imajda kalmasını engellemek; **Multi-Stage Build** deseni ile imaj boyutunu **~850 MB'tan ~12 MB'a düşürmek**, BuildKit katman önbelleklemesini (`CACHED`) ve `.dockerignore` mekanizmasını uygulamak.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Host üzerinde **8080** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Katman Önbellekleme (Layer Caching) Mantığı
Bağımlılıkları kaynak koddan önce kopyalamak, kod her değiştiğinde gereksiz paket indirmelerini önler:

```text
KÖTÜ:
COPY . .                  ──> [Kod değiştiğinde sonraki her adım baştan çalışır]
RUN npm install           ──> [45 saniye sürer!]

OPTİMİZE:
COPY package*.json ./     ──> [Değişmediyse: ---> CACHED ⚡ (0.1 sn)]
RUN npm install
COPY . .                  ──> [Sadece kod kopyalanır: Hızlı!]
```

Bulunduğunuz dizindeki Node.js benchmark testini inceleyebilirsiniz:
```bash
cd lab-07-image-size-reduction-and-multistage
cat Dockerfile.optimized
```

### 2. .dockerignore ile Gereksiz Dosyaları Engelleme
Derleme bağlamına (build context) git geçmişi, node_modules veya hassas `.env` dosyalarının girmesini engelleyin:
```bash
cat .dockerignore
```

### 3. Tek Aşamalı (Single-Stage) Ağır İmajı Derleme
Go uygulamamızı tüm Go derleyicisini içeren standart yöntemle derleyelim:

```bash
docker build -f go-app/Dockerfile.single-stage -t go-heavy:1.0 ./go-app
```

### 4. Çok Aşamalı (Multi-Stage) Minimal İmajı Derleme
Aynı uygulamayı `builder` ve `runtime` aşamalarını ayırarak derleyelim:

```bash
docker build -f go-app/Dockerfile.multi-stage -t go-lightweight:1.0 ./go-app
```

### 5. Boyut Karşılaştırması (Büyük Fark!)
İki imajın boyutlarını terminalde kıyaslayın:

```bash
docker images | grep -E "go-heavy|go-lightweight"
```
*Gözlem: `go-heavy` yaklaşık **850 MB** iken, `go-lightweight` sadece **~12 MB** yer kaplar! (%98'den fazla tasarruf).*

### 6. Minimal İmajı Çalıştırma ve Doğrulama
```bash
docker run -d --name go-service -p 8080:8080 go-lightweight:1.0

curl http://localhost:8080
```

---

## ✅ Doğrulama (Verification)
- `docker images` listesinde `go-lightweight:1.0` imajının 15 MB altında olduğunu teyit edin.
- `curl http://localhost:8080` çağrısında `Multi-Stage Build Basariyla Calisiyor!` mesajının döndüğünü görün.

---

## 🧹 Temizlik
```bash
docker rm -f go-service 2>/dev/null || true
docker rmi go-heavy:1.0 go-lightweight:1.0 2>/dev/null || true
```
