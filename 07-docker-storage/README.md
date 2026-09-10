# LAB-07 — Docker Storage: Named Volume, Host Bind Mount ve Bellek İçi tmpfs

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `postgres:17-alpine`, `busybox` | `-` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 65-73, Lab 5); Docker konteynerlarının katmanlı dosya sisteminde yazılabilir alanın (writable layer) neden geçici (ephemeral) olduğunu kavramak ve kalıcı ya da paylaşılan veriler için 3 temel depolama modelini uygulamalı olarak test etmektir:

1. **Named Volume (Kalıcı Depolama):** Docker tarafından yönetilen (`/var/lib/docker/volumes`), konteyner silinse bile silinmeyen bağımsız disk alanı.
2. **Host Bind Mount (Geliştirme & Dosya Paylaşımı):** Ana makinedeki (host) herhangi bir dizini (`$PWD:/work`) konteyner içine canlı bağlama.
3. **tmpfs Mount (Bellek İçi Geçici Depolama):** Hassas veya yüksek hızlı geçici verileri ana makinenin RAM'inde tutma, konteyner durduğu anda sıfırlama.
4. **`--mount` Sözdizimi:** Üretim ortamlarında `-v` yerine açık ve hatasız `--mount type=volume,source=...,target=...` kullanımını öğrenmek.

---

## 2. Ön Koşullar

* Docker Engine çalışır durumda olmalıdır (`docker info`).
* Temel SQL ve komut satırı bilgisi.

---

## 3. Depolama Tipleri Karşılaştırma Modeli

| Özellik | Named Volume | Bind Mount | tmpfs Mount |
|:---|:---|:---|:---|
| **Kalıcılık** | Evet (Container silinse de kalır) | Evet (Host diskinde kalır) | Hayır (RAM'dedir, silinir) |
| **Yönetici** | Docker Engine | Host İşletim Sistemi | Host RAM / Çekirdek |
| **Host Bağımlılığı** | Hayır (Taşınabilir) | Evet (Dizin yoluna bağımlı) | Hayır |
| **Tipik Kullanım** | Veritabanları (PostgreSQL, MySQL) | Kod geliştirme (Hot reload), konfigürasyon | Token, hassas geçici dosya, cache |

---

## 4. Görevler (Tasks)

1. **Named Volume Oluşturma:** `pgdata` isimli bir Docker Named Volume oluşturun ve `docker volume inspect` ile depolama yolunu inceleyin.
2. **Kalıcı Veritabanı:** `postgres:17-alpine` konteynerını `pgdata` volume'una bağlayarak başlatın ve içine `orders` tablosu açıp test verisi ekleyin.
3. **Kalıcılığı Kanıtlama (Disaster Simulation):** Veritabanı konteynerını `docker rm -f` ile tamamen silin. Aynı `pgdata` volume'unu bağlayarak `db-new` adıyla yeni bir konteyner başlatın ve verilerin korunduğunu kanıtlayın.
4. **Host Bind Mount:** Bulunduğunuz dizini (`$PWD`) `busybox` konteyneri içerisine `/work` olarak bind mount edin ve dosya listesini okuyun.
5. **Bellek İçi tmpfs Mount:** 64 MB boyutunda bir `tmpfs` RAM disk tahsis ederek içine dosya yazın ve test edin.
6. **Otomasyon Doğrulaması:** `scripts/verify-storage.sh` betiği ile tüm depolama tiplerini otomatik doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Neden -v yerine --mount Önerilir?</summary>

`-v pgdata:/data` sözdiziminde eğer `pgdata` yanlış yazılırsa Docker hata vermek yerine sessizce hostta yeni bir dizin açabilir. `--mount type=volume,source=pgdata,target=/data` sözdizimi ise açıkça tipi (`volume`, `bind`, `tmpfs`) belirtir ve production ortamlarında yazım hatalarını anında engeller.
</details>

<details>
<summary>💡 İpucu 2: Volume'lar Fiziksel Olarak Nerede Saklanır?</summary>

Linux üzerinde Docker volume'ları doğrudan `/var/lib/docker/volumes/<volume-adi>/_data` yolunda saklanır. Host işletim sisteminde root yetkisiyle doğrudan bu dizine erişilebilir.
</details>

<details>
<summary>💡 İpucu 3: Docker'da Yetkisiz Veri Kaybı (Volume Prune Tehlikesi)</summary>

`docker volume rm` veya `docker volume prune` komutları çalışan bir konteynere bağlı olmayan tüm Named Volume'ları kalıcı olarak siler. Üretim ortamlarında bu komutlar kesinlikle çok dikkatli çalıştırılmalıdır.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla verinin kurtarıldığını ve volume durumunu teyit edin:

```bash
# 1. Veri sorgulama
docker exec db-new psql -U postgres -t -c "SELECT item FROM orders WHERE id=1;"

# 2. Volume listeleme
docker volume ls | grep pgdata
```

* **Beklenen Başarı Çıktısı:**
  * SQL sorgusu `Server` çıktısını dönmelidir.
  * `docker volume ls` listesinde `pgdata` görünmelidir.

---

## 7. Temizlik

Laboratuvar tamamlandığında oluşturulan test veritabanını ve volume'u silin:

```bash
docker rm -f db db-new 2>/dev/null || true
docker volume rm pgdata 2>/dev/null || true
```
