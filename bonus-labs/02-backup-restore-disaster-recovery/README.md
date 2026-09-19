# BONUS-DOC-02 — İmaj ve Volume Yedekleme (save, load, export, import)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `alpine`, `tar` | - |

---

## Amaç

- İnternetsiz (air-gapped) ortamlara imaj taşımak için `docker save` ve `docker load` komutlarını kullanmak.
- Çalışan bir konteyner dosya sistemini düz arşiv olarak dışa aktarmak (`docker export`) ve içe aktarmak (`docker import`).
- Geçici bir yardımcı konteyner (`alpine`) ile Named Volume kalıcı verilerini `.tar.gz` olarak yedeklemek ve geri yüklemek.

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
1. İMAJ YEDEKLEME (save / load)
   [ my-app:v1 ] ── docker save ──> [ my-app.tar ] ── docker load ──> [ my-app:v1 ]

2. VOLUME YEDEKLEME (Helper Container Modeli)
   [ VOLUME: my-data ] ── -v my-data:/source:ro ──> [ alpine helper ] ── tar ──> [ /backup/data.tar.gz ]
```

---

## Adım Adım Uygulama Rehberi

### 1. İmaj Yedekleme ve Geri Yükleme (save / load)
```bash
# 1. Mevcut bir imajı .tar arşivi olarak diske kaydedin:
docker pull alpine:3.20
docker save -o /tmp/alpine-backup.tar alpine:3.20

# 2. İmajı yerelden silin:
docker rmi alpine:3.20

# 3. İmajı arşiv dosyasından geri yükleyin (Tüm katmanlar ve metaveriler korunur):
docker load -i /tmp/alpine-backup.tar

# Doğrulama:
docker images alpine:3.20
```

### 2. Volume Verisini Yedekleme (Helper Pattern)
```bash
# 1. Test amaçlı bir volume oluşturup içine veri yazın:
docker volume create app-data
docker run --rm -v app-data:/data alpine sh -c "echo 'DevOps 2026 Kalici Veri' > /data/db.txt"

# 2. Yardımcı bir konteyner ile volume'u host üzerindeki bir dizine tar.gz olarak yedekleyin:
mkdir -p /tmp/docker-backups
docker run --rm -v app-data:/source:ro -v /tmp/docker-backups:/target alpine \
  tar -czf /target/app-data-backup.tar.gz -C /source .

ls -lh /tmp/docker-backups/app-data-backup.tar.gz
```

### 3. Volume Verisini Geri Yükleme (Restore)
```bash
# 1. Orijinal volume'u silin:
docker volume rm app-data

# 2. Yeni bir volume oluşturup yedeği içine açın:
docker volume create restored-data
docker run --rm -v restored-data:/target -v /tmp/docker-backups:/source alpine \
  tar -xzf /source/app-data-backup.tar.gz -C /target

# 3. Verinin korunduğunu test edin:
docker run --rm -v restored-data:/data alpine cat /data/db.txt
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker run --rm -v restored-data:/data alpine cat /data/db.txt
# Çıktıda 'DevOps 2026 Kalici Veri' görülmelidir.
```

---

## Temizlik

```bash
docker volume rm restored-data 2>/dev/null || true
rm -rf /tmp/alpine-backup.tar /tmp/docker-backups
```
