# LAB-04 — Çok Dilli (Polyglot) Uygulama Paketleme (App Dockerization)

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 60 dakika | `multi-stage`, `scratch`, `node`, `python`, `go`, `java` | `3000, 8000, 8080` |

---

## Diller ve Mimari Kapsam

| No | Klasör | Dil / Çatı | Temel Odak ve Dockerization Pratiği |
|:---:|:---|:---|:---|
| **01** | [`01-nodejs`](01-nodejs/README.md) | **Node.js (Express)** | Katman önbelleği, non-root `USER node`, slim base imaj |
| **02** | [`02-python`](02-python/README.md) | **Python (FastAPI)** | `PYTHONDONTWRITEBYTECODE=1`, `PYTHONUNBUFFERED=1`, non-root `appuser`, no-cache pip |
| **03** | [`03-golang`](03-golang/README.md) | **Go (Golang)** | Multi-stage build (`golang:alpine` ➔ `scratch`), `CGO_ENABLED=0`, **~8 MB imaj boyutu** |
| **04** | [`04-java-petclinic`](04-java-petclinic/README.md) | **Java (Spring Boot PetClinic)** | Maven multi-stage, **Layered JAR (`layertools`)**, JVM Container Tuning |
| **05** | [`05-dotnet`](05-dotnet/README.md) | **.NET 8 (ASP.NET Core)** | SDK ➔ Alpine Runtime multi-stage build, yerleşik `app` kullanıcısı |
| **06** | [`06-php`](06-php/README.md) | **PHP 8.3 + Composer** | Multi-stage Composer, `--optimize-autoloader`, yerleşik OPcache hızlandırma |
| **07** | [`07-frontend-react`](07-frontend-react/README.md) | **React SPA + Vite + Nginx** | Multi-stage derleme, statik dosya sunumu, SPA `try_files` yönlendirmesi |

---

## Adım Adım Uygulama

### 1. Go (Golang) Scratch Uygulaması

```bash
cd 03-golang
docker build -t go-app:v1 .
docker images go-app:v1
docker run -d --name go-demo -p 8080:8080 go-app:v1
curl http://localhost:8080/health
cd ..
```

---

### 2. Python (FastAPI) Uygulaması

```bash
cd 02-python
docker build -t py-app:v1 .
docker run -d --name py-demo -p 8000:8000 py-app:v1
docker exec py-demo whoami
curl http://localhost:8000/health
cd ..
```

---

### 3. Node.js (Express) Uygulaması

```bash
cd 01-nodejs
docker build -t node-app:v1 .
docker run -d --name node-demo -p 3000:3000 node-app:v1
curl http://localhost:3000/health
cd ..
```

---

### 4. Java Spring Boot (Layered JAR)

```bash
cd 04-java-petclinic
cat Dockerfile
# Multi-stage layertools katmanlarını inceleyin
cd ..
```

---

## Temizlik

Çalıştırılan test konteynerlarını temizleyin:

```bash
docker rm -f go-demo py-demo node-demo 2>/dev/null || true
docker rmi go-app:v1 py-app:v1 node-app:v1 2>/dev/null || true
```
