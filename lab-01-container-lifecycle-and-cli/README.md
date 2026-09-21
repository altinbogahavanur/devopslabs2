# LAB-01: Konteyner Yaşam Döngüsü ve Temel CLI

## 🎯 Labın Amacı
Docker Engine mimarisini doğrulamak ve konteynerlerin yaşam döngüsünü (`create`, `run`, `stop`, `start`, `restart`, `pause`, `unpause`, `kill`, `rm`, `prune`) uygulamalı olarak yönetmek.

## 📋 Ön Koşullar & Portlar
- Docker Engine kurulu ve çalışır durumda olmalıdır.
- Host üzerinde **8080** portu boşta olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Docker Motoru ve Kurulumu Doğrulama
```bash
# Docker istemci ve sunucu sürümlerini kontrol edin
docker version

# Docker Daemon bilgilerini (Depolama sürücüsü, cgroup sürümü) inceleyin
docker info | grep -E "Server Version|Storage Driver|Cgroup"

# Non-root yetkinizi test edin (sudo yazmadan çalışmalıdır)
docker ps
```

### 2. İlk Web Konteynerını Başlatma (Detached Mod)
```bash
# Nginx web sunucusunu 8080 portundan arka planda başlatın
docker run -d --name web-life -p 8080:80 nginx:alpine

# Çalışan konteyneri listeleyin
docker ps
```

### 3. Durdurma, Başlatma ve Yeniden Başlatma
```bash
# Konteyneri zarifçe durdurun (SIGTERM sinyali gönderir)
docker stop web-life

# Durmuş olan konteynerleri listeleyin
docker ps -a | grep web-life

# Konteyneri tekrar başlatın
docker start web-life

# Konteyneri yeniden başlatın
docker restart web-life
```

### 4. Pause ve Unpause ile Süreci Dondurma
`pause`, Linux `cgroups` dondurucusunu (freezer) kullanarak konteynerin CPU tüketimini durdurur ancak bellekteki durumunu korur.

```bash
# Konteyneri dondurun (SIGSTOP):
docker pause web-life

# Test edin (İstek askıda kalacak, yanıt dönmeyecektir):
curl --max-time 2 http://localhost:8080 || echo "Konteyner donduruldu, yanit vermiyor!"

# Konteyneri uyandırın (SIGCONT):
docker unpause web-life

# Şimdi tekrar test edin (Anında 200 OK yanıtı döner):
curl -s http://localhost:8080 | grep "Welcome to nginx!"
```

### 5. Kill (Zorla Kapatma) vs Stop Farkı
```bash
# stop: 10 saniye bekleme süresi tanır (SIGTERM), işlem bitmezse SIGKILL atar.
# kill: Beklemeden doğrudan Linux kernel seviyesinde süreci sonlandırır (SIGKILL).
docker kill web-life
```

### 6. Konteyner Silme ve Disk Temizliği
```bash
# Tek bir konteyneri zorla silin:
docker rm -f web-life

# Durmuş tüm konteynerleri tek komutla temizleyin:
docker container prune -f

# Sistem disk kullanımını analiz edin:
docker system df
```

---

## ✅ Doğrulama (Verification)
- `docker ps -a` komutunu çalıştırdığınızda `web-life` konteynerinin sistemden tamamen temizlenmiş olduğunu teyit edin.

---

## 🧹 Temizlik
```bash
docker rm -f web-life 2>/dev/null || true
```
