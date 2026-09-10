# LAB-06 — Docker Networking: Custom Bridge, Dahili DNS ve Ağ İzolasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `postgres:17-alpine`, `nginx:alpine`, `busybox` | `8080` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 60-63, Lab 4); Docker ağ sürücülerini (`bridge`, `host`, `none`, `overlay`) kavramak, kullanıcı tanımlı bir bridge ağ (`user-defined bridge`) oluşturarak konteynerların birbirlerini **IP adresi yerine konteyner isimleriyle (Embedded DNS)** bulmasını sağlamak ve `none` network ile tam izolasyonu doğrulamaktır:

1. **User-defined Bridge Mimarisi:** Varsayılan bridge ağından farklı olarak dahili DNS (`127.0.0.11`) çözümlemesini aktif etmek.
2. **Dahili DNS Testi:** `busybox nslookup db` komutu ile IP adresleri dinamik değişse bile servis adıyla iletişimi kanıtlamak.
3. **Port Publishing (-p):** Dış dünyadan (host) gelen trafiğin konteyner portuna yönlendirilmesini izlemek.
4. **None Network:** Loopback haricinde hiçbir ağ arayüzü barındırmayan, ağ erişimi sıfırlanmış güvenli konteyner çalıştırmak.

---

## 2. Ön Koşullar

* Docker Engine çalışır durumda olmalıdır (`docker info`).
* Host üzerinde `8080` portu boşta olmalıdır.

---

## 3. Mimari ve Çalışma Modeli

```text
               HOST MAKİNE (Ubuntu)
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ Port 8080 ───┐                                                          │
  │              ▼                                                          │
  │   +───────────────────────────+       +─────────────────────────────+   │
  │   | net-web (Nginx)           |       | net-db (PostgreSQL)         |   │
  │   | IP: 172.18.0.3            |       | IP: 172.18.0.2              |   │
  │   +─────────────┬─────────────+       +──────────────┬──────────────+   │
  │                 │                                    │                  │
  │                 ▼                                    ▼                  │
  │   ======================= app-net (Bridge) ========================     │
  │               (Dahili DNS Çözümleme: 'net-db' ➔ 172.18.0.2)             │
  └─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Görevler (Tasks)

1. **Özel Bridge Ağ Oluşturma:** `app-net` adında kullanıcı tanımlı bir bridge ağ oluşturun ve ağ listesini denetleyin.
2. **Veritabanı Konteyneri Başlatma:** `postgres:17-alpine` imajını kullanarak `app-net` ağına bağlı `net-db` adında bir veritabanı konteyneri başlatın.
3. **Dahili DNS Çözümleme Testi:** `app-net` ağına geçici bir `busybox` konteyneri bağlayarak `nslookup net-db` komutuyla DNS çözümlemesini test edin.
4. **Web Sunucusu ve Port Yayınlama:** `nginx:alpine` imajıyla `app-net` ağına bağlı `net-web` konteynerını hostun `8080` portuna publish ederek başlatın ve `curl` ile erişimi teyit edin.
5. **None Network İzolasyonu:** `--network none` parametresiyle bir test konteyneri çalıştırıp ağ arayüzlerini listeleyerek (`ip addr`) tam ağ izolasyonunu doğrulayın.
6. **Otomasyon Doğrulaması:** `scripts/verify-networking.sh` betiği ile tüm senaryoları uçtan uca test edin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Default Bridge vs User-defined Bridge</summary>

Docker'ın varsayılan `bridge` ağı konteyner isimlerini DNS ile **çözemez** (yalnızca eski `--link` ile çalışır). Konteynerların birbirine `ping db` veya `http://api:8000` şeklinde servis adıyla erişebilmesi için **kullanıcı tanımlı bir bridge ağ (`docker network create`) şarttır.**
</details>

<details>
<summary>💡 İpucu 2: Embedded DNS IP Adresi</summary>

Docker içinde çalışan dahili DNS sunucusu her zaman `127.0.0.11` adresindedir. `/etc/resolv.conf` dosyasına bakıldığında `nameserver 127.0.0.11` görülür.
</details>

<details>
<summary>💡 İpucu 3: --network none Nerelerde Kullanılır?</summary>

Hassas toplu işlem (batch processing), kriptografik hesaplama veya gizli anahtar üretimi yapan ve dış internetle kesinlikle temas etmemesi gereken konteynerlar için `--network none` mükemmel bir güvenlik kalkanıdır.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla ağ bağlantılarını ve DNS çözümlemesini teyit edin:

```bash
# 1. Ağdaki bağlı konteynerlar
docker network inspect app-net | grep -A 5 "Containers"

# 2. Web sunucusu HTTP yanıtı
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080
```

* **Beklenen Başarı Çıktısı:**
  * `app-net` JSON çıktısında hem `net-web` hem de `net-db` konteynerlarının IPv4 adresleri listelenmelidir.
  * `curl` HTTP yanıt kodu olarak `200` dönmelidir.

---

## 7. Temizlik

Laboratuvar tamamlandığında konteynerları ve özel ağı silin:

```bash
docker rm -f net-web net-db 2>/dev/null || true
docker network rm app-net 2>/dev/null || true
```
