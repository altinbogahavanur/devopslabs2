# LAB-DOC-05-02 — Host ve None Ağ Sürücüleri: Yüksek Performans ve Tam İzolasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `python:3.12-alpine`, `busybox` | 8088 (Host Network) |

---

## Amaç

- Docker'ın dahili NAT ve bridge katmanlarını atlayarak doğrudan ana makinenin ağ kartını kullanan `--network host` modunu incelemek.
- Dış ve iç ağ bağlantısı tamamen kesilmiş, yalnızca yerel döngü (loopback) barındıran `--network none` moduyla izole güvenliği deneyimlemek.

---

## Ön Koşullar

- LAB-DOC-05-01 tamamlanmış olmalıdır.
- Host üzerinde `8088` portu boşta olmalıdır (Host üzerindeki `80` ve `443` portları Nginx Ters Proxy servisine ayrıldığından, host network testlerinde çakışmayı önlemek için `8088` portu kullanılır).

---

## Mimari ve Çalışma Modeli

```text
1. HOST NETWORK (--network host)
   [ Host Ağ Kartı (eth0) ] ──── [ Konteyner Süreci (Port 8088) ]  (NAT Yok! -p Yönlendirme Yok!)

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

Ana makinenin ağ yığınını doğrudan kullanan bir web servisi başlatın. `-p` ile port eşleme yapılmasına gerek yoktur; konteyner süreci doğrudan hostun `8088` portunu dinler:

```bash
docker run -d --name host-web --network host python:3.12-alpine python3 -m http.server 8088
```

> **Neden Port 80 Değil?:** Üretim ve eğitim ortamlarında host makinenin 80 ve 443 portları Nginx Master Reverse Proxy tarafından dinlenir. `--network host` modunda konteyner doğrudan host arayüzlerine bağlandığı için port 80 kullanılırsa `bind: address already in use` hatası oluşur. Bu nedenle çakışma yaşamayan `8088` portu tercih edilmiştir.

### 2. Port Dinleme Tablosunu Kontrol Etme

Host makinenin soket tablosunda `8088` portunun doğrudan python süreci tarafından dinlendiğini doğrulayın:

```bash
sudo ss -tulpn | grep ':8088'
```

### 3. Doğrudan Localhost Üzerinden Test Etme

```bash
curl -I http://localhost:8088
```

Test sonrasında konteynerı durdurup silin:

```bash
docker rm -f host-web
```

### 4. None Network ile Tam Ağ İzolasyonu

Ağ kartı olmayan, yalnızca yerel döngü (loopback) barındıran izole bir konteyner çalıştırıp ağ arayüzlerini listeleyin:

```bash
docker run --rm --network none busybox ip addr
```

### 5. Ağ İzolasyonunu Doğrulama (Dış Ağ Engeli)

Ağ bağlantısı denemesi yaptığınızda ağ arayüzü bulunmadığı için doğrudan hata alınmalıdır:

```bash
docker run --rm --network none busybox ping -c 1 8.8.8.8 2>&1 || true
```

---

## Doğal Doğrulama ve Beklenen Sonuç

None ağ modunda yalnızca `lo` arayüzünün bulunduğunu doğrulayın:

```bash
docker run --rm --network none busybox ip link
```

Beklenen çıktı:
```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```
*(Çıktıda `eth0` veya herhangi bir sanal ethernet köprüsü bulunmamalıdır.)*

---

## Temizlik

```bash
docker rm -f host-web 2>/dev/null || true
```
