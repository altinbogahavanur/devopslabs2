# LAB-DOC-05 — Docker Ağ Mimarisi: Bridge, Dahili DNS ve İzolasyon

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|---|---|---|---|
| Orta | 40 Dakika | `docker-ce`, `bridge`, `host`, `none`, `dns` | 8080 |

## Amaç
- Konteynerların birbirleriyle ve dış dünyayla nasıl iletişim kurduğunu kavramak.
- Varsayılan (default) bridge ağında neden isimle DNS çözümleme yapılamadığını anlamak.
- Kullanıcı tanımlı bridge ağı (`docker network create`) ile dahili DNS (`127.0.0.11`) çözümlemesini kurmak (`api -> db`).
- `--network host` ile sıfır NAT gecikmesi ve `--network none` ile tam ağ izolasyonu senaryolarını test etmek.
- DMZ mimarisiyle veritabanını internete kapatıp sadece backend mikroservisinin erişimine açmak.

## Ön Koşullar
- `lab-01-docker-engine-and-warmup` ve `lab-02-dockerfile-and-caching` tamamlanmış olmalıdır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Alt Dizin | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-custom-bridge-and-dns`](01-custom-bridge-and-dns/README.md) | Orta | Özel bridge ağı oluşturma, dahili DNS (`127.0.0.11`) çözümleme ve port eşleme (`-p`). |
| **02** | [`02-host-and-none-networks`](02-host-and-none-networks/README.md) | Orta | `--network host` ile sıfır NAT gecikmesi ve `--network none` ile tam ağ izolasyonu. |
| **03** | [`advanced/03-multi-network-dmz-and-aliases`](advanced/03-multi-network-dmz-and-aliases/README.md) | İleri | Çoklu ağ köprüsü (DMZ Mimarisi), veritabanını dış dünyadan yalıtma ve ağ takma adları (`--network-alias`). |

---

## Hızlı Başlangıç

```bash
cd lab-05-docker-networking-and-dns/01-custom-bridge-and-dns
cat README.md
```
