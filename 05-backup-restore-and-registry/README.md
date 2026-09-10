# LAB-05 — İmaj/Volume Yedekleme (Backup & Restore) ve Kurumsal Registry

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 50 dakika | `docker-ce`, `postgres:17-alpine`, `registry:2.8`, `harbor` | `5000, 8085` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 57 & 58, Lab 3C); kapalı devre (air-gapped/internetsiz) veya felaket kurtarma (disaster recovery) senaryolarında Docker imajlarını ve kalıcı verilerini (Named Volumes) eksiksiz yedekleyip geri yüklemek, Docker Hub üzerinde public/private depoları yönetmek ve yerel OCI Registry ile kurumsal VMware Harbor mimarisini kavramaktır:

1. **İmaj Yedekleme (`save` / `load`):** Tüm katmanları, etiketleri ve geçmişi koruyarak `.tar` formatında arşivleme.
2. **Konteyner Dışa Aktarma (`export` / `import`):** Çalışan dosya sistemini tek düz katman (flattened) olarak çıkarma.
3. **Volume Yedekleme ve Kurtarma:** Geçici bir yardımcı konteyner (`alpine`) kullanarak PostgreSQL veritabanı yedeğini alma ve silinen veriyi sıfırdan geri yükleme.
4. **Registry Yönetimi:** Yerel OCI Registry ve kurumsal Harbor Registry yeteneklerini (RBAC, Dahili Trivy, Robot Hesapları) inceleme.

---

## 2. Ön Koşullar

* Docker Engine çalışır durumda olmalıdır.
* Port 5000 ve 8085 boşta olmalıdır.

---

## 3. Mimari ve Karşılaştırma Modelleri

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

### Karşılaştırma: `save/load` vs `export/import`

| Özellik | `docker save` / `docker load` | `docker export` / `docker import` |
|:---|:---|:---|
| **Hedef Nesne** | Docker İmajı | Çalışan Konteyner Dosya Sistemi |
| **Katmanlar (Layers)** | Tüm katmanlar korunur | Tüm katmanlar tek düz katmanda birleşir (Flattened) |
| **Metadata & Geçmiş** | `ENV`, `WORKDIR`, `CMD`, geçmiş korunur | Metadata silinir, `import` sırasında yeniden girilmelidir |
| **Kullanım Amacı** | İmajları internet olmayan sunuculara taşımak | Çalışan konteynerın salt dosya yedeğini almak |

---

## 4. Görevler (Tasks)

1. `alpine:latest` imajını `my-app:v1.0` olarak etiketleyin, `docker save` ile `.tar` dosyasına kaydedin. İmajı yerelden silip `docker load` ile geri yükleyin.
2. `db-prod-data` adında bir Named Volume oluşturup PostgreSQL başlatın ve test verisi yazın.
3. Yardımcı bir `alpine` konteyneri kullanarak volume içeriğini `db-prod-backup.tar.gz` olarak yedekleyin.
4. **Felaket Kurtarma:** Konteyneri ve volume'u tamamen silin. Yeni bir volume oluşturup arşivden geri yükleyin ve verilerin kaybolmadığını kanıtlayın.
5. `private-registry/docker-compose.yml` stack'ini ayağa kaldırarak `localhost:5000` adresine bir imaj pushlayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Volume Yedeğinde Salt-Okunur (:ro) Bağlama</summary>

Yedek alırken `-v db-prod-data:/source:ro` şeklinde `:ro` (read-only) bayrağı eklemek, yedekleme sırasında dosya sisteminde kilitlenme veya bozulma yaşanmasını engeller.
</details>

<details>
<summary>💡 İpucu 2: Kurumsal Dünyada Neden Harbor?</summary>

Harbor; basit bir depolama servisi olmanın ötesinde, imajlar yayınlanmadan önce dahili Trivy ile zafiyet taraması yapar, Cosign ile imza doğrular ve CI/CD süreçleri için süreli/kısıtlı Robot Hesapları sunar. Detaylar için `harbor/` dizinini inceleyin.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

```bash
docker exec db-recovered psql -U postgres -d company -c "SELECT count(*) FROM orders;"
```

* **Beklenen Sonuç:** `2` dönmelidir. Tablo ve veriler eksiksiz kurtarılmıştır.

---

## 7. Temizlik

```bash
docker rm -f db-recovered 2>/dev/null || true
docker volume rm db-recovered-data 2>/dev/null || true
rm -rf ./backups /tmp/my-backup-app.tar
```
