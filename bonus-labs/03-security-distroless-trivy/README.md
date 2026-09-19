# BONUS-DOC-03 — Konteyner Güvenliği, Google Distroless ve Trivy Zafiyet Analizi

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri - Uzman | `distroless`, `trivy`, `capabilities`, `read-only` | 8080 |

Konteyner ortamları varsayılan olarak root yetkileriyle çalışır ve ciddi güvenlik açıkları barındırabilir. Bu modülde, CIS Docker Benchmark ve NIST standartlarına uygun olarak Google Distroless imajları, non-root kullanıcı zorunluluğu, Trivy ile zafiyet taraması ve çalışma zamanı sertleştirme (runtime hardening) pratikleri ele alınır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-nonroot-and-distroless`](01-nonroot-and-distroless/README.md) | İleri | Google Distroless taban imajları, shell'siz (`sh`/`bash` yok) imaj üretimi ve non-root kullanıcı (`UID 65532`) ile çalışma. |
| **02** | [`02-vulnerability-scanning-trivy`](02-vulnerability-scanning-trivy/README.md) | İleri | Aqua Security Trivy ile CVE taraması, CRITICAL/HIGH filtreleme ve CI/CD derleme kırma (`--exit-code 1`) kapısı. |
| **03** | [`advanced/03-runtime-hardening-and-capabilities`](advanced/03-runtime-hardening-and-capabilities/README.md) | Uzman | Linux yeteneklerini sıfırlama (`--cap-drop=ALL`), salt-okunur dosya sistemi (`--read-only`) ve yetki yükseltme engeli (`no-new-privileges`). |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-nonroot-and-distroless
cat README.md
```
