# 🐳 Docker Pratik Teftiş ve Sorun Giderme Laboratuvarları

Bu dizin, Docker dünyasında sadece teorik konteyner başlatmanın ötesine geçerek; **çalışan konteynerin içine girme (`exec`), canlı dosya kopyalama (`cp`), log filtreleme, proses takibi (`top`), ağ ve disk birimlerini cerrahi olarak denetleme (`inspect`)** becerilerini kazandıran hızlı pratik laboratuvarları içerir.

---

## 📑 Pratik Laboratuvar Listesi

| Dizin | Konu | Süre | Öğrenilen Temel Refleks |
|---|---|:---:|---|
| [`01-exec-ve-dosya-transferi/`](./01-exec-ve-dosya-transferi/README.md) | **`exec` ve `cp` İle Dosya Transferi** | 10 Dk | Canlı konteyner içine kabuk açma, host'tan içeriye hotfix atma, konteynerden dışarıya log ve konfigürasyon çekme |
| [`02-log-ve-canli-teftis/`](./02-log-ve-canli-teftis/README.md) | **Log Dedektifliği, `top` ve `inspect`** | 10 Dk | Canlı log takibi (`-f`, `--tail`), konteyner içi proses listesi (`docker top`), kaynak tüketimi (`docker stats`) ve Go template ile IP filtreleme |
| [`03-volume-ve-network-kontrol/`](./03-volume-ve-network-kontrol/README.md) | **Volume ve Network Teftişi** | 10 Dk | Kalıcı named volume denetimi, özel bridge ağ kurma, iki konteyneri dahili DNS adıyla konuşturma, `connect/disconnect` |
| [`04-veri-kaliciligi-ve-volume-kurtarma/`](./04-veri-kaliciligi-ve-volume-kurtarma/README.md) | **Veri Kalıcılığı ve MySQL Kurtarma** | 15 Dk | Volumesiz konteyner silinince veri kaybı deneyi, Named Volume ile konteyner silinse bile veriyi kurtarma |

---

## 🚀 Hızlı Başlangıç

İlgili lab klasörüne girip yönergeleri uygulayabilirsiniz:

```bash
# Örnek: Canlı Konteyner Teftişi
cd pratik-lablar/01-exec-ve-dosya-transferi
docker run -d --name test-web -p 19001:80 nginx:alpine
docker cp ornek-hotfix.html test-web:/usr/share/nginx/html/index.html
curl http://localhost:19001
docker rm -f test-web
```
