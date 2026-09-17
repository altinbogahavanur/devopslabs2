# LAB-DOC-06-03 (Advanced) — Çoklu Ağ Mimarisi (DMZ) ve Network Aliases

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker-ce`, `busybox`, `nginx` | 8080 |

---

## Amaç

- Kurumsal mimarilerde uygulanan **DMZ (Yalıtılmış Bölge)** ağ modelini Docker üzerinde inşa etmek.
- Bir konteyneri aynı anda birden fazla ağa bağlamak (`docker network connect`).
- Veritabanını dış dünyadan ve frontend ağından tamamen izole ederek yalnızca backend API üzerinden erişilebilir kılmak.
- Ağ takma adları (`--network-alias`) ile esnek DNS çözümlemesi sağlamak.

---

## Ön Koşullar

- LAB-DOC-06-01 ve 02 tamamlanmış olmalıdır.
- Host üzerinde `8080` portu boşta olmalıdır.

---

## Mimari ve DMZ İzolasyon Modeli

```text
[İNTERNET / HOST PORT 8080]
              │
              ▼
+───────────────────────────+
| FRONTEND AĞI (front-net)  |
|  - [gateway-proxy]        | ──> Port 8080 üzerinden dışa açık
+─────────────┬─────────────+
              │
              ▼ (Her İki Ağa da Bağlı Tek Köprü: backend-api)
+───────────────────────────+
| BACKEND AĞI (back-net)    |
|  - [backend-api]          | ──> Hem front-net hem back-net'e bağlı
|  - [secure-database]      | ──> SADECE back-net'e bağlı (Dışa tamamen kapalı!)
+───────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. İzole Ağları Oluşturma
```bash
docker network create front-net
docker network create back-net
```

### 2. Veritabanını Sadece Arka Ağa Başlatma
```bash
docker run -d --name secure-db --network back-net \
  --network-alias db.internal \
  -e POSTGRES_PASSWORD=Secret2026! \
  postgres:17-alpine
```

### 3. Backend API'yi Başlatma ve İki Ağa da Bağlama
```bash
# Backend'i önce back-net'e bağlı başlatın:
docker run -d --name backend-api --network back-net alpine sleep 3600

# Ardından front-net ağına da bağlayın (Köprü görevi):
docker network connect front-net backend-api
```

### 4. Gateway Konteynerını Sadece Ön Ağa Başlatma
```bash
docker run -d --name gateway-proxy --network front-net -p 8080:80 nginx:alpine
```

### 5. DMZ İzolasyonunun Test Edilmesi
```bash
# 1. Gateway, backend-api ile haberleşebilmelidir:
docker exec gateway-proxy ping -c 2 backend-api

# 2. Gateway, secure-db'ye ASLA erişememelidir (İzolasyon kanıtı!):
docker exec gateway-proxy ping -c 1 -W 2 secure-db 2>&1 || true

# 3. Backend API ise secure-db'ye hem adı hem alias ile erişebilmelidir:
docker exec backend-api ping -c 2 db.internal
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker inspect secure-db -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}'
# Çıktı SADECE 'back-net' olmalıdır.
```

---

## Temizlik

```bash
docker rm -f gateway-proxy backend-api secure-db 2>/dev/null || true
docker network rm front-net back-net 2>/dev/null || true
```
