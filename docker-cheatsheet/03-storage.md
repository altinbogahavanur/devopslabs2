# 💾 Docker Depolama Komutları (Storage Cheatsheet)

Named Volume, Bind Mount ve tmpfs karşılaştırması, veri kalıcılığı ve yedekleme komutları.

---

## 🏛️ Depolama Türleri Karşılaştırma Tablosu

| Depolama Türü | Host Konumu | Yönetici | En İdeal Kullanım Senaryosu |
| :--- | :--- | :--- | :--- |
| **Named Volume** | `/var/lib/docker/volumes/` | Docker Motoru | Veritabanları (Postgres, MySQL), üretim kalıcı verileri, yüksek I/O |
| **Bind Mount** | Host üzerinde herhangi bir path (Örn: `$(pwd)`) | Kullanıcı / OS | Kaynak kod hot-reload, yerel konfigürasyon (`nginx.conf`) bağlama |
| **tmpfs Mount** | Yalnızca Host RAM (Bellek) | Linux Çekirdeği | Hassas geçici anahtarlar, oturum cache'i, yüksek hızlı geçici işlemler |

---

## 1. Named Volume Yönetimi

Docker tarafından yönetilen, konteyner silinse bile silinmeyen güvenli disk alanlarıdır.

### Yeni Bir Volume Oluşturma
```bash
docker volume create pg_data
```

### Mevcut Volume'leri Listeleme
```bash
docker volume ls
```

### Volume Ayrıntılarını ve Host Yolunu Görme (`inspect`)
```bash
docker volume inspect pg_data
```
* **Önemli Çıktı:** `"Mountpoint": "/var/lib/docker/volumes/pg_data/_data"`

### Volume'ü Konteynere Bağlama (Kalıcı Veritabanı)
```bash
# Kısa sözdizim (-v):
docker run -d --name postgres-db -v pg_data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres:16-alpine

# Modern sözdizim (--mount):
docker run -d --name postgres-db --mount type=volume,source=pg_data,target=/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres:16-alpine
```

### Belirli Bir Volume'ü Silme (Konteyner Durmuş Olmalıdır)
```bash
docker volume rm pg_data
```

### Hiçbir Konteyner Tarafından Kullanılmayan Tüm Boş Volume'leri Temizleme
```bash
docker volume prune -f
```

---

## 2. Bind Mount Yönetimi

Host üzerindeki belirli bir klasörü doğrudan konteyner içine yansıtarak canlı dosya paylaşımı sağlar.

### Geliştirme Ortamı İçin Canlı Kod Bağlama (Hot-Reload)
```bash
docker run -d --name my-web -p 8080:80 -v $(pwd)/html:/usr/share/nginx/html nginx:alpine
```
* **Açıklama:** Host'taki `html` klasöründe yapılan her değişiklik anında tarayıcıya yansır.

### Salt Okunur (Read-Only) Bind Mount
```bash
docker run -d --name my-web -p 8080:80 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro nginx:alpine
```
* **Açıklama:** `:ro` bayrağı sayesinde konteyner içindeki bir process host'taki konfigürasyonu değiştiremez (Güvenlik standardı).

---

## 3. tmpfs (Bellek / RAM) Mount

Diske hiçbir şey yazmadan doğrudan RAM üzerinde geçici depolama alanı açar; konteyner durduğunda silinir.

### RAM Üzerinde 64 MB Güvenli Geçici Alan Açma
```bash
docker run -d --name cache-app --tmpfs /tmp:rw,noexec,nosuid,size=64m redis:alpine
```
* **Açıklama:** Diske I/O yükü bindirmez; hassas şifreler veya geçici önbellek için en hızlı ve güvenli çözümdür.

---

## 4. Volume Yedekleme ve Afet Kurtarma (Disaster Recovery)

Volume verilerini host üzerine `.tar.gz` olarak arşivleme ve sıfırdan geri yükleme (Helper Pattern).

### Volume'ü `.tar.gz` Arşivi Olarak Yedekleme
```bash
docker run --rm \
  -v pg_data:/source:ro \
  -v $(pwd):/backup \
  alpine tar -czf /backup/pg_data_backup.tar.gz -C /source .
```

### `.tar.gz` Arşivinden Yeni Bir Volume'e Geri Yükleme (Restore)
```bash
# 1. Yeni boş volume oluşturun:
docker volume create pg_data_restored

# 2. Arşivi volume içine açın:
docker run --rm \
  -v pg_data_restored:/target \
  -v $(pwd):/backup \
  alpine tar -xzf /backup/pg_data_backup.tar.gz -C /target
```
