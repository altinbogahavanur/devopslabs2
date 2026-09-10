# LAB-10-01 — GitHub Actions ile Docker İmaj Derleme, Güvenlik Taraması ve Push

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 30 dakika | `github-actions`, `docker buildx`, `trivy`, `docker hub` | `-` |

---

## CI/CD Boru Hattı Mimarisi

```text
[ GIT PUSH (main / tag) ]
          │
          ▼
+─────────────────────────────────────────────────────────────+
| GITHUB ACTIONS RUNNER                                       |
|  1. Checkout Kaynak Kodlar                                  |
|  2. Setup Docker Buildx                                     |
|  3. Login Docker Hub (GitHub Secrets)                       |
|  4. Docker Build (GHA Cache ile 10 kat hızlı)               |
|  5. TRIVY ZAFİYET TARAMASI (CRITICAL & HIGH CVE)            |
|     - Açık varsa pipeline kırılır (Quality Gate) ❌         |
|  6. DOCKER PUSH ➔ Docker Hub / Harbor Registry ✅           |
+─────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama

### Adım 1: GitHub Secrets Tanımlama

GitHub deponuzun **Settings ➔ Secrets and variables ➔ Actions** sekmesine şu değişkenleri ekleyin:
* `DOCKERHUB_USERNAME`: Docker Hub kullanıcı adınız
* `DOCKERHUB_TOKEN`: Docker Hub Personal Access Token (PAT)

---

### Adım 2: Workflow Dosyasını Konumlandırma

`.github/workflows/docker-build-push.yml` dosyasını inceleyin:

```bash
cat .github/workflows/docker-build-push.yml
```

---

### Adım 3: Kodu Commit ve Push Etme

```bash
git add .github/workflows/docker-build-push.yml
git commit -m "ci: add docker build and push workflow"
git push origin main
```

---

### Adım 4: Sürüm Etiketi (Tag) ile Tetikleme

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub web arayüzünde **Actions** sekmesine giderek derleme ve Trivy güvenlik tarama adımlarını izleyin.

---

## Temizlik

Test amaçlı yüklenen etiketleri Docker Hub arayüzünden silebilirsiniz.
