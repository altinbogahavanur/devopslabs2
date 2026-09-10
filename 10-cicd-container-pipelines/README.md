# MODÜL 08 — CI/CD ile Konteyner Otomasyonu (Container CI/CD Pipelines)

Bu modülde, bir `Dockerfile` dosyasını manuel olarak derleyip göndermek yerine, modern kurumsal CI/CD motorları (GitHub Actions, GitLab CI ve Jenkins) ile her `git push` yapıldığında otomatik imaj üreten, güvenlik kapılarından (Trivy zafiyet taraması) geçiren ve Docker Hub / Harbor Registry'ye yükleyen tam otomatik boru hatları incelenmektedir.

---

## 📂 Laboratuvar Listesi

| No | Klasör | CI/CD Aracı | Öne Çıkan Yetkinlikler |
|:---:|:---|:---|:---|
| **01** | [`github-actions`](github-actions/README.md) | **GitHub Actions** | `setup-buildx`, GHA Cache (`type=gha`), Semantik etiketleme, Trivy CVE kapısı, Docker Hub push |
| **02** | [`gitlab-ci`](gitlab-ci/README.md) | **GitLab CI** | Docker-in-Docker (`docker:dind`), Hadolint linter, Kaniko, GitLab Container Registry & Harbor |
| **03** | [`jenkins`](jenkins/README.md) | **Jenkins Declarative** | Declarative `Jenkinsfile`, Credential Store entegrasyonu, Trivy denetimi, `post { always { cleanup } }` |
