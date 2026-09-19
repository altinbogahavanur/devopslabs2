# LAB-DOC-02 — Dockerfile Direktifleri, Önbellekleme ve Multi-Stage İmajlar

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Temel - Orta | `docker-ce`, `buildkit`, `golang`, `nodejs` | 3000, 8080 |

## Amaç
- Konteyner dünyasında imajların kod olarak altyapı (IaC) prensibiyle `Dockerfile` üzerinden tanımlanmasını öğrenmek.
- Temel direktiflerin (`FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE`) kullanımını ve `CMD` ile `ENTRYPOINT` arasındaki farkları kavramak.
- Docker BuildKit mimarisi ile katman önbellekleme (layer caching) optimizasyonunu uygulamak ve derleme sürelerini 30 saniyeden 0.1 saniyeye indirmek (`---> CACHED`).
- Çok aşamalı derleme (Multi-Stage Builds) deseni ile derleme araçlarını nihai imajın dışında bırakarak imaj boyutlarını %90 küçültmek.

## Ön Koşullar
- `lab-01-docker-engine-and-warmup` tamamlanmış olmalıdır.

---

## Modül Laboratuvarları

Bu laboratuvar serisini sırasıyla uygulayınız:

| No | Alt Dizin | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-dockerfile-directives`](01-dockerfile-directives/README.md) | Temel | `FROM`, `WORKDIR`, `COPY`, `RUN`, `ENV`, `EXPOSE` direktifleri ve `CMD` vs `ENTRYPOINT` farkı. |
| **02** | [`02-layer-caching-and-optimization`](02-layer-caching-and-optimization/README.md) | Temel - Orta | Katman sıralaması, önbellek bozulmasını önleme (`CACHED`), `.dockerignore` kullanımı ve derleme hızı kıyaslaması. |
| **03** | [`advanced/03-multistage-builds-and-buildkit`](advanced/03-multistage-builds-and-buildkit/README.md) | İleri | Çok aşamalı derleme deseni (Builder vs Runtime), Go/Alpine optimizasyonu, 800 MB'tan 12 MB'a imaj küçültme. |

---

## Hızlı Başlangıç

```bash
cd lab-02-dockerfile-and-caching/01-dockerfile-directives
cat README.md
```
