# 🎮 Eğlence ve Faydalı Araçlar Merkezi (Docker Arcade & DevOps Toolbox)

> **Bu Modülün Amacı:** Docker ve konteyner teknolojisini sadece soyut sunucu komutlarıyla değil; **tarayıcıda çalışan oyunlar (Tetris, 2048), yerel mimari çizim araçları (Excalidraw, draw.io), web dosya yöneticisi (FileBrowser), ağ teşhis araçları (WhoAmI) ve hız testleriyle (Speedtest)** eğlenceli ve pratik şekilde öğrenmek!

Bu laboratuvar, hem **Docker Compose** ile toplu orkestrasyonu hem de **bağımsız `docker run`** komutlarıyla tekil konteyner yönetimini öğretir.

---

## 📑 Servis Kataloğu ve Kurumsal Port Listesi

Tüm servisler eğitim platformumuzun **`KURUMSAL_PORT_VE_GÜVENLİK_MATRİSİ`** standartlarına göre `19001 - 19008` port aralığına ve Nginx ters vekiline (`/appX`) bağlanmıştır:

| Servis Adı | Açıklama | Port | Doğrudan IP:Port | Nginx Kısayolu | Çalıştırma Yöntemi |
|---|---|:---:|---|---|:---:|
| 🧱 **Web Tetris** | Ok tuşlarıyla oynanan nostaljik web Tetris oyunu. | `19001` | `http://<IP>:19001` | `http://<IP>/app1` | Compose / `docker run` |
| 🧰 **IT-Tools** | 50+ araç (Base64, Cron, Regex, JWT, JSON/YAML çevirici). | `19002` | `http://<IP>:19002` | `http://<IP>/app2` | Compose / `docker run` |
| ✏️ **Excalidraw** | %100 yerel ve internetsiz çalışan serbest mimari tahtası. | `19003` | `http://<IP>:19003` | `http://<IP>/app3` | Compose / `docker run` |
| 🔢 **2048 Oyunu** | Sınıf içi turnuvalar için klasik 2048 zeka oyunu. | `19004` | `http://<IP>:19004` | `http://<IP>/app4` | Compose / `docker run` |
| 📂 **FileBrowser** | Sunucudaki dosyaları tarayıcıdan Google Drive gibi yönetme. | `19005` | `http://<IP>:19005` | `http://<IP>/app5` | Compose / `docker run` |
| 🕵️ **Traefik WhoAmI**| HTTP request header'larını ve konteyner IP'sini basan test aracı. | `19006` | `http://<IP>:19006` | — | Compose / `docker run` |
| 🚀 **Speedtest** | Web üzerinden tek tıkla ağ hızını ve ping'i ölçme aracı. | `19007` | `http://<IP>:19007` | — | Compose / `docker run` |
| 📐 **draw.io** | AWS, K8s ve Docker ikonlarıyla kurumsal mimari çizici. | `19008` | `http://<IP>:19008` | — | Compose / `docker run` |

---

## 🚀 YÖNTEM 1: Docker Compose ile Hepsini Tek Hamlede Başlatma

Tüm servisleri tek bir hamleyle başlatmak için:

```bash
cd devops-arcade-and-tools
docker compose up -d
docker compose ps
```

### Durdurmak ve Temizlemek İçin:
```bash
docker compose down
```

---

## 🛠️ YÖNTEM 2: Doğrudan `docker run` (CLI) ile Tekil Çalıştırma

Öğrencilere her bir parametrenin (`-d`, `-p`, `-v`, `--name`, `--restart`) ne işe yaradığını tekil komutlarla kavratın:

### 1. 📂 Web Tabanlı Dosya Yöneticisi (FileBrowser)
Öğrencinin kendi sanal makinesindeki dosyalara tarayıcıdan masaüstü gibi erişmesini sağlar:
```bash
docker run -d --name lab-filebrowser \
  -p 19005:80 \
  -v /home/student:/srv \
  --restart unless-stopped \
  filebrowser/filebrowser:latest
```
* **Erişim:** `http://<IP>:19005` (Varsayılan kullanıcı: `admin` / `admin`).

---

### 2. 🕵️ Ağ ve HTTP Başlık Analizcisi (Traefik WhoAmI)
Bir istek attığınızda arkada dönen tüm HTTP başlıklarını (Host, User-Agent, X-Forwarded-For) ekrana basan mükemmel teşhis aracı:
```bash
docker run -d --name lab-whoami \
  -p 19006:80 \
  --restart unless-stopped \
  traefik/whoami:latest
```
* **Test:** `curl http://localhost:19006`
* **Örnek Çıktı:**
  ```text
  Hostname: 7a6f8b9c1d2e
  IP: 127.0.0.1
  IP: 172.17.0.4
  RemoteAddr: 127.0.0.1:48292
  GET / HTTP/1.1
  Host: localhost:19006
  User-Agent: curl/7.88.1
  ```

---

### 3. 🚀 Yerel Ağ Hız Testi (LibreSpeed Speedtest)
Sunucunun indirme/yükleme hızını ve gecikmesini görsel ölçmek için:
```bash
docker run -d --name lab-speedtest \
  -p 19007:80 \
  --restart unless-stopped \
  adolfintel/speedtest:latest
```
* **Erişim:** `http://<IP>:19007` ➔ "Start" butonuna basın ve hızı canlı izleyin!

---

### 4. 📐 Çevrimdışı Profesyonel Mimari Çizim Aracı (draw.io)
AWS, Kubernetes, Azure ve GCP hazır şablonlarıyla diyagram çizme:
```bash
docker run -d --name lab-drawio \
  -p 19008:8080 \
  --restart unless-stopped \
  jgraph/drawio:latest
```
* **Erişim:** `http://<IP>:19008`

---

### 5. 🌤️ Tek Seferlik Geçici Konteyner (`--rm` Deneyi)
Arka planda kalıcı çalışmayan, işini yapıp anında yok olan konteyner örneği:
```bash
docker run --rm curlimages/curl -s "wttr.in/Istanbul?format=3"
```
* Ekranda anlık hava durumunu basar ve `docker ps -a` listesinde arkasında çöp bırakmadan tamamen silinir!

---

## ⚡ Canlı Sınıf Deneyi: "Konteyneri Boğalım (cgroups Limiti)"

Öğrencilere Linux cgroups mekanizmasının gücünü göstermek için:

```bash
# Tetris oyununu aşırı düşük kaynakla (16 MB RAM, %10 CPU) başlatın:
docker run -d --name bogulmus-tetris \
  -p 19001:80 \
  --memory="16m" \
  --cpus="0.1" \
  bsord/tetris:latest

# Canlı olarak sınırları izleyin:
docker stats bogulmus-tetris
```
* Ekranda `16MiB` limitini ve cgroups tavan sınırını öğrencinin bizzat görmesini sağlayın!
