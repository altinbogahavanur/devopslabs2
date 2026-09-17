# LAB-DOC-06 — Docker Ağ Mimarisi: Bridge, DNS ve İzolasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `docker-ce`, `bridge`, `host`, `none`, `dns` | 80, 8080 |

Konteynerların birbirleriyle ve dış dünyayla nasıl iletişim kurduğu kurumsal mimarilerin temelini oluşturur. Bu modülde, kullanıcı tanımlı bridge ağları, yerleşik DNS çözümleme, host/none sürücüleri ve DMZ tarzı çoklu ağ mimarileri ele alınır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-custom-bridge-and-dns`](01-custom-bridge-and-dns/README.md) | Orta | Özel bridge ağı oluşturma, dahili DNS (`127.0.0.11`) çözümleme ve port eşleme (`-p`). |
| **02** | [`02-host-and-none-networks`](02-host-and-none-networks/README.md) | Orta | `--network host` ile sıfır NAT gecikmesi ve `--network none` ile tam ağ izolasyonu. |
| **03** | [`advanced/03-multi-network-dmz-and-aliases`](advanced/03-multi-network-dmz-and-aliases/README.md) | İleri | Çoklu ağ köprüsü (DMZ Mimarisi), veritabanını dış dünyadan yalıtma ve ağ takma adları (`--network-alias`). |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-custom-bridge-and-dns
cat README.md
```
