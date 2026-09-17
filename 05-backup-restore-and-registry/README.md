# LAB-DOC-05 — İmaj/Volume Yedekleme ve Kurumsal Registry Yönetimi

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `docker-ce`, `registry:2`, `harbor`, `trivy` | 5000, 8085 |

Konteyner ortamlarında felaket kurtarma (disaster recovery), internetsiz (air-gapped) ortamlara imaj ve veri taşıma, yerel ve kurumsal OCI Registry (Harbor) yönetimi bu modülün ana odağıdır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-image-backup-restore`](01-image-backup-restore/README.md) | Orta | `docker save`/`load` ile katmanlı imaj arşivleme ve geçici yardımcı konteyner (`alpine`) ile Named Volume `.tar.gz` yedeği alma. |
| **02** | [`02-local-registry-v2`](02-local-registry-v2/README.md) | Orta | `registry:2` ile yerel OCI kayıt defteri kurma, `docker push`/`pull` ve Registry HTTP v2 API katalog sorgulama. |
| **03** | [`advanced/03-enterprise-harbor-registry`](advanced/03-enterprise-harbor-registry/README.md) | İleri | Kurumsal VMware Harbor mimarisi, RBAC, CI/CD Robot hesapları, Değiştirilemez Etiket (Tag Immutability) ve Trivy zafiyet taraması. |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-image-backup-restore
cat README.md
```
