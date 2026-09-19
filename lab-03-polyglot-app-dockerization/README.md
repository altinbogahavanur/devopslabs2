# LAB-DOC-03 — Çok Dilli (Polyglot) Uygulama Paketleme Alıştırması

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta - İleri | 45 Dakika | `multi-stage`, `scratch`, `node`, `python`, `go`, `java`, `dotnet`, `php` | 3000, 8000, 8080 |

> **Önemli Erişim Notu:** Başlattığınız mikroservisleri test ederken tarayıcınızdan `http://<SUNUCU-IP>:<PORT>` veya yerel terminalden `curl http://localhost:<PORT>` komutunu kullanabilirsiniz.

---

## 1. Amaç

Bu laboratuvarın amacı; modern yazılım dünyasında en çok kullanılan **7 farklı programlama dili ve çalışma zamanının (runtime)** kaynak kod seviyesinden başlayarak üretime hazır, optimize ve güvenli şekilde nasıl Dockerize edildiğini kavramaktır:

1. **Derlenen Diller (Compiled):** Go ve .NET için `scratch` veya Alpine tabanlı ultra hafif multi-stage imajlar üretmek.
2. **Yorumlanan Diller (Interpreted):** Python, Node.js ve PHP için katman önbelleği ve root olmayan kullanıcı (`non-root`) yapılandırması.
3. **Kurumsal / JVM Mimarisi:** Java Spring Boot PetClinic uygulamasında `layertools` ile katmanlı JAR (Layered JAR) ve JVM bellek optimizasyonu (`-XX:MaxRAMPercentage=75.0`).
4. **Tek Sayfa Uygulamaları (SPA):** React + Vite uygulamasını derleyip hafif Nginx imajına paketlemek.

---

## 2. Ön Koşullar

* `lab-02-dockerfile-and-caching` tamamlanmış olmalıdır.
* Docker Engine ve BuildKit aktif olmalıdır (`docker info`).
* Host üzerinde `3000`, `8000` ve `8080` portları boşta olmalıdır.

---

## 3. Diller ve Mimari Kapsam

| No | Klasör | Dil / Çatı | Temel Odak ve Dockerization Pratiği |
|:---:|:---|:---|:---|
| **01** | [`01-nodejs`](01-nodejs/README.md) | **Node.js (Express)** | Basitleştirilmiş `npm install`, non-root `USER node`, slim base imaj |
| **02** | [`02-python`](02-python/README.md) | **Python (FastAPI)** | `PYTHONDONTWRITEBYTECODE=1`, `PYTHONUNBUFFERED=1`, non-root `appuser`, no-cache pip |
| **03** | [`03-golang`](03-golang/README.md) | **Go (Golang)** | Multi-stage build (`golang:alpine` ➔ `scratch`), `CGO_ENABLED=0`, **~8 MB imaj boyutu** |
| **04** | [`04-java-petclinic`](04-java-petclinic/README.md) | **Java (Spring Boot PetClinic)** | Maven multi-stage, **Layered JAR (`layertools`)**, JVM Container Tuning |
| **05** | [`05-dotnet`](05-dotnet/README.md) | **.NET 8 (ASP.NET Core)** | SDK ➔ Alpine Runtime multi-stage build, yerleşik `app` kullanıcısı |
| **06** | [`06-php`](06-php/README.md) | **PHP 8.3 + Composer** | Multi-stage Composer, `--optimize-autoloader`, yerleşik OPcache hızlandırma |
| **07** | [`07-frontend-react`](07-frontend-react/README.md) | **React SPA + Vite + Nginx** | Multi-stage derleme, statik dosya sunumu, SPA `try_files` yönlendirmesi |

---

## 4. Görevler (Tasks)

1. **Go Scratch Derlemesi:** `03-golang` dizinindeki Go uygulamasını inceleyin; `Dockerfile` ile derleyip imaj boyutunun 10 MB altında olduğunu doğrulayın.
2. **Python FastAPI ve Non-Root:** `02-python` dizinindeki FastAPI uygulamasını derleyin; non-root çalıştığını ve `/health` ucunun yanıt verdiğini test edin.
3. **Node.js Express ve Caching:** `01-nodejs` dizinindeki uygulamayı derleyip `3000` portundan test edin.
4. **Spring Boot Layered JAR:** `04-java-petclinic` dizinindeki Spring Boot uygulamasını derleyip `layertools` katman yapısını gözlemleyin.
5. **Konteyner Temizliği:** Çalıştırılan test konteynerlarını temizleyin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Go Neden scratch İmajında Çalışabilir?</summary>

Go dili kaynak kodu doğrudan makine koduna (statically linked binary) derler. `CGO_ENABLED=0` verildiğinde C standart kütüphanelerine (libc/glibc) bağımlılık sıfırlanır. Bu sayede hiçbir işletim sistemi dosyası barındırmayan tamamen boş `scratch` imajında 5-8 MB boyutunda çalışabilir.
</details>

<details>
<summary>💡 İpucu 2: Java Spring Boot Layered JAR Avantajı</summary>

Geleneksel fat-JAR yönteminde 50 MB'lık uygulamanın 45 MB'ı kütüphane (dependencies), 5 MB'ı uygulama kodudur. `layertools` ile kütüphaneler ayrı katmana, uygulama kodu ayrı katmana konur. Koddaki küçük bir değişiklikte sadece 5 MB'lık katman yeniden derlenir ve transfer edilir.
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Komutlar (Tıklayınca Açılır)</summary>

### Adım 1: Go Scratch Uygulamasını Derleme ve Çalıştırma
```bash
cd ~/docker-labs/04-polyglot-app-dockerization/03-golang
docker build -t go-app:v1 .
docker images go-app:v1
docker run -d --name go-demo -p 8080:8080 go-app:v1
curl http://localhost:8080/health
```

### Adım 2: Python FastAPI Uygulamasını Derleme ve Doğrulama
```bash
cd ~/docker-labs/04-polyglot-app-dockerization/02-python
docker build -t py-app:v1 .
docker run -d --name py-demo -p 8000:8000 py-app:v1
docker exec py-demo whoami
curl http://localhost:8000/health
```

### Adım 3: Node.js Express Uygulamasını Derleme
```bash
cd ~/docker-labs/04-polyglot-app-dockerization/01-nodejs
docker build -t node-app:v1 .
docker run -d --name node-demo -p 3000:3000 node-app:v1
curl http://localhost:3000/health
```

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla çok dilli imaj boyutlarını ve yanıtları doğrulayın:

```bash
# 1. İmaj boyutlarını karşılaştırma
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "go-app|py-app|node-app"

# 2. Servis sağlık yanıtları
curl -s http://localhost:8080/health
curl -s http://localhost:8000/health
curl -s http://localhost:3000/health
```

* **Beklenen Başarı Çıktısı:**
  * `go-app:v1` boyutu **~10 MB veya daha küçük** görünmelidir.
  * Tüm `/health` uçları `{"status": "ok"}` veya `200 OK` dönmelidir.

---

## 8. Temizlik

Laboratuvar tamamlandığında çalışan konteynerları ve test imajlarını temizleyin:

```bash
docker rm -f go-demo py-demo node-demo 2>/dev/null || true
docker rmi go-app:v1 py-app:v1 node-app:v1 2>/dev/null || true
```
