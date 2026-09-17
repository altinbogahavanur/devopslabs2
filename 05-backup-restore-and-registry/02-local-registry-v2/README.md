# LAB-DOC-05-02 — Yerel OCI Registry (Docker Registry v2)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `registry:2`, `docker-ce`, `curl` | 5000 |

> **Önemli Erişim Notu:** Yerel OCI Registry API sorgularını doğrudan sunucu içinden `curl http://localhost:5000/v2/_catalog` komutuyla yapabilirsiniz.

---

## Amaç

- Kurum içinde veya yerel geliştirme ortamında Docker Hub'a bağımlı kalmadan özel imaj deposu (`registry:2`) çalıştırmak.
- İmajları yerel registry adresine göre etiketlemek (`localhost:5000/uygulama:etiket`).
- Registry HTTP API v2 kullanarak depodaki imajları ve etiketleri sorgulamak.

---

## Ön Koşullar

- LAB-DOC-05-01 tamamlanmış olmalıdır.
- Host üzerinde `5000` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
[Geliştirici Terminali]
      │
      ├── docker tag alpine:3.20 localhost:5000/my-alpine:v1
      │
      ├── docker push localhost:5000/my-alpine:v1 ────┐
      │                                                ▼
      │                                  +───────────────────────────+
      │                                  | LOCAL REGISTRY CONTAINER  |
      │                                  | - Port: 5000              |
      │                                  | - Depo: /var/lib/registry |
      │                                  +───────────────────────────+
      │                                                │
      └── docker pull localhost:5000/my-alpine:v1 ─────┘
```

---

## Adım Adım Uygulama Rehberi

### 1. Yerel Registry Konteynerını Başlatma
```bash
# Kalıcı veri alanı ile Registry v2 konteynerını başlatın:
docker run -d -p 5000:5000 --restart=always --name local-registry registry:2

# Registry durumunu kontrol edin:
curl -I http://localhost:5000/v2/
# HTTP/1.1 200 OK yanıtı dönmelidir.
```

### 2. İmajı Yerel Depo İçin Etiketleme ve Gönderme (Push)
```bash
# 1. Küçük bir temel imaj çekin:
docker pull busybox:latest

# 2. Yerel registry adresine göre etiketleyin:
docker tag busybox:latest localhost:5000/my-busybox:1.0

# 3. İmajı yerel registry'ye yükleyin:
docker push localhost:5000/my-busybox:1.0
```

### 3. Registry API ile Depoyu Sorgulama
```bash
# Depodaki imaj listesini (katalog) çekin:
curl http://localhost:5000/v2/_catalog

# my-busybox imajının etiketlerini sorgulayın:
curl http://localhost:5000/v2/my-busybox/tags/list
```

### 4. Yerel Depodan İmaj Çekme (Pull)
```bash
# 1. Yereldeki imajları silin:
docker rmi localhost:5000/my-busybox:1.0 busybox:latest

# 2. Kendi yerel registry'nizden çekin:
docker pull localhost:5000/my-busybox:1.0

# 3. Konteynerı çalıştırıp test edin:
docker run --rm localhost:5000/my-busybox:1.0 echo "Yerel Registry'den basariyla calisti!"
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:5000/v2/_catalog | grep "my-busybox"
# Çıktıda '{"repositories":["my-busybox"]}' görünmelidir.
```

---

## Temizlik

```bash
docker rm -f local-registry 2>/dev/null || true
docker rmi localhost:5000/my-busybox:1.0 2>/dev/null || true
```
