# LAB-05 — İmaj/Volume Yedekleme (Backup & Restore) ve Kurumsal Registry

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 50 dakika | `docker-ce`, `postgres:17-alpine`, `registry:2.8`, `harbor` | `5000, 8085` |

---

## Mimari ve Yedekleme Modelleri

```text
1. İMAJ YEDEKLEME (save / load)
   [ my-app:v1 (Çok Katmanlı İmaj) ] ──── docker save ────> [ my-app.tar ] ──── docker load ────> [ my-app:v1 ]

2. VOLUME YEDEKLEME (Helper Container Modeli)
   [ NAMED VOLUME: pgdata ]
              │
              │ -v pgdata:/source:ro (Salt-Okunur)
              ▼
   +───────────────────────────────────────────────+
   | GEÇİCİ YARDIMCI KONTEYNER (alpine)            |
   | - tar -czf /backup/db-backup.tar.gz -C /source|
   +───────────────────────────────────────────────+
              │
              │ -v $(pwd)/backups:/backup
              ▼
   [ HOST DİSKİ: ./backups/db-backup.tar.gz ]
```

---

## Adım Adım Uygulama

### Adım 1: İmaj Yedekleme (`docker save`) ve Geri Yükleme (`docker load`)

```bash
# 1. Test amaçlı bir imaj hazırlama
docker pull alpine:latest
docker tag alpine:latest my-backup-app:v1.0

# 2. İmajı katmanları ve metadata'sı ile birlikte .tar arşivine çıkarma
mkdir -p backups
docker save -o backups/my-backup-app.tar my-backup-app:v1.0
ls -lh backups/my-backup-app.tar

# 3. Yerel imajı tamamen silme
docker rmi my-backup-app:v1.0

# 4. İmajı arşiv dosyasından geri yükleme
docker load -i backups/my-backup-app.tar

# 5. Geri yüklendiğini doğrulama
docker images my-backup-app:v1.0
```

---

### Adım 2: Konteyner Dosya Sistemini Dışa Aktarma (`export` / `import`)

```bash
# 1. Çalışan bir konteyner başlatma
docker run -d --name export-demo alpine sh -c "echo 'sabit veri' > /app-data.txt; sleep 3600"

# 2. Konteyner dosya sistemini tek düz katman (flattened) olarak dışa aktarma
docker export export-demo > backups/container-export.tar

# 3. Arşivi yeni bir imaj olarak içe aktarma
docker import backups/container-export.tar imported-app:v1.0

# 4. İki imaj arasındaki farkı inceleme
docker images | grep -E "my-backup-app|imported-app"
```

---

### Adım 3: PostgreSQL Named Volume Yedeği Alma (Helper Container)

```bash
# 1. Volume oluşturup PostgreSQL veritabanı başlatma
docker volume create db-prod-data
docker run -d --name prod-db \
  -e POSTGRES_PASSWORD=secret \
  -v db-prod-data:/var/lib/postgresql/data \
  postgres:17-alpine

# 2. Veritabanının açılmasını bekleyip tablo ve veri ekleme
sleep 4
docker exec prod-db psql -U postgres -c "CREATE TABLE customers (id int, name text); INSERT INTO customers VALUES (1, 'Ahmet Yilmaz'), (2, 'Ayse Demir');"

# 3. Yardımcı bir alpine konteyneri ile volume'u salt-okunur bağlayıp tar.gz yedeği alma
docker run --rm \
  -v db-prod-data:/source:ro \
  -v $(pwd)/backups:/backup \
  alpine tar -czf /backup/db-prod-backup.tar.gz -C /source .

ls -lh backups/db-prod-backup.tar.gz
```

---

### Adım 4: Felaket Kurtarma Simülasyonu (Disaster Recovery)

```bash
# 1. Veritabanı konteynerını ve volume'u tamamen silin!
docker rm -f prod-db
docker volume rm db-prod-data

# 2. Sıfırdan yeni bir boş volume oluşturma
docker volume create db-prod-restored

# 3. Yardımcı konteyner ile arşivi yeni volume içine açma
docker run --rm \
  -v db-prod-restored:/target \
  -v $(pwd)/backups:/backup \
  alpine sh -c "tar -xzf /backup/db-prod-backup.tar.gz -C /target"

# 4. Kurtarılan volume ile yeni veritabanı başlatma
docker run -d --name restored-db \
  -e POSTGRES_PASSWORD=secret \
  -v db-prod-restored:/var/lib/postgresql/data \
  postgres:17-alpine

# 5. Verilerin kurtarıldığını sorgulama
sleep 4
docker exec restored-db psql -U postgres -c "SELECT * FROM customers;"
```

---

### Adım 5: Yerel OCI Registry Kurulumu ve İmaj Yükleme

```bash
# 1. Resmi OCI Registry konteynerini Port 5000'de başlatma
docker run -d -p 5000:5000 --restart=always --name local-registry registry:2.8

# 2. Bir imajı yerel registry için etiketleme
docker tag my-backup-app:v1.0 localhost:5000/my-backup-app:v1.0

# 3. İmajı yerel depoya gönderme (push)
docker push localhost:5000/my-backup-app:v1.0

# 4. Registry içindeki imaj kataloğunu sorgulama
curl -s http://localhost:5000/v2/_catalog
```

---

### Adım 6: VMware Harbor Kurulum Yapılandırması

Harbor kurumsal registry stack'i için temel yapılandırma parametreleri:

```bash
# Harbor compose stack klasörüne geçiş
cd harbor/
cat docker-compose.yml | head -n 30
# Harbor bileşenleri: core, portal, registry, trivy, redis, database
cd ..
```

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker rm -f restored-db export-demo local-registry 2>/dev/null || true
docker volume rm db-prod-restored 2>/dev/null || true
docker rmi my-backup-app:v1.0 imported-app:v1.0 localhost:5000/my-backup-app:v1.0 2>/dev/null || true
rm -rf backups
```
