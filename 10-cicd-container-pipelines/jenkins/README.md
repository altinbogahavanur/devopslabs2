# LAB-10-03 — Jenkins Declarative Pipeline ile Docker İmaj Üretimi ve Dağıtımı

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 40 dakika | `jenkins`, `declarative-pipeline`, `trivy`, `docker` | `8080` |

---

## Jenkins Pipeline Akışı

```text
+──────────────+     +──────────────+     +──────────────+     +──────────────+     +──────────────+
| 1. CHECKOUT  | ──> | 2. HADOLINT  | ──> | 3. BUILD     | ──> | 4. TRIVY     | ──> | 5. PUSH      |
|  (Git repo)  |     |  (Dockerfile)|     |  (Tag + SHA) |     |  (CVE Scan)  |     |  (Registry)  |
+──────────────+     +──────────────+     +──────────────+     +──────────────+     +──────────────+
                                                                                           │
                                                                                           ▼
                                                                                    +──────────────+
                                                                                    | POST: CLEANUP|
                                                                                    +──────────────+
```

---

## Adım Adım Uygulama

### Adım 1: Jenkins Kimlik Bilgisini Ekleme

1. Jenkins Web arayüzüne gidin (`http://<sunucu-ip>:8080`).
2. **Manage Jenkins ➔ Credentials ➔ System ➔ Global credentials ➔ Add Credentials** yolunu izleyin.
3. Tür olarak **Username with password** seçip ID alanına `docker-registry-credentials` verin.

---

### Adım 2: Declarative Jenkinsfile Dosyasını İnceleme

```bash
cat Jenkinsfile
```

*`post { always { ... } }` bloğunun build başarılı da olsa başarısız da olsa yerel imajları silerek disk dolmasını nasıl engellediğini gözlemleyin.*

---

### Adım 3: Pipeline Projesi Oluşturma ve Çalıştırma

1. Jenkins ana sayfasında **New Item ➔ Pipeline** seçeneğiyle proje oluşturun.
2. Definition olarak **Pipeline script from SCM** seçip Git repository adresinizi ve `Jenkinsfile` yolunu belirtin.
3. **Build Now** butonuna tıklayarak Console Output üzerinden aşamaları izleyin.

---

## Temizlik

Jenkins çalışma alanını (workspace) arayüzden **Wipe Out Current Workspace** seçeneğiyle temizleyebilirsiniz.
