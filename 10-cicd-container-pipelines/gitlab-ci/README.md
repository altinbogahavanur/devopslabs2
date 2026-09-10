# LAB-10-02 — GitLab CI ile Docker-in-Docker (dind) ve Registry Entegrasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 35 dakika | `gitlab-ci`, `docker:dind`, `trivy` | `-` |

---

## GitLab CI Pipeline Aşamaları

```text
+─────────────+     +──────────────+     +──────────────────+     +────────────────+
| 1. LINT     | ──> | 2. BUILD     | ──> | 3. SECURITY-SCAN | ──> | 4. PUSH        |
|  (Hadolint) |     |  (docker:dind|     |  (Trivy CVE Scan)|     |  (GitLab       |
|             |     |   image.tar) |     |   image.tar)     |     |   Registry)    |
+─────────────+     +──────────────+     +──────────────────+     +────────────────+
```

---

## Adım Adım Uygulama

### Adım 1: Pipeline Yapılandırmasını İnceleme

`.gitlab-ci.yml` dosyasındaki Hadolint, Docker-in-Docker derleme, Trivy zafiyet denetimi ve Push adımlarını inceleyin:

```bash
cat .gitlab-ci.yml
```

---

### Adım 2: GitLab Runner Yapılandırmasını Doğrulama

Docker executor çalıştıran runner üzerinde `/etc/gitlab-runner/config.toml` dosyasında `privileged = true` ayarının tanımlı olduğunu teyit edin:

```toml
[[runners]]
  executor = "docker"
  [runners.docker]
    privileged = true
```

---

### Adım 3: Kodu Gönderme ve Pipeline'ı Başlatma

```bash
git add .gitlab-ci.yml
git commit -m "ci: add gitlab-ci dind pipeline"
git push origin main
```

---

### Adım 4: Canlı Dağıtımı İzleme

GitLab web arayüzünde **Build ➔ Pipelines** sekmesine giderek 4 aşamanın sırasıyla tamamlandığını ve **Deploy ➔ Container Registry** altında imajın commit SHA etiketiyle yer aldığını doğrulayın.

---

## Temizlik

Test amaçlı üretilen imaj etiketlerini Container Registry arayüzünden silebilirsiniz.
