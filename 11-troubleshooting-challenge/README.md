# LAB-DOC-11 — Docker Arıza Teşhis ve Onarım Simülatörü (Troubleshooting Challenge)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta / İleri | `docker-ce`, `ss`, `curl`, `inspect`, Bash Simülatörü | Değişken (80, 8080) |

Bu laboratuvarda; Docker üretim ve geliştirme ortamlarında en sık karşılaşılan **5 kritik arıza senaryosunu** interaktif bir simülatör eşliğinde deneyimleyecek, teşhis koyacak (`Diagnose`), onaracak (`Remediate`) ve çözümünüzü otomatik testlerle (`Verify`) doğrulayacaksınız.

---

## 🎯 Öğrenme Hedefleri

1. **Port Yönetimi:** `bind: address already in use` arızasını tespit edip portu serbest bırakmak veya konteyneri yönlendirmek.
2. **PID 1 ve Yaşam Döngüsü:** Ön plan (foreground) süreci eksikliği nedeniyle `Exit Code 0` ile anında kapanan konteynerleri onarmak.
3. **Bellek Kısıtları:** `OOMKilled` ve `Exit Code 137` çökme durumlarını `inspect` ile yakalayıp kaynak sınırlarını optimize etmek.
4. **Konteyner İçi Ağ ve DNS:** Varsayılan bridge ağında dahili DNS bulunmadığını kavrayıp özel bridge ağı kurmak.
5. **Kalıcı Depolama İzinleri:** Non-root konteynerlerin host dizinlerine yazarken yaşadığı `Permission Denied` hatasını UID/GID seviyesinde çözmek.

---

## 🚀 İnteraktif Simülatör ile Çalışma (Önerilen Yöntem)

Laboratuvar dizinindeki simülatörü çalıştırarak arızaları canlı olarak üretebilir ve test edebilirsiniz:

```bash
# 1. Laboratuvar dizinine gidin
cd 11-troubleshooting-challenge

# 2. İnteraktif menüyü başlatın
./troubleshoot-menu.sh
```

### 🎮 Menü Kullanım Döngüsü

Menüden bir senaryo seçtiğinizde ilgili arıza odasına girersiniz:
- **`[B] Break`:** Sistemi bozar, arızayı simüle eder ve konteyneri başlatır.
- **`[V] Verify`:** Çözümünüzü otomatik test eder (HTTP 200 yanıtı, PID 1 çalışma durumu, Ping iletimi, log yazımı).
- **`[H] Hint`:** Takıldığınızda kök neden analizine yardımcı olacak ipuçlarını ve kontrol komutlarını listeler.
- **`[S] Solution`:** Resmi çözüm adımlarını gösterir ve istenirse otomatik uygular.
- **`[C] Cleanup`:** İlgili senaryonun konteynerlerini temizler.
- **`[R] Return`:** Ana menüye döner.

---

## 🔍 Manuel Çalışma ve Senaryo Detayları

Simülatör yerine komutları doğrudan terminalinizde adım adım denemek isterseniz:

### Senaryo 1: Port Çakışması Hatası (`bind: address already in use`)

```bash
# 1. Simülasyon: Port 8080'i kitleyen bir konteyner başlatalım:
docker run -d --name port-occupier -p 8080:80 nginx:alpine

# 2. Şimdi 8080 portunu isteyen asıl web konteynerini başlatmayı deneyelim:
docker run -d --name fixed-port-web -p 8080:80 nginx:alpine
```

- **Hata Çıktısı:**
  `Error response from daemon: driver failed programming external connectivity ... bind: address already in use`
- **Teşhis:**
  ```bash
  docker ps --filter publish=8080
  sudo ss -tulpn | grep ':8080'
  ```
- **Onarım:**
  Portu tutan süreci sonlandırın ve konteyneri başlatın:
  ```bash
  docker rm -f port-occupier
  docker run -d --name fixed-port-web -p 8080:80 nginx:alpine
  curl http://localhost:8080
  ```

---

### Senaryo 2: Anında Kapanan Konteyner (`Exit Code 0`)

```bash
# Simülasyon: Nginx'i arka plan daemon'u olarak başlatan hatalı bir komut verelim:
docker run -d --name exit-web nginx:alpine nginx
docker ps -a | grep exit-web
```

- **Teşhis:**
  Konteyner hemen `Exited (0)` durumuna geçmiştir. Docker, bir konteyneri sadece **PID 1 (ön plandaki süreç)** yaşadığı sürece ayakta tutar. `nginx` komutu arka plana geçtiğinde ön planda süreç kalmaz ve konteyner kapanır.
- **Onarım:**
  Süreç ön planda çalışacak şekilde (`daemon off;`) başlatılmalıdır:
  ```bash
  docker rm -f exit-web
  docker run -d --name exit-web nginx:alpine nginx -g "daemon off;"
  docker ps | grep exit-web
  ```

---

### Senaryo 3: Bellek Aşımı ve OOMKilled (`Exit Code 137`)

```bash
# Simülasyon: 32 MB RAM sınırı olan bir konteynere 80 MB bellek harcattıralım:
docker run -d --name memory-crasher --memory 32m python:3.12-alpine \
  python3 -c "import time; a = 'x' * (80 * 1024 * 1024); time.sleep(60)"
sleep 2
docker ps -a | grep memory-crasher
```

- **Teşhis:**
  Konteyner `Exited (137)` olmuştur:
  ```bash
  docker inspect -f 'ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}' memory-crasher
  ```
  *(ExitCode 137 = 128 + 9 [SIGKILL], OOMKilled = true)*
- **Onarım:**
  Konteyner bellek sınırı makul seviyeye yükseltilmelidir:
  ```bash
  docker rm -f memory-crasher
  docker run -d --name memory-crasher --memory 256m python:3.12-alpine \
    python3 -c "import time; a = 'x' * (80 * 1024 * 1024); time.sleep(60)"
  ```

---

### Senaryo 4: Konteynerlar Arası İletişim Kopukluğu (Default Bridge)

```bash
# 1. Simülasyon: İki konteyneri varsayılan köprü (default bridge) üzerinde başlatalım:
docker run -d --name srv-db alpine sleep 3600
docker run -d --name srv-app alpine sleep 3600

# 2. srv-app içinden srv-db'ye isimle ping atmayı deneyelim:
docker exec srv-app ping -c 1 srv-db 2>&1 || true
```

- **Hata Çıktısı:**
  `ping: bad address 'srv-db'`
- **Teşhis:**
  Docker varsayılan `bridge` ağı üzerinde **Dahili DNS (Embedded DNS 127.0.0.11) sunucusu sunmaz!**
- **Onarım:**
  Özel bir bridge ağı oluşturup konteynerları bu ağa bağlayın:
  ```bash
  docker network create custom-net
  docker network connect custom-net srv-db
  docker network connect custom-net srv-app
  docker exec srv-app ping -c 2 srv-db
  ```

---

### Senaryo 5: Volume Erişim Reddi (`Permission Denied`)

```bash
# 1. Simülasyon: Host üzerinde root kullanıcısına ait kilitli bir dizin açalım:
rm -rf /tmp/perm-test && mkdir -p /tmp/perm-test && chmod 700 /tmp/perm-test

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
  ```

---

## 🧹 Genel Temizlik (Cleanup)

```bash
docker rm -f port-occupier fixed-port-web broken-port-web exit-web memory-crasher srv-db srv-app perm-app 2>/dev/null || true
docker network rm custom-net 2>/dev/null || true
rm -rf /tmp/perm-test 2>/dev/null || true
```
