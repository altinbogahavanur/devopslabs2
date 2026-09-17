# LAB-10-02 — GitLab CI ile Docker-in-Docker (dind) ve Harbor/Registry Entegrasyonu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 35 dakika | `gitlab-ci`, `docker:dind`, `trivy`, `harbor` | `-` |

---

## 1. Amaç

Bu laboratuvarda, kurumsal ortamlarda en sık kullanılan CI/CD motorlarından biri olan **GitLab CI** üzerinde Docker imajı derleme (Docker-in-Docker - DinD), güvenlik açığı taraması ve Registry'ye pushlama iş akışı kurulur:

1. **Hadolint Lint Aşaması:** Dockerfile'ın yazım ve güvenlik standartlarına uygunluğunun statik analizi.
2. **Docker-in-Docker (dind) Mimarisi:** Bir Docker konteyneri içinde başka bir Docker daemon çalıştırarak `docker build` komutunun işletilmesi.
3. **Katmanlı Artifact Taşıma:** Derlenen imajın `docker save` ile `image.tar` haline getirilerek Trivy güvenlik tarayıcısına aktarılması.
4. **GitLab Registry & Harbor Push:** İmajın hem commit SHA (`commit-a1b2c3d`) hem de `latest` etiketiyle depoya yüklenmesi.

---

## 2. Ön Koşullar

* GitLab hesabı veya self-hosted GitLab CE sunucusu.
* Etkin bir GitLab Runner (Docker executor yetkili).
* Projeye ait `Dockerfile`.

---

## 3. GitLab CI Pipeline Aşamaları

```text
+─────────────+     +──────────────+     +──────────────────+     +────────────────+
| 1. LINT     | ──> | 2. BUILD     | ──> | 3. SECURITY-SCAN | ──> | 4. PUSH        |
|  (Hadolint) |     |  (docker:dind|     |  (Trivy CVE Scan)|     |  (GitLab/Harbor|
|             |     |   image.tar) |     |   image.tar)     |     |   Registry)    |
+─────────────+     +──────────────+     +──────────────────+     +────────────────+
```

---

## 4. Görevler (Tasks)

1. **Pipeline Mimarisi İncelemesi:** `.gitlab-ci.yml` dosyasındaki stage tanımlarını (`lint`, `build`, `security-scan`, `push`) ve `docker:24.0-dind` servis bağlantısını inceleyin.
2. **Değişkenler ve TLS:** `DOCKER_TLS_CERTDIR: ""` ayarının yerel runner ortamlarında bağlantıyı nasıl kolaylaştırdığını analiz edin.
3. **Artifact Paylaşımı:** Derleme aşamasında oluşturulan `image.tar` arşivinin `artifacts: paths:` ile Trivy aşamasına nasıl taşındığını görün.
4. **Kalite Kapısı:** Trivy taramasında `HIGH,CRITICAL` zafiyetlerin tespit edilip raporlandığını denetleyin.
5. **Registry Pushlama:** İmajın `$CI_REGISTRY` üzerine `$CI_COMMIT_SHORT_SHA` ve `latest` etiketleriyle gönderilmesini sağlayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Docker-in-Docker (dind) vs Docker Socket Mount</summary>

GitLab Runner'da iki yaklaşım vardır:
* `dind`: Tamamen izole ayrı bir daemon ayağa kalkar, host daemon'ı kirletmez ve güvenlidir. Ancak ek kaynak tüketir.
* `/var/run/docker.sock` bağlama: Host daemon'ını doğrudan kullanır, hızlıdır ancak host üzerinde yetki yükseltme riski taşır.
</details>

<details>
<summary>💡 İpucu 2: CI_REGISTRY_USER ve CI_JOB_TOKEN</summary>

GitLab CI içinde harici şifre girmeden dahili container registry'ye oturum açmak için yerleşik `$CI_REGISTRY_USER` (`gitlab-ci-token`) ve `$CI_JOB_TOKEN` değişkenleri otomatik olarak kullanılır.
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Yapılandırma (Tıklayınca Açılır)</summary>

### Adım 1: `.gitlab-ci.yml` Dosyasını Projeye Dahil Etme
```bash
cp .gitlab-ci.yml ~/my-project/
cd ~/my-project/
```

### Adım 2: GitLab Runner Ayarını Doğrulama
Runner yapılandırma dosyasında (`/etc/gitlab-runner/config.toml`) Docker executor için `privileged = true` tanımlı olmalıdır:
```toml
[[runners]]
  executor = "docker"
  [runners.docker]
    privileged = true
```

### Adım 3: Kodu Commit ve Push Etme
```bash
git add .gitlab-ci.yml
git commit -m "ci: add gitlab-ci dind build and push pipeline"
git push origin main
```

### Adım 4: Pipeline Durumunu İzleme
GitLab Web arayüzünde **Build ➔ Pipelines** sekmesine giderek 4 aşamanın sırasıyla başarıyla tamamlandığını izleyin.

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

1. GitLab Web UI'da **Deploy ➔ Container Registry** sekmesini açın.
2. İmajın altında commit SHA ve `latest` etiketlerinin başarıyla listelendiğini doğrulayın.
3. Yerel makinenizden imajı çekmeyi test edin:
```bash
docker pull registry.gitlab.com/<username>/<repo>:latest
```

---

## 8. Temizlik

GitLab Container Registry arayüzünden test amaçlı üretilmiş commit SHA etiketlerini temizleyin veya test projesini arşivleyin.
