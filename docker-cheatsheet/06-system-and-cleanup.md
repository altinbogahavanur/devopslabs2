# 🧹 Docker Sistem, Bakım ve Temizlik Komutları (System & Cleanup Cheatsheet)

Disk alanı analizi, BuildKit önbelleği temizleme ve kullanılmayan kaynakları kaldırma komutları.

---

## 1. Disk Kullanım Analizi (`docker system df`)

Docker'ın diskte ne kadar yer kapladığını kategorik olarak gösterir.

### Genel Disk Kullanım Özeti
```bash
docker system df
```
* **Örnek Çıktı:**
  * `Images`: Toplam imaj boyutu ve geri kazanılabilir alan (Reclaimable).
  * `Containers`: Konteynerlerin writable katman boyutu.
  * `Local Volumes`: Kalıcı disk alanlarının boyutu.
  * `Build Cache`: Derleme katman önbelleği boyutu.

### Ayrıntılı Disk Kullanım Dökümü
```bash
docker system df -v
```

---

## 2. Kademeli Temizlik Komutları (`prune`)

### Güvenli Rutin Temizlik (Kalıcı Verilere Dokunmaz)
```bash
docker system prune -f
```
* **Neleri Siler:**
  * Tüm durmuş (Exited) konteynerler.
  * İsmi olmayan (`<none>`) boşta kalan (dangling) imajlar.
  * Hiçbir konteyner tarafından kullanılmayan ağlar.
  * *Not: Named Volume'lere ve etiketli imajlara DOKUNMAZ.*

### Agresif İmaj Temizliği (Kullanılmayan Tüm İmajlar Dahil)
```bash
docker system prune -a -f
```
* **Neleri Siler:**
  * Yukarıdakilere ek olarak, şu an çalışan bir konteyner tarafından kullanılmayan **tüm etiketli imajları da** siler.

### Derleme Önbelleğini (BuildKit Cache) Temizleme
```bash
docker builder prune -f
# Veya tüm derleme geçmişini temizleme:
docker builder prune -a -f
```

### Yalnızca Boşta Kalan Volume'leri Temizleme
```bash
docker volume prune -f
```

---

## 3. Sistem Bilgisi ve Canlı Olay Akışı (Event Stream)

### Docker Motoru Bilgilerini İnceleme (`info`)
```bash
docker info
```
* **Önemli Bilgiler:** Cgroup sürümü (`cgroup v2`), Storage Driver (`overlay2`), Docker Root Dir (`/var/lib/docker`), Toplam bellek ve CPU kısıtları.

### Canlı Konteyner Olaylarını Dinleme (`events`)
```bash
docker events
```
* **Açıklama:** Terminali açık bırakarak konteynerlerin başlatılma, durdurulma, OOMKilled ve silinme olaylarını anlık olarak izler.
