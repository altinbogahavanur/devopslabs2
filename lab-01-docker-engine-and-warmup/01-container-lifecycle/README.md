# LAB-DOC-02-01 — Konteyner Yaşam Döngüsü ve Temel Komutlar

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç | `docker-ce`, `nginx:alpine`, `curl` | 8080 |

> **Önemli Erişim Notu:** Konteyner web arayüzünü test etmek için `http://<SUNUCU-IP>:8080` adresini kullanabilir veya terminalden `curl http://localhost:8080` komutuyla yanıt alabilirsiniz.

---

## Amaç

- Konteyner yaşam döngüsünü (`create`, `start`, `run`, `stop`, `restart`, `kill`, `rm`) uygulamalı olarak kavramak.
- Arka planda (detached `-d`) çalıştırma ve port eşleme (`-p`) mantığını pekiştirmek.
- Konteyner loglarını canlı izlemek (`logs -f`) ve içine interaktif komut kabuğu açmak (`exec -it`).

---

## Ön Koşullar

- Docker Engine çalışır durumda olmalıdır (`docker info`).
- Host üzerinde `8080` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
[docker run -d -p 8080:80] ──> [Image: nginx:alpine] ──> [Container: Running]
                                                               │
                                       ┌───────────────────────┼───────────────────────┐
                                       ▼                       ▼                       ▼
                                [docker logs]           [docker exec]           [docker stop/rm]
```

---

## Adım Adım Uygulama Rehberi

### 1. İlk Web Konteynerını Başlatma
```bash
# Nginx konteynerını arka planda (detached) ve port 8080'i hosta eşleyerek başlatın:
docker run -d --name my-web -p 8080:80 nginx:alpine

# Çalışan konteynerları listeleyin:
docker ps
```

### 2. Canlı Log İzleme
```bash
# Konteyner loglarını takip edin (Ayrı bir terminalden veya curl isteğiyle log üretin):
docker logs -f my-web &
LOG_PID=$!

# İstek gönderip logu görün:
curl http://localhost:8080

# Arka plandaki log izlemeyi durdurun:
kill $LOG_PID
```

### 3. Konteyner İçine Canlı Bağlanma (Exec)
```bash
# Konteyner içerisinde interaktif bir sh kabuğu açın ve işletim sistemini kontrol edin:
docker exec -it my-web cat /etc/os-release

# Konteyner içindeki Nginx süreçlerini kontrol edin:
docker exec my-web ps aux
```

### 4. Yaşam Döngüsü Kontrolleri
```bash
# Konteyneri durdurma:
docker stop my-web
docker ps -a | grep my-web

# Konteyneri tekrar başlatma:
docker start my-web

# Konteyneri durdurup silme:
docker stop my-web
docker rm my-web
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker ps -a | grep my-web
# Çıktı boş dönmelidir (Konteyner başarıyla durdurulup silinmiştir).
```

---

## Temizlik

```bash
docker rm -f my-web 2>/dev/null || true
```
