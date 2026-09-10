# LAB-06 — Docker Networking: Custom Bridge, Dahili DNS ve Ağ İzolasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç - Orta | 40 dakika | `docker-ce`, `postgres:17-alpine`, `nginx:alpine`, `busybox` | `8080` |

---

## Mimari ve Çalışma Modeli

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

## Adım Adım Uygulama

### Adım 1: Kullanıcı Tanımlı Bridge Ağ Oluşturma

Varsayılan `bridge` ağından farklı olarak kullanıcı tanımlı ağlarda konteynerlar birbirini IP yerine doğrudan isimleriyle (Dahili DNS - `127.0.0.11`) bulabilir:

```bash
docker network create app-net
docker network ls
```

---

### Adım 2: Veritabanını Ağ İçinde Başlatma

```bash
docker run -d --name net-db --network app-net -e POSTGRES_PASSWORD=secret postgres:17-alpine
```

---

### Adım 3: Dahili DNS Çözümlemesini Test Etme

Aynı ağa geçici bir konteyner bağlayarak `net-db` isminin çözülmesini test edin:

```bash
docker run --rm --network app-net busybox nslookup net-db
```

*Çıktıda `net-db` isminin Docker dahili DNS'i tarafından `172.18.0.2` gibi bir IP'ye çözüldüğünü gözlemleyin.*

---

### Adım 4: Web Sunucusunu Başlatma ve Port Eşleme

```bash
docker run -d --name net-web --network app-net -p 8080:80 nginx:alpine

# Ağa bağlı konteynerları denetleme
docker network inspect app-net

# Host üzerinden erişimi doğrulama
curl -I http://localhost:8080
```

---

### Adım 5: None Network ile Tam İzolasyon

Dış dünya ile veya diğer konteynerlarla hiçbir temas kurmaması gereken güvenli iş yükleri için ağsız (`none`) mod kullanılır:

```bash
docker run --rm --network none busybox ip addr
```

*Çıktıda sadece `127.0.0.1 (lo)` olduğunu, harici ağ kartı (`eth0`) bulunmadığını gözlemleyin.*

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker rm -f net-web net-db 2>/dev/null || true
docker network rm app-net 2>/dev/null || true
```
