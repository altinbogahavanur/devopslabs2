# LAB-DOC-07-01 — Kalıcı Depolama: Named Volumes ve Host Bind Mounts

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `postgres:17-alpine`, `nginx:alpine` | 8080 |

---

## Amaç

- Konteynerlar silindiğinde veya yeniden başlatıldığında verilerin kaybolmasını engellemek.
- Docker tarafından yönetilen **Named Volume** ile ana makine dizini eşleyen **Host Bind Mount** arasındaki farkları kavramak.
- Güvenlik amacıyla salt-okunur (`:ro`) bağlama yapmak.

---

## Ön Koşullar

- LAB-DOC-06 tamamlanmış olmalıdır.
- Host üzerinde `8080` portu boşta olmalıdır.

---

## Mimari ve Depolama Modeli

```text
1. NAMED VOLUME (Docker Yönetir)
   /var/lib/docker/volumes/pgdata/_data  <════>  /var/lib/postgresql/data (Konteyner)

2. HOST BIND MOUNT (Geliştirici Yönetir)
   $(pwd)/html                           <════>  /usr/share/nginx/html (Konteyner:ro)
```

---

## Adım Adım Uygulama Rehberi

### 1. Named Volume ile Kalıcı PostgreSQL Başlatma
```bash
# 1. Named volume oluşturun:
docker volume create pg-storage

# 2. Volume'u bağlayarak veritabanını başlatın:
docker run -d --name db-persisted -v pg-storage:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=StorageLab2026! \
  postgres:17-alpine

# 3. Tablo ve veri oluşturun:
docker exec -i db-persisted psql -U postgres -c "CREATE TABLE test (id serial, msg text);"
docker exec -i db-persisted psql -U postgres -c "INSERT INTO test (msg) VALUES ('Kalıcı Veri');"
```

### 2. Kalıcılık Testi (Konteyneri Silip Yeni Konteyner Bağlama)
```bash
# Konteyneri tamamen silin:
docker rm -f db-persisted

# Aynı volume ile YENİ bir konteyner açın:
docker run -d --name db-recovered -v pg-storage:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=StorageLab2026! \
  postgres:17-alpine

# Verinin silinmediğini teyit edin:
docker exec -i db-recovered psql -U postgres -c "SELECT * FROM test;"
```

### 3. Host Bind Mount ve Salt-Okunur (:ro) Modu
```bash
# 1. Host üzerinde bir dizin açın:
mkdir -p /tmp/web-content
echo "<h1>Host Bind Mount ile Canli Yayinda!</h1>" > /tmp/web-content/index.html

# 2. Dizini konteynere :ro (read-only) olarak bağlayın:
docker run -d --name web-bind -p 8080:80 \
  -v /tmp/web-content:/usr/share/nginx/html:ro \
  nginx:alpine

# 3. Test edin:
curl http://localhost:8080

# 4. Konteyner içinden dosyayı değiştirmeyi deneyin (Hata vermelidir!):
docker exec web-bind sh -c "echo hack > /usr/share/nginx/html/index.html" 2>&1 || true
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker exec -i db-recovered psql -U postgres -c "SELECT msg FROM test;" | grep "Kalıcı Veri"
# Çıktıda 'Kalıcı Veri' görülmelidir.
```

---

## Temizlik

```bash
docker rm -f db-recovered web-bind 2>/dev/null || true
docker volume rm pg-storage 2>/dev/null || true
rm -rf /tmp/web-content
```
