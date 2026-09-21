# 🐙 Docker Compose Komutları (Compose Cheatsheet)

Çok konteynerli uygulamaları (multi-container stacks) tek komutla yönetme ve denetleme komutları.

---

## 1. Yığını Başlatma ve Durdurma

### Tüm Servisleri Arka Planda Başlatma (`up`)
```bash
docker compose up -d
```

### Kod Değiştiğinde İmajları Yeniden Derleyerek Başlatma
```bash
docker compose up -d --build
```

### Eski / Yetim (Orphan) Konteynerleri Temizleyerek Başlatma
```bash
docker compose up -d --remove-orphans
```

### Tüm Servisleri ve Ağları Durdurup Kaldırma (`down`)
```bash
docker compose down
```

### Servislerle Birlikte Named Volume'leri de Temizleme (Tam Sıfırlama)
```bash
docker compose down -v --remove-orphans
```
* **DİKKAT:** `-v` parametresi veritabanı volume'lerini de siler!

---

## 2. Durum Takibi ve Canlı Günlükler (Logs)

### Yığındaki Konteynerlerin Durumunu ve Portlarını Görme
```bash
docker compose ps
```

### Canlı Logları Ekrana Yazdırma (Tüm Servisler)
```bash
docker compose logs -f
```

### Yalnızca Belirli Bir Servisin Son Loglarını Görme
```bash
docker compose logs -f --tail 100 backend
```

---

## 3. Canlı Müdahale ve Yönetim

### Çalışan Bir Servisin İçine Kabuk Açma (`exec`)
```bash
docker compose exec backend sh
# Veya veritabanına bağlanma:
docker compose exec postgres psql -U novashop -d novashop_db
```

### Yalnızca Tek Bir Servisi Yeniden Başlatma
```bash
docker compose restart backend
```

### Tek Bir Servisi Durdurma veya Başlatma
```bash
docker compose stop backend
docker compose start backend
```

### Konfigürasyon Dosyasını Doğrulama ve Birleştirme (`config`)
```bash
docker compose config
```
* **Açıklama:** YAML sözdizimini doğrular, ortam değişkenlerini (`.env`) yerine koyar ve nihai konfigürasyonu basar.

### Belirli Bir Servisin Kopyasını Çoğaltma (Yatay Ölçekleme)
```bash
docker compose up -d --scale worker=3
```

### Farklı Bir Compose Dosyası ile Çalışma (`-f`)
```bash
docker compose -f docker-compose.prod.yml up -d
```
