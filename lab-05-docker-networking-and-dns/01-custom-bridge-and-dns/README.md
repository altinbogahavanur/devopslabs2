# LAB-DOC-05-01 — Özel Bridge Ağı, Dahili DNS ve Port Yönlendirme

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `postgres:17-alpine`, `nginx:alpine`, `busybox` | 8080 |

> **Önemli Erişim Notu:** Ağ üzerinden dışa açılan web servisini `http://<SUNUCU-IP>:8080` adresinden tarayıcınızdan veya `curl http://localhost:8080` komutuyla test edebilirsiniz.

---

## Amaç

- Varsayılan `bridge` ağı ile kullanıcı tanımlı (`user-defined bridge`) ağ arasındaki kritik farkları öğrenmek.
- Kullanıcı tanımlı ağlarda otomatik aktif olan **Dahili DNS (Embedded DNS - 127.0.0.11)** ile konteynerlerin birbirlerini IP yerine isimleriyle bulmasını sağlamak.
- Dış dünyadan gelen trafiği `-p [HOST]:[CONTAINER]` ile konteyner portuna yönlendirmek (Port Publishing).

---

## Ön Koşullar

- LAB-DOC-04 tamamlanmış olmalıdır.
- Host üzerinde `8080` portu boşta olmalıdır.

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

## Adım Adım Uygulama Rehberi

### 1. Kullanıcı Tanımlı Bridge Ağ Oluşturma
```bash
# app-net adında bir bridge ağ oluşturun:
docker network create --driver bridge app-net

# Ağları listeleyin:
docker network ls
```

### 2. Ağ Üzerinde Veritabanı Konteyneri Başlatma
```bash
# Veritabanını app-net ağına bağlayarak başlatın (Dış dünyaya port açmaya gerek yok!):
docker run -d --name net-db --network app-net \
  -e POSTGRES_PASSWORD=BilgincIT454 \
  postgres:17-alpine
```

### 3. Dahili DNS Çözümlemesini Test Etme
```bash
# Geçici bir busybox konteynerını aynı ağa bağlayıp 'net-db' ismini çözümleyip test edin:
docker run --rm --network app-net busybox ping -c 2 net-db
```

### 4. Web Sunucusunu Başlatma ve Port Eşleme
```bash
# Nginx web sunucusunu hem app-net ağına bağlayın hem de hostun 8080 portuna açın:
docker run -d --name net-web --network app-net -p 8080:80 nginx:alpine

# Host üzerinden erişimi doğrulayın:
curl http://localhost:8080
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker run --rm --network app-net alpine getent hosts net-db
# net-db ismi için IP adresi (172.x.x.x) başarıyla çözümlenmelidir.
```

---

## Temizlik

```bash
docker rm -f net-web net-db 2>/dev/null || true
docker network rm app-net 2>/dev/null || true
```
