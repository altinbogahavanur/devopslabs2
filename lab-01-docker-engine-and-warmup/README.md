# LAB-DOC-01 — Docker Engine Mimarisi ve Kademeli Isınma Komutları

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç | `docker-ce`, `nginx:alpine`, `curl` | 8080 |

## Amaç
- Docker Engine mimarisini (dockerd daemon, containerd, runc, shim) ve non-root çalışma izinlerini doğrulamak.
- Konteyner dünyasına yeni adım atan bir mühendis için temel Docker CLI komutlarını 8 aşamalı kademeli bir akışla deneyimlemek.
- Arka planda (detached `-d`) servis çalıştırma, port yönlendirme (`-p`), süreç listeleme (`ps`), canlı log izleme (`logs -f`) ve interaktif kabuk açma (`exec -it`) pratiklerini pekiştirmek.
- Konteyner dosya sistemine host'tan dosya aktarmak (`docker cp`), değişiklikleri incelemek (`docker diff`) ve kaynak kullanımını (`inspect`, `stats`) analiz etmek.
- Yaşam döngüsü bitişini (`stop`, `rm`) ve disk temizliğini (`docker system prune`) uygulamak.

## Ön Koşullar
- Ubuntu sanal makinesinde Docker Engine kurulu olmalıdır (`docker info`).
- Host üzerinde `8080` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
[DOCKER CLI]
     │
     ▼ (UNIX Socket: /var/run/docker.sock)
[DOCKER DAEMON (dockerd)]
     │
     ▼ (gRPC)
[containerd] ──> [containerd-shim] ──> [runc] ──> [Linux Kernel Namespaces & Cgroups]
                                                              │
                                            ┌─────────────────┴─────────────────┐
                                            ▼                                   ▼
                                [PID/Mount/Net İzolasyonu]             [CPU/RAM Limitleri]
```

---

## Adım Adım Uygulama Rehberi

### Bölüm 1: Docker Motoru ve Kurulum Doğrulaması

1. Docker motor sürümünü ve bileşenlerini kontrol edin:
   ```bash
   docker version
   docker compose version
   ```
2. Docker sistem bilgilerini (Depolama sürücüsü, cgroup sürümü, çalışan konteyner sayısı) inceleyin:
   ```bash
   docker info | grep -E "Server Version|Storage Driver|Cgroup|Security Options"
   ```
3. Non-root kullanıcı yetkinizi doğrulayın (`sudo` yazmadan `docker ps` çalışabilmelidir):
   ```bash
   docker ps
   ```

---

### Bölüm 2: Kademeli Isınma Komutları (8 Aşamalı Pratik)

#### Adım 1: İlk Temas ve İmaj Çekme (hello-world)
Docker'ın kayıt defterinden (Docker Hub) imaj indirip konteyner çalıştırma mekanizmasını görün:
```bash
docker run hello-world
```
*İnceleme: Docker yerelde `hello-world` bulamazsa otomatik çeker (`pull`), bir konteyner başlatır, karşılama mesajını ekrana basar ve PID 1 süreci bittiği için konteyneri durdurur.*

#### Adım 2: Arka Planda Web Servisi Başlatma (Detached & Port Mapping)
Bir web sunucusunu arka planda çalıştırmak ve dış dünyadan erişilebilir kılmak:
```bash
docker run -d --name web-warmup -p 8080:80 nginx:alpine
```
*Açıklama: `-d` (detached) terminali serbest bırakır. `-p 8080:80` ana makinenin 8080 portunu konteynerin 80 portuna yönlendirir.*

#### Adım 3: Süreçleri ve Konteynerleri İnceleme
```bash
# Sadece aktif (çalışan) konteynerları listeleyin:
docker ps

# Durmuş olanlar dahil tüm geçmişi görün:
docker ps -a

# Konteyner içindeki gerçek Linux süreç tablosunu host üzerinden inceleyin:
docker top web-warmup
```

#### Adım 4: Canlı Log İzleme
```bash
# Konteyner loglarını canlı akış modunda arka planda başlatın:
docker logs -f web-warmup &
LOG_PID=$!

# Ana makineden web servisine istek gönderip canlı logun düştüğünü izleyin:
curl -s http://localhost:8080 > /dev/null

# Log takibini durdurun:
kill $LOG_PID
```

#### Adım 5: Konteyner İçine Canlı Bağlanma (Exec)
Konteynerin izole dosya sistemine interaktif kabuk açarak girin:
```bash
# Konteynerin işletim sistemi sürümünü okuyun:
docker exec -it web-warmup cat /etc/os-release

# Konteyner içine interaktif sh oturumu açın:
docker exec -it web-warmup sh
# (Konteyner içindeyken hostname ve dizini kontrol edin):
hostname
ls -la /usr/share/nginx/html
exit
```

#### Adım 6: Dosya Kopyalama ve Değişiklik İnceleme (docker cp & diff)
```bash
# 1. Host üzerinde özel bir selamlama sayfası oluşturun:
echo "<h1>Docker Isinma Laboratuvari Tamamlandi!</h1>" > /tmp/index.html

# 2. Dosyayı çalışan konteynerin içine kopyalayın:
docker cp /tmp/index.html web-warmup:/usr/share/nginx/html/index.html

# 3. Dosya sistemindeki değişiklikleri inceleyin (C: Changed, A: Added):
docker diff web-warmup

# 4. Web servisini test ederek güncellemeyi doğrulayın:
curl http://localhost:8080
```

#### Adım 7: İnceleme ve Canlı Kaynak Tüketimi (inspect & stats)
```bash
# Konteynerin IP adresini ve metadata detaylarını sorgulayın:
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web-warmup

# Konteynerin anlık CPU ve RAM tüketimini görüntüleyin:
docker stats --no-stream web-warmup
```

#### Adım 8: Yaşam Döngüsü Bitişi ve Disk Temizliği
```bash
# Konteyneri durdurun:
docker stop web-warmup

# Konteyneri yeniden başlatın:
docker start web-warmup

# Konteyneri zorla durdurup silin:
docker rm -f web-warmup

# Sistem disk kullanımını inceleyin ve sahipsiz katmanları temizleyin:
docker system df
docker system prune -f
```

---

## Doğal Doğrulama ve Beklenen Sonuç
- `curl http://localhost:8080` çağrısında özel oluşturduğunuz `Docker Isinma Laboratuvari Tamamlandi!` mesajının dönmesi.
- `docker ps` çıktısında temizlik sonrası hiçbir atıl test konteynerinin kalmadığının doğrulanması.

## Temizlik
```bash
docker rm -f web-warmup 2>/dev/null || true
rm -f /tmp/index.html
```
