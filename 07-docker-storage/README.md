# LAB-07 — Docker Storage: Named Volume, Host Bind Mount ve Bellek İçi tmpfs

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `postgres:17-alpine`, `busybox` | `-` |

---

## Adım Adım Uygulama

### Adım 1: Named Volume ile Veritabanı Başlatma ve Veri Ekleme

```bash
# 1. Volume oluşturma ve inceleme
docker volume create pgdata
docker volume inspect pgdata

# 2. PostgreSQL'i volume'a bağlayarak çalıştırma
docker run -d --name db -e POSTGRES_PASSWORD=secret -v pgdata:/var/lib/postgresql/data postgres:17-alpine

# 3. Tablo oluşturup veri ekleme
sleep 4
docker exec db psql -U postgres -c "CREATE TABLE orders (id int, item text); INSERT INTO orders VALUES (1, 'Server');"
```

---

### Adım 2: Konteyneri Silip Kalıcılığı Doğrulama

```bash
# 1. Çalışan veritabanı konteynerını tamamen silin
docker rm -f db

# 2. Aynı pgdata volume'unu bağlayarak yeni bir konteyner başlatın
docker run -d --name db-new -e POSTGRES_PASSWORD=secret -v pgdata:/var/lib/postgresql/data postgres:17-alpine

# 3. Verinin korunduğunu sorgulayın
sleep 4
docker exec db-new psql -U postgres -c "SELECT * FROM orders;"
```

---

### Adım 3: Host Bind Mount ile Canlı Dizin Paylaşımı

```bash
# Mevcut çalışma dizinini konteyner içine bağlayarak listeleme
docker run --rm -v "$PWD:/work" busybox ls -la /work
```

---

### Adım 4: Bellek İçi (tmpfs) RAM Depolama

Geçici veya hassas verileri ana makinenin fiziksel belleğinde (RAM) tutmak için `tmpfs` kullanılır:

```bash
# 64 MB RAM disk tahsis ederek dosya yazma ve okuma testi
docker run --rm --tmpfs /cache:rw,size=64m busybox sh -c "echo 'ram disk verisi' > /cache/token && cat /cache/token"
```

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker rm -f db-new 2>/dev/null || true
docker volume rm pgdata 2>/dev/null || true
```
