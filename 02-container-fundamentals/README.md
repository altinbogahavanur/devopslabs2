# LAB-DOC-02 — Konteyner Temelleri ve Yaşam Döngüsü

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Başlangıç - İleri | `docker-ce`, `curl`, `cgroups-v2` | 8080, 8081 |

Konteyner dünyasına ilk adım bu modülde atılır. Konteynerların başlatılması, süreç ve dosya izolasyonu, çift yönlü veri kopyalama ve kaynak sınırları (CPU/RAM/OOM) uygulamalı olarak incelenir.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-container-lifecycle`](01-container-lifecycle/README.md) | Başlangıç | Konteyner yaşam döngüsü (`run`, `stop`, `rm`, `logs -f`, `exec -it`) ve port eşleme (`-p`). |
| **02** | [`02-file-operations-and-commit`](02-file-operations-and-commit/README.md) | Başlangıç - Orta | Host ve konteyner arası dosya aktarımı (`docker cp`), `diff`, anlık durum imajı (`commit`) ve teşhis komutları. |
| **03** | [`advanced/03-resource-limits-and-cgroups`](advanced/03-resource-limits-and-cgroups/README.md) | İleri | CPU/RAM kısıtlamaları (`--memory`, `--cpus`), cgroups v2 ve bellek taşmasında **Exit Code 137 (OOMKilled)** analizi. |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-container-lifecycle
cat README.md
```
