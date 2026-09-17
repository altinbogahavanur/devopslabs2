# LAB-10-03 — Jenkins Declarative Pipeline ile Docker İmaj Üretimi ve Harbor/Registry Dağıtımı

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 40 dakika | `jenkins`, `declarative-pipeline`, `trivy`, `docker` | `8080` |

---

## 1. Amaç

Bu laboratuvarda, kurumsal CI/CD süreçlerinin en yaygın kullanılan platformu **Jenkins** üzerinde **Declarative `Jenkinsfile`** ile uçtan uca bir Docker konteyner boru hattı işletmek:

1. **Pipeline as Code:** Tüm derleme, test, güvenlik taraması ve dağıtım aşamalarını sürümlenebilir bir `Jenkinsfile` ile kod olarak tanımlamak.
2. **Hadolint ve Trivy Entegrasyonu:** Konteyner derleme sürecine otomatik güvenlik kapıları (Quality Gates) eklemek.
3. **Güvenli Kimlik Bilgisi (Credentials):** Registry şifrelerini Jenkins Credential Store'dan (`credentials('...')`) maskelenmiş olarak çekmek.
4. **Post-Build Temizlik:** Sunucunun diskini doldurmamak için derlenen yerel ara imajları `post { always { ... } }` bloğunda otomatik silmek.

---

## 2. Ön Koşullar

* Çalışan bir Jenkins sunucusu (Port 8080).
* Jenkins üzerinde `docker` ve `pipeline` eklentilerinin kurulu olması.
* Jenkins kullanıcısının Docker socket'ine erişim yetkisi (`usermod -aG docker jenkins`).

---

## 3. Jenkins Pipeline Akışı

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

## 4. Görevler (Tasks)

1. **Jenkins Kimlik Tanımlaması:** Jenkins web arayüzünde **Manage Jenkins ➔ Credentials** altında `docker-registry-credentials` ID'si ile Username & Password kimliği oluşturun.
2. **Jenkinsfile İncelemesi:** `Jenkinsfile` içerisindeki `environment`, `stages` ve `post` bloklarını inceleyin.
3. **Hadolint Lint Aşaması:** Dockerfile hatalarının derleme başlamadan önce nasıl engellendiğini gözlemleyin.
4. **Trivy Güvenlik Kapısı:** Güvenlik açığı tespit edildiğinde pipeline'ın nasıl davrandığını analiz edin.
5. **Otomatik Disk Temizliği:** `post { always { ... } }` bloğunun yerel imajları nasıl temizlediğini doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Jenkins Credentials Masking</summary>

Jenkins, `credentials()` fonksiyonuyla çekilen şifreleri konsol loglarında otomatik olarak `****` şeklinde maskeler. Bu sayede geliştiriciler veya denetçiler build loglarında gerçek şifreleri göremez.
</details>

<details>
<summary>💡 İpucu 2: post { always } Mantığı</summary>

CI/CD sunucularında en sık karşılaşılan problem `No space left on device` (Disk dolması) hatasıdır. Derleme başarılı da olsa başarısız da olsa ara imajları temizlemek için `post { always { sh "docker rmi ... || true" } }` kuralı zorunlu tutulmalıdır.
</details>

---

## 6. Adım Adım Çözüm Rehberi

<details>
<summary>🎯 Çözüm Adımları ve Referans Yapılandırma (Tıklayınca Açılır)</summary>

### Adım 1: Jenkins Kimlik Bilgisini Ekleme
1. Jenkins Web arayüzüne gidin (`http://<sunucu-ip>:8080`).
2. **Manage Jenkins ➔ Credentials ➔ System ➔ Global credentials ➔ Add Credentials** yolunu izleyin.
3. Tür olarak **Username with password** seçin:
   * **Username:** Registry kullanıcı adınız
   * **Password:** Registry şifreniz / token
   * **ID:** `docker-registry-credentials`

### Adım 2: Jenkins Pipeline Projesi Oluşturma
1. Jenkins ana sayfasında **New Item** butonuna tıklayın.
2. Bir isim verin (Örn: `docker-microservice-pipeline`) ve **Pipeline** tipini seçin.
3. Pipeline sekmesinde Definition olarak **Pipeline script from SCM** seçin.
4. SCM olarak **Git** seçip repository URL ve `Jenkinsfile` yolunu belirtin.

### Adım 3: Derlemeyi Başlatma (Build Now)
1. Sol menüden **Build Now** butonuna tıklayın.
2. Console Output ekranını açarak `Hadolint`, `Docker Build`, `Trivy` ve `Push` adımlarının çıktısını izleyin.

</details>

---

## 7. Doğal Doğrulama ve Beklenen Sonuç

1. Jenkins Pipeline aşama grafiğinde tüm blokların (Lint, Build, Scan, Push, Cleanup) yeşil renkte tamamlandığını teyit edin.
2. Konsol çıktısının sonunda şu mesajı arayın:
```text
✅ Pipeline basariyla tamamlandi!
Finished: SUCCESS
```
3. Hedef Registry üzerinde `BUILD_NUMBER` etiketiyle imajın yer aldığını doğrulayın.

---

## 8. Temizlik

Jenkins çalışma alanını (workspace) proje menüsünden **Wipe Out Current Workspace** ile temizleyebilir veya Jenkins sunucusundaki eski konteyner katmanlarını temizleyebilirsiniz:

```bash
docker system prune -f --filter "label!=keep"
```
