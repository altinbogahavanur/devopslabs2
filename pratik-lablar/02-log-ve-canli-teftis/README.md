# Pratik Lab 02: Docker Log İnceleme, Proses Dedektifliği (`top`) ve `inspect`

Bu pratik laboratuvarda, Docker log yönetiminin inceliklerini (`-f`, `--tail`, `-t`), konteyner içindeki prosesleri ana makineden izlemeyi (`docker top`), kaynak kullanımını (`docker stats`) ve JSON metaverisinden cerrahi bilgi çekmeyi (`docker inspect --format`) uygulayacaksınız.

---

## 1. Test Konteynerini Başlatma

```bash
docker run -d --name log-app -p 19012:80 nginx:alpine
```

---

## 2. Log Dedektifliği (`docker logs`)

1. **Zaman Damgası (Timestamp) ile Okuma:**
   ```bash
   docker logs -t log-app
   ```
2. **Sadece Son N Satırı Listeleme:**
   ```bash
   docker logs --tail 10 log-app
   ```
3. **Canlı Log Akışı (Follow `-f`):**
   ```bash
   # Terminalde logu canlı takibe alın:
   docker logs -f --tail 5 log-app &
   LOG_PID=$!

   # İstek atarak logun düştüğünü görün:
   curl -s http://localhost:19012 > /dev/null
   curl -s http://localhost:19012/olmayan-sayfa > /dev/null

   kill $LOG_PID
   ```

---

## 3. Proses Dedektifliği (`docker top`)

Konteynerin içine girmeden içinde hangi proseslerin çalıştığını ve bunların ana makinedeki gerçek PID karşılıklarını görün:
```bash
docker top log-app
```
* **Ders:** `nginx: master process` ve `nginx: worker process` satırlarını inceleyin.

---

## 4. Canlı Kaynak Tüketimi (`docker stats`)

Konteynerin CPU ve RAM tüketimini anlık olarak raporlayın:
```bash
docker stats --no-stream log-app
```
* Ekranda `CPU %`, `MEM USAGE / LIMIT`, `NET I/O` ve `PIDS` sütunlarını inceleyin.

---

## 5. Cerrahi Bilgi Filtreleme (`docker inspect --format`)

Yüzlerce satırlık ham JSON yerine Go şablon formatı (`--format`) ile sadece aradığınız bilgiyi çekin:

```bash
# 1. Konteynerin dahili IP adresi:
docker inspect --format '{{ .NetworkSettings.IPAddress }}' log-app

# 2. Çalışma durumu ve başlama zamanı:
docker inspect --format 'Durum: {{ .State.Status }}, Baslama: {{ .State.StartedAt }}' log-app

# 3. Yeniden başlama sayısı (Restart Count):
docker inspect --format 'Restart Sayisi: {{ .RestartCount }}' log-app
```

---

## 6. Temizlik

```bash
docker rm -f log-app
```
