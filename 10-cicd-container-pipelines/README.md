# LAB-DOC-10 — CI/CD ile Konteyner Otomasyonu (Container Pipelines)

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `github-actions`, `gitlab-ci`, `jenkins`, `trivy` | - |

Modern DevOps süreçlerinde Dockerfile dosyaları manuel olarak derlenip yüklenmez. Her `git push` yapıldığında otomatik imaj üreten, güvenlik açıklarını (Trivy) tarayan ve Docker Hub / Harbor Registry'ye yükleyen tam otomatik CI/CD boru hatları kullanılır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-github-actions`](01-github-actions/README.md) | İleri | GitHub Actions: `setup-buildx`, GHA Cache (`type=gha`), Semantik etiketleme, Trivy CVE kapısı ve Docker Hub push. |
| **02** | [`02-gitlab-ci`](02-gitlab-ci/README.md) | İleri | GitLab CI: Docker-in-Docker (`docker:dind`), Hadolint linter, Kaniko, GitLab Container Registry & Harbor. |
| **03** | [`advanced/03-jenkins`](advanced/03-jenkins/README.md) | İleri | Jenkins Declarative Pipeline: Credential Store, Trivy güvenlik kapısı, kurumsal Harbor push ve `post { always { cleanup } }`. |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-github-actions
cat README.md
```
