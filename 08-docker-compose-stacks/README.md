# LAB-DOC-08 — Docker Compose Mimarileri ve Orkestrasyon

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `docker compose v2`, `nginx`, `redis`, `postgres` | 80, 5000, 8080 |

> **Önemli Erişim Notu:** Compose ile ayağa kaldırılan servisleri (örneğin 3-Tier Web API veya Voting App) test ederken `http://<SUNUCU-IP>:<PORT>` (Örn: Port 80, Port 5000 veya Port 8080) adresini kullanabilir veya yerel olarak `curl http://localhost:<PORT>` komutuyla doğrulama yapabilirsiniz.

---

## Amaç

Bu modülde çoklu konteyner mimarilerinin (Multi-Container Stacks) Docker Compose V2 kullanılarak tek bir bildirimsel YAML dosyası (`docker-compose.yaml`) ile nasıl yönetildiği, servisler arası sağlık kontrolleri (`depends_on: condition: service_healthy`), ortam değişkenleri (`.env`), çift ağ izolasyonu ve çoklu ortam profilleri (`profiles`) uygulamalı olarak incelenir.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-compose-fundamentals`](01-compose-fundamentals/README.md) | Orta | `services`, `networks`, `volumes`, `.env` değişkenleri ve `service_healthy` bağımlılık zinciri. |
| **02** | [`02-wordpress-mysql`](02-wordpress-mysql/README.md) | Orta | İki katmanlı klasik CMS mimarisi ve Named Volume kalıcılığı. |
| **03** | [`03-3tier-web-api-db`](03-3tier-web-api-db/README.md) | Orta - İleri | Nginx Gateway (Port 80) + FastAPI + Redis + PostgreSQL ile Çift Ağ (DMZ) izolasyonu. |
| **04** | [`advanced/04-example-voting-app`](advanced/04-example-voting-app/README.md) | İleri | Polyglot 5 bileşenli mikroservis mimarisi: Python (`vote`), Node.js (`result`), .NET (`worker`), Redis ve Postgres. |
| **05** | [`advanced/05-compose-profiles-and-overrides`](advanced/05-compose-profiles-and-overrides/README.md) | İleri | `profiles: [debug, tools]`, çoklu ortam (`compose.prod.yaml`) ve ortam bazlı yapılandırma ezme (override). |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-compose-fundamentals
cat README.md
```
