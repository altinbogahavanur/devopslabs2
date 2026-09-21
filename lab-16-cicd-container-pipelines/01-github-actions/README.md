# LAB-16-01: GitHub Actions ile Docker İmaj Derleme, Güvenlik Taraması ve Push

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `github-actions`, `docker buildx`, `trivy`, `docker hub` | Yok |

---

## 1. Amaç

Bu laboratuvarda, eldeki bir Dockerfile'ın manuel olarak derlenip yüklenmesi yerine, koda her `git push` yapıldığında çalışan kurumsal bir **GitHub Actions CI/CD Pipeline**'ı yapılandırılır:

1. **Docker Buildx Kurulumu:** Çok platformlu ve önbellek (GitHub Actions Cache - `type=gha`) destekli derleyiciyi devreye alma.
2. **Semantik Etiketleme (`metadata-action`):** Git commit hash'i (`commit-abc1234`), branch adı (`latest`) ve git tag'lerine (`v1.0.0`) göre otomatik imaj etiketleri üretme.
3. **Güvenlik Kapısı (Trivy Scan):** İmaj registry'ye gönderilmeden önce içinde `CRITICAL` seviyede güvenlik açığı (CVE) olup olmadığını tarama.
4. **Registry'ye Gönderme:** Güvenlik testinden geçen imajı Docker Hub veya GHCR üzerine otomatik yükleme.

---

## 2. Ön Koşullar

* GitHub hesabı ve fork edilmiş repository.
* Docker Hub hesabı ve Personal Access Token (PAT).
* Dockerfile ve mikroservis kaynak kodları.

---

## 3. CI/CD Boru Hattı Mimarisi

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

## 4. Görevler (Tasks)

1. **GitHub Secrets Yapılandırması:** GitHub deponuzun **Settings ➔ Secrets and variables ➔ Actions** sekmesinde `DOCKERHUB_USERNAME` ve `DOCKERHUB_TOKEN` sırlarını tanımlayın.
2. **Workflow İncelemesi:** `.github/workflows/docker-build-push.yml` dosyasındaki aşamaları, tetikleyicileri (triggers) ve Buildx yapılandırmasını inceleyin.
3. **Önbellek Mekanizması:** `type=gha` önbellekleme direktifinin sonraki build sürelerini nasıl kısalttığını analiz edin.
4. **Güvenlik Kapısı (Trivy Gate):** Trivy adımında kritik güvenlik açıklarının registry push öncesinde nasıl engellendiğini inceleyin.
5. **Canlı Çalıştırma:** Repository'ye commit atarak veya bir tag (`v1.0.0`) pushlayarak Actions sekmesinde iş akışının yeşil yandığını teyit edin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: type=gha Cache Avantajı</summary>

GitHub Actions üzerinde standart `docker build` çalıştırıldığında her seferinde temiz sanal makine açıldığı için katman önbellekleri (layer cache) kaybolur. `type=gha` kullanıldığında katmanlar GitHub'ın hızlı cache depolama alanına yüklenir ve sonraki build'ler saniyeler içinde tamamlanır.
</details>

<details>
<summary>💡 İpucu 2: Docker Hub Personal Access Token (PAT)</summary>

GitHub Secrets içine doğrudan Docker Hub şifrenizi yazmak yerine Docker Hub hesabınızdan **Security ➔ Access Tokens** bölümüne gidip sadece `Read & Write` yetkisine sahip bir PAT üretip kullanmak kurumsal güvenlik standardıdır.
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Yapılandırma (Tıklayınca Açılır)</summary>

### Adım 1: GitHub Secrets Tanımlama
Deponuzun ayarlarına gidin ve aşağıdaki sırları tanımlayın:
* `DOCKERHUB_USERNAME`: Docker Hub kullanıcı adınız
* `DOCKERHUB_TOKEN`: Docker Hub Personal Access Token

### Adım 2: Workflow Dosyasını Konumlandırma
```bash
mkdir -p .github/workflows
cp .github/workflows/docker-build-push.yml .github/workflows/
```

### Adım 3: Kodu Commit ve Push Etme
```bash
git add .github/workflows/docker-build-push.yml
git commit -m "ci: add automated docker build, scan and push workflow"
git push origin main
```

### Adım 4: Sürüm Etiketi (Tag) ile Tetikleme
```bash
git tag v1.0.0
git push origin v1.0.0
```

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

1. GitHub tarayıcısında **Actions** sekmesine gidin.
2. `Docker Build, Scan and Push Pipeline` iş akışının yeşil tik (success) aldığını görün.
3. Docker Hub web arayüzünde imajınızın `latest`, `v1.0.0` ve `commit-<sha>` etiketleriyle yüklendiğini doğrulayın.

---

## 8. Temizlik

Test amaçlı oluşturulan imajları Docker Hub arayüzünden silebilir veya yerel Docker ortamınızdaki test imajını kaldırabilirsiniz:

```bash
docker rmi devopsatolyesi/microservice-api:test-scan 2>/dev/null || true
```
