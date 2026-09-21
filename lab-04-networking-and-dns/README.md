# LAB-04: Konteyner Ağları ve Dahili DNS İletişimi

## 🎯 Labın Amacı
Varsayılan `bridge` ağının kısıtlarını görmek, özel bir köprü ağı (`docker network create`) oluşturmak, dahili Docker DNS (`127.0.0.11`) motorunu kullanarak iki konteyneri sabit IP adresi bilmeden isimleriyle konuşturmak ve ağ izolasyonu sağlamak.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. Varsayılan Bridge Ağının Kısıtını Görme
Docker'ın varsayılan `bridge` ağı konteyner isimlerini DNS üzerinden çözümleyemez:

```bash
# Varsayılan ağda iki konteyner başlatın:
docker run -d --name default-c1 alpine sleep 3600
docker run -d --name default-c2 alpine sleep 3600

# c2 konteynerinden c1 konteynerine ismiyle ping atmayı deneyin:
docker exec default-c2 ping -c 2 default-c1 || echo 'BAŞARISIZ: Varsayılan bridge ağında dahili DNS çözümü yoktur'

# Temizleyin:
docker rm -f default-c1 default-c2
```

### 2. Özel Kullanıcı Tanımlı Ağ (Custom Bridge) Oluşturma
```bash
# İzole bir özel köprü ağı oluşturun:
docker network create internal-net

# Ağları listeleyin:
docker network ls
```

### 3. Dahili DNS ile Konteyner Haberleşmesi
Kullanıcı tanımlı ağlarda Docker'ın gömülü DNS sunucusu (`127.0.0.11`) otomatik devreye girer:

```bash
# 1. Özel ağ üzerinde bir Nginx web servisi başlatın:
docker run -d --name backend-api --network internal-net nginx:alpine

# 2. Aynı ağ üzerinde bir istemci (client) konteyneri açın:
docker run -d --name frontend-client --network internal-net alpine sleep 3600

# 3. İstemci içinden backend servisine ismiyle ping atın:
docker exec frontend-client ping -c 2 backend-api

# 4. İstemci içinden web servisine doğrudan ismiyle HTTP isteği atın:
docker exec frontend-client wget -qO- http://backend-api | grep "Welcome to nginx!"
```

### 4. Çalışan Konteyneri Canlı Olarak Ağa Bağlama / Koparma
Konteyneri durdurmadan ağ kartı ekleyip çıkarın:

```bash
# İkinci bir ağ açın:
docker network create dmz-net

# frontend-client konteynerini bu yeni ağa da dahil edin:
docker network connect dmz-net frontend-client

# Konteynerin iki ayrı ağdan IP aldığını denetleyin:
docker inspect -f '{{json .NetworkSettings.Networks}}' frontend-client

# Ağdan bağlantıyı koparın:
docker network disconnect dmz-net frontend-client
```

### 5. Host ve None Ağ Modları
- `--network host`: Ağ izolasyonunu kaldırır, host'un ağ kartını doğrudan kullanır (en yüksek performans, sıfır izolasyon).
- `--network none`: Konteynerin dış dünyayla tüm ağ bağlantısını keser (loopback hariç), tam izolasyon.

```bash
# Dış dünyadan tamamen izole konteyner testi:
docker run --rm --network none alpine ip addr
```

---

## ✅ Doğrulama (Verification)
```bash
docker exec frontend-client ping -c 1 backend-api
```
Komutu `1 packets transmitted, 1 packets received, 0% packet loss` çıktısıyla isim çözümlemesinin çalıştığını teyit etmelidir.

---

## 🧹 Temizlik
```bash
docker rm -f backend-api frontend-client 2>/dev/null || true
docker network rm internal-net dmz-net 2>/dev/null || true
```
