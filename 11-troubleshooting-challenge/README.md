# LAB-DOC-11 — Docker Sorun Giderme Meydan Okuması (Troubleshooting Challenge)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker-ce`, `ss`, `curl`, `inspect` | Değişken (80, 8080) |

---

## Amaç

Gerçek hayatta üretim ve geliştirme ortamlarında en sık karşılaşılan **5 kritik Docker arızasını** adım adım teşhis etmek (`Diagnose`) ve onarmak (`Remediate`):

1. **Port Çakışması Hatası** (`bind: address already in use`)
2. **Anında Kapanan Konteyner** (`Exit Code 0` / Daemon eksikliği)
3. **Bellek Aşımı ve Çökme** (`Exit Code 137` / OOMKilled)
4. **Volume Erişim Reddi** (`Permission Denied` / UID Mismatch)
5. **Konteynerlar Arası İletişim Kopukluğu** (Varsayılan bridge üzerinde DNS çalışmaması)

---

## 🔍 Temel Teşhis Metodolojisi

Docker ortamında bir arıza yaşandığında izlenecek altın teşhis sırası:

1. `docker ps -a` (Konteyner çalışıyor mu, yeniden mi başlıyor, ne zaman durdu?)
2. `docker logs <konteyner-adı>` (Uygulamanın bastığı son hata veya çökme mesajı)
3. `docker inspect <konteyner-adı>` (Çıkış kodu `ExitCode`, `OOMKilled` durumu, IP ve mount bilgisi)
4. `sudo ss -tulpn | grep :PORT` (Port ana makinede başka bir servis tarafından tutuluyor mu?)

---

## Senaryolar ve Çözüm Adımları

### Senaryo 1: Port Çakışması Hatası (`bind: address already in use`)

```bash
# 1. Simülasyon: Port 8080'i arka planda bir servis ile kilitleyelim:
python3 -m http.server 8080 >/dev/null 2>&1 &
BLOCKED_PID=$!

# 2. Şimdi 8080 portunu isteyen bir Nginx konteyneri başlatmayı deneyelim:
docker run -d --name broken-port-web -p 8080:80 nginx:alpine
```

- **Hata Çıktısı:**
  `Error response from daemon: driver failed programming external connectivity ... bind: address already in use`
- **Teşhis:**
  ```bash
  sudo ss -tulpn | grep ':8080'
  ```
- **Onarım:**
  Portu tutan süreci sonlandırın ve konteyneri tekrar başlatın:
  ```bash
  kill -9 $BLOCKED_PID
  docker run -d --name fixed-port-web -p 8080:80 nginx:alpine
  curl http://localhost:8080
  docker rm -f fixed-port-web
  ```

---

### Senaryo 2: Anında Kapanan Konteyner (`Exit Code 0`)

```bash
# Simülasyon: Nginx'i arka plan daemon'u olarak başlatan hatalı bir komut verelim:
docker run -d --name exit-web nginx:alpine nginx
docker ps -a | grep exit-web
```

- **Teşhis:**
  Konteyner hemen `Exited (0)` durumuna geçmiştir. Çünkü Docker bir konteyneri sadece **PID 1 (ön plandaki süreç)** yaşadığı sürece ayakta tutar. `nginx` komutu arka plana geçtiğinde ön planda süreç kalmaz ve konteyner kapanır.
- **Onarım:**
  Süreç ön planda çalışacak şekilde (`daemon off;`) başlatılmalıdır:
  ```bash
  docker rm exit-web
  docker run -d --name fixed-exit-web -p 8080:80 nginx:alpine nginx -g "daemon off;"
  docker ps | grep fixed-exit-web
  docker rm -f fixed-exit-web
  ```

---

### Senaryo 3: Bellek Sızıntısı ve OOMKilled (`Exit Code 137`)

```bash
# Simülasyon: 64 MB RAM sınırı olan bir konteynere 100 MB bellek harcattıralım:
docker run -d --name memory-crasher --memory 64m python:3.12-alpine \
  python3 -c "import time; a = 'x' * (100 * 1024 * 1024); time.sleep(60)"
sleep 3
docker ps -a | grep memory-crasher
```

- **Teşhis:**
  Konteyner `Exited (137)` olmuştur. Çıkış kodunu ve OOM bayrağını denetleyin:
  ```bash
  docker inspect -f 'ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}' memory-crasher
  ```
  *(ExitCode 137 = 128 + 9 [SIGKILL], OOMKilled = true)*
- **Onarım:**
  Uygulamanın bellek tüketimi optimize edilmeli veya konteyner bellek sınırı artırılmalıdır (`--memory 256m`).
  ```bash
  docker rm -f memory-crasher
  ```

---

### Senaryo 4: Volume Erişim Reddi (`Permission Denied`)

```bash
# 1. Simülasyon: Host üzerinde root kullanıcısına ait kilitli bir dizin açalım:
mkdir -p /tmp/perm-test && sudo chmod 700 /tmp/perm-test

# 2. Non-root (UID 1000) bir konteyner ile buraya yazmayı deneyelim:
docker run --rm -u 1000:1000 -v /tmp/perm-test:/data alpine \
  touch /data/app.log 2>&1
```

- **Hata Çıktısı:**
  `touch: /data/app.log: Permission denied`
- **Teşhis:**
  Host dizininin sahibi `root (0)` iken, konteyner `UID 1000` ile çalışmaktadır.
- **Onarım:**
  Host dizini sahipliğini ilgili kullanıcıya verin:
  ```bash
  sudo chown -R 1000:1000 /tmp/perm-test
  docker run --rm -u 1000:1000 -v /tmp/perm-test:/data alpine touch /data/app.log
  ls -l /tmp/perm-test/app.log
  rm -rf /tmp/perm-test
  ```

---

### Senaryo 5: Konteynerlar Arası İletişim Kopukluğu (Default Bridge Hatası)

```bash
# 1. Simülasyon: İki konteyneri varsayılan köprü (default bridge) üzerinde başlatalım:
docker run -d --name srv-db postgres:17-alpine -e POSTGRES_PASSWORD=test
docker run -d --name srv-app alpine sleep 3600

# 2. srv-app içinden srv-db'ye isimle ping atmayı deneyelim:
docker exec srv-app ping -c 1 srv-db 2>&1 || true
```

- **Hata Çıktısı:**
  `ping: bad address 'srv-db'`
- **Teşhis:**
  Docker varsayılan `bridge` ağı üzerinde **Dahili DNS (Embedded DNS) sunucusu sunmaz!** Konteynerlar birbirini sadece IP ile bulabilir.
- **Onarım:**
  Özel bir bridge ağı oluşturup konteynerları bu ağa taşıyın:
  ```bash
  docker network create custom-net
  docker network connect custom-net srv-db
  docker network connect custom-net srv-app
  docker exec srv-app ping -c 2 srv-db
  ```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker exec srv-app ping -c 2 srv-db
# Özel ağa bağlandıktan sonra ping paketleri başarıyla iletilmelidir.
```

---

## Temizlik

```bash
docker rm -f srv-db srv-app 2>/dev/null || true
docker network rm custom-net 2>/dev/null || true
```
