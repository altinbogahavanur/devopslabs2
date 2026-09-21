# 🌐 Docker Ağ Yönetimi Komutları (Networking Cheatsheet)

Ağ türleri, özel bridge ağları, yerleşik DNS çözümlemesi ve ağ izolasyonu komutları.

---

## 🏛️ Docker Ağ Sürücüleri (Network Drivers)

| Sürücü | Davranış | Dahili DNS | Kullanım Alanı |
| :--- | :--- | :---: | :--- |
| **bridge** (Özel) | Sanal switch, izole IP bloğu (`172.x.x.x`) | ✅ Var (`127.0.0.11`) | Standart üretim ve mikroservis haberleşmesi |
| **default bridge** | `docker0` varsayılan ağı | ❌ Yok | Tavsiye edilmez (yalnızca IP ile erişilir) |
| **host** | Host'un ağ yığınını doğrudan kullanır | — | Yüksek throughput gerektiren proxy'ler, Benchmark |
| **none** | Ağ kartını tamamen kapatır (Loopback hariç) | ❌ Yok | İzole batch hesaplamaları, güvenlik testleri |
| **overlay** | Çoklu host (Swarm / K8s benzeri küme) | ✅ Var | Dağıtık küme ortamları |

---

## 1. Ağ Oluşturma ve Yönetimi

### Yeni Bir Özel Bridge Ağı Oluşturma
```bash
docker network create my-net
```

### Özel Subnet ve Gateway ile Ağ Oluşturma
```bash
docker network create --driver bridge --subnet 10.20.0.0/16 --gateway 10.20.0.1 custom-net
```

### Mevcut Ağları Listeleme
```bash
docker network ls
```

### Ağ Ayrıntılarını ve Bağlı Konteynerleri Görme (`inspect`)
```bash
docker network inspect my-net
```
* **Açıklama:** Ağa bağlı tüm konteynerlerin IP ve MAC adreslerini listeler.

### Belirli Bir Ağı Silme (İçinde Konteyner Olmamalıdır)
```bash
docker network rm my-net
```

### Kullanılmayan Tüm Ağları Temizleme
```bash
docker network prune -f
```

---

## 2. Konteynerleri Ağa Bağlama ve Dahili DNS

Özel bridge ağlarında konteynerler birbirine IP yerine **konteyner isimleriyle** erişebilir.

### Konteyneri Özel Ağda Başlatma
```bash
# 1. API konteynerini başlatın:
docker run -d --name api-service --network my-net my-api:1.0

# 2. Web konteynerini aynı ağda başlatın:
docker run -d --name web-service --network my-net -p 8080:80 nginx:alpine
```

### İsimle DNS Çözümlemesini Test Etme
```bash
docker exec -it web-service ping -c 2 api-service
```
* **Açıklama:** Docker'ın dahili DNS sunucusu (`127.0.0.11`) `api-service` ismini otomatik olarak doğru IP'ye çözümler.

---

## 3. Canlı Ağa Bağlama ve Ayırma (Multi-Homed Container)

Çalışan bir konteyneri durdurmadan ikinci bir ağa bağlamak (DMZ senaryosu).

### Konteyneri Canlı Olarak İkinci Bir Ağa Bağlama
```bash
docker network connect dmz-net web-service
```
* **Açıklama:** `web-service` artık hem `my-net` hem de `dmz-net` ağlarına üyedir; her iki ağdan da IP alır.

### Konteyneri Ağdan Ayırma
```bash
docker network disconnect dmz-net web-service
```

---

## 4. Özel Ağ Modları

### Host Ağ Modu (Port Eşleme Olmadan Doğrudan Host Portunu Dinleme)
```bash
docker run -d --name proxy --network host nginx:alpine
```
* **Açıklama:** Konteyner Nginx'in 80 portunu doğrudan host'un 80 portuna bağlar (`-p` parametresine gerek kalmaz).

### Tamamen İzole Ağ Modu (Ağ Kartı Yok)
```bash
docker run -it --rm --network none alpine ip addr
```
* **Açıklama:** Yalnızca `127.0.0.1` (lo) döngüsel kartı aktiftir; internet ve dış ağ erişimi tamamen kesiktir.
