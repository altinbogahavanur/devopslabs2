# LAB-16: CI/CD Konteyner Pipeline'ları (GitHub Actions & GitLab CI)

## 🎯 Labın Amacı
Yazılım geliştirme yaşam döngüsünde Docker imajlarının derlenmesi (`build`), güvenlik taramasından geçirilmesi (`scan`) ve kayıt defterlerine (`registry`) yüklenmesi süreçlerini **GitHub Actions** ve **GitLab CI** otomasyon araçlarıyla üretime hazır hale getirmek.

## 📋 Ön Koşullar
- Git ve Docker Engine temel bilgisi.

---

## 🚀 Adım Adım İnceleme ve Uygulama

### 1. GitHub Actions Pipeline Mimarisi
`01-github-actions/` dizini altındaki workflow dosyasını inceleyin:

```bash
cd ~/docker-labs/lab-16-cicd-container-pipelines/01-github-actions
cat .github/workflows/docker-build-push.yml
```

**Temel Pipeline Aşamaları:**
1. **Docker Setup Buildx:** Gelişmiş BuildKit özelliklerini ve multi-arch desteğini açar.
2. **Docker Login:** GitHub Secrets üzerinden korunan `DOCKERHUB_USERNAME` ve `DOCKERHUB_TOKEN` ile güvenli giriş yapar.
3. **Build & Push:** `docker/build-push-action` kullanarak imajı derler ve GitHub cache (`type=gha`) sayesinde katmanları önbellekler.

---

### 2. GitLab CI (Docker-in-Docker - dind)
`02-gitlab-ci/` dizini altındaki konfigürasyonu inceleyin:

```bash
cd ~/docker-labs/lab-16-cicd-container-pipelines/02-gitlab-ci
cat .gitlab-ci.yml
```

**Temel GitLab Pipeline Bileşenleri:**
- `image: docker:27-cli`: Pipeline adımlarını yürüten Docker CLI konteyneri.
- `services: - docker:27-dind`: Konteyner içinde Docker Daemon çalıştıran Docker-in-Docker servisi.
- `CI_REGISTRY_IMAGE`: GitLab'ın yerleşik imaj deposuna otomatik etiketleme.

---

## ✅ Doğrulama (Verification)
- Pipeline YAML dosyalarının sözdizimi hatalarından arındırıldığını ve gizli anahtarların (Secrets) kod içine açık metin yazılmadığını doğrulayın.
