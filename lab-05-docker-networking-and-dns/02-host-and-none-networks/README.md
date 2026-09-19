# LAB-DOC-05-02 — Host ve None Ağ Sürücüleri: Yüksek Performans ve Tam İzolasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `nginx:alpine`, `busybox` | 80 (Host Network) |

---

## Amaç

- Docker'ın dahili NAT ve bridge katmanlarını atlayarak doğrudan ana makinenin ağ kartını kullanan `--network host` modunu incelemek.
- Dış ve iç ağ bağlantısı tamamen kesilmiş, yalnızca yerel döngü (loopback) barındıran `--network none` moduyla izole güvenliği deneyimlemek.

---

## Ön Koşullar

- LAB-DOC-05-01 tamamlanmış olmalıdır.
- Host üzerinde `80` portu boşta olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
1. HOST NETWORK (--network host)
   [ Host Ağ Kartı (eth0) ] ──── [ Konteyner Süreci (Nginx) ]  (NAT Yok! Sıfır Gecikme)

2. NONE NETWORK (--network none)
   +───────────────────────────────────+
   | KONTEYNER (Yalıtılmış Ada)        |
   | - Sadece 'lo' (127.0.0.1) var.    |
   | - 'eth0' YOKTUR! İnternet/Ağ YOK! |
   +───────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Host Network ile Web Sunucusu Başlatma
```bash
# -p vermeden doğrudan host ağıyla başlatın (Konteyner hostun 80 portunu dinler):
docker run -d --name host-web --network host nginx:alpine

# Host makinenin port dinleme tablosunda 80'i kontrol edin:
sudo ss -tulpn | grep ':80'

# Doğrudan localhost üzerinden test edin:
curl -I http://localhost:80

docker rm -f host-web
```

### 2. None Network ile Tam Ağ İzolasyonu
```bash
# Ağ kartı olmayan izole bir konteyner çalıştırıp ağ arayüzlerini listeleyin:
docker run --rm --network none busybox ip addr
```

### 3. İzolasyonu Test Etme (Dış Ağ Engeli)
```bash
# Ağ bağlantısı denemesi yaptığınızda 'Network is unreachable' hatası almalısınız:
docker run --rm --network none busybox ping -c 1 8.8.8.8 2>&1 || true
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker run --rm --network none busybox ip link
# Çıktıda yalnızca '1: lo:' görünmeli, 'eth0' bulunmamalıdır.
```

---

## Temizlik

```bash
docker rm -f host-web 2>/dev/null || true
```
