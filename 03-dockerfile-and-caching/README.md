# LAB-DOC-03 — Dockerfile Direktifleri, Önbellekleme ve Multi-Stage İmajlar

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Temel - İleri | `docker-ce`, `buildkit`, `golang`, `nodejs` | 3000, 8080 |

Konteyner dünyasında imajlar birer kod dosyası (`Dockerfile`) ile tanımlanır. Bu modülde, temel direktiflerden başlayarak derleme hızını artıran katman önbellekleme (layer caching) teknikleri ve imaj boyutlarını %90'a varan oranda düşüren çok aşamalı derleme (Multi-Stage Builds) desenleri incelenir.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-dockerfile-directives`](01-dockerfile-directives/README.md) | Temel | `FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE` direktifleri ve `CMD` vs `ENTRYPOINT` farkı. |
| **02** | [`02-layer-caching-and-optimization`](02-layer-caching-and-optimization/README.md) | Temel - Orta | Katman sıralaması, önbellek bozulmasını önleme (`CACHED`), `.dockerignore` kullanımı ve derleme hızı kıyaslaması. |
| **03** | [`advanced/03-multistage-builds-and-buildkit`](advanced/03-multistage-builds-and-buildkit/README.md) | İleri | Çok aşamalı derleme deseni (Builder vs Runtime), Go/Alpine optimizasyonu, 800 MB'tan 12 MB'a imaj küçültme. |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-dockerfile-directives
cat README.md
```
