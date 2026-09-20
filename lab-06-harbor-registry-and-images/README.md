# LAB-DOC-06 — İmaj Yönetimi, Yerel Registry:2 ve Kurumsal Harbor Registry

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `docker-ce`, `docker-hub`, `registry:2`, `harbor`, `trivy` | 5000, 18444 |

## Amaç
- Konteyner imajlarının etiketleme standartlarını (Semantic Versioning: `v1.0.0`, `latest`) ve OCI imaj formatını kavramak.
- Docker Hub üzerinde public ve private repository oluşturarak aynı imajın erişim davranışını doğrulamak.
- Yerel testler için `registry:2` konteyneri kurarak HTTP v2 API üzerinden imaj `push` ve `pull` işlemlerini denemek.
- Kurumsal **Harbor OCI Registry** (`18444`) üzerinde proje oluşturmak, robot hesabı ile kimlik doğrulaması yapmak.
- Üretim ortamlarında imajların üzerine kazara yazılmasını engelleyen **Tag Immutability (Değiştirilemez Etiket)** ve **Immutable Digest (`@sha256:...`)** güvenlik kurallarını uygulamak.

## Ön Koşullar
- `lab-01-docker-engine-and-warmup` ve `lab-02-dockerfile-and-caching` tamamlanmış olmalıdır.
- Platformda Harbor Registry servisinin (`http://<HOST_IP>/harbor` veya `http://127.0.0.1:18444`) çalışır durumda olması.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Alt Dizin | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`02-local-registry-v2`](02-local-registry-v2/README.md) | Orta | `registry:2` (`5000`) ile hafif yerel OCI registry kurma, `docker push`/`pull` ve HTTP v2 API katalog sorgulama. |
| **02** | [`harbor`](harbor/README.md) | İleri | Kurumsal VMware Harbor mimarisi, RBAC, Robot hesapları, Tag Immutability ve Trivy zafiyet taraması. |
| **03** | [`03-docker-hub-public-private`](03-docker-hub-public-private/README.md) | Orta | Docker Hub public/private repository oluşturma, PAT ile güvenli giriş, image tag/push/pull ve erişim doğrulaması. |

---

## Hızlı Başlangıç

```bash
cd lab-06-harbor-registry-and-images/02-local-registry-v2
cat README.md
```
