# Kurumsal Konteyner Deposu: Harbor Registry, Trivy ve DevSecOps

Bu dizin, kurumsal Kubernetes ve CI/CD süreçlerinde standart olarak kullanılan **VMware Harbor Enterprise OCI Registry** mimarisini, Trivy güvenlik tarayıcısını ve **Tag Immutability (Değiştirilemez Etiket)** güvenlik pratiklerini içerir.

---

## 1. Neden Basit Registry Yerine Harbor?

| Özellik | Docker Hub | Standart `registry:2` | Harbor Enterprise |
|---|---|---|---|
| **Kullanıcı & RBAC Yönetimi** | Temel | Yok | Kapsamlı Rol Tabanlı Erişim (RBAC) + OIDC / LDAP |
| **Zafiyet Taraması (Vulnerability Scanning)** | Sınırlı | Yok | Dahili **Trivy** Taraması (OS & Kütüphane CVE tespiti) |
| **İmaj İmzalama (Content Trust)** | Yok | Yok | **Cosign / Notary** ile dijital imza doğrulama |
| **Değiştirilemez Etiket (Tag Immutability)** | Ücretli | Yok | Dahili kural motoru (`v*`, `release-*` üzerine yazmayı engelleme) |
| **Proje İzolasyonu & Kota** | Yok | Yok | Proje bazlı depolama kotası ve temizlik kuralları (Retention Policy) |
| **Robot Hesapları (Robot Accounts)** | Var (Access Tokens) | Yok | CI/CD (Jenkins, GitLab) için süreli ve kısıtlı robot token'ları |

---

## 2. Harbor Bileşenleri ve Ağ Mimarisi

```text
               İSTEMCİ / DOCKER CLI / WEB TARAYICI
                                │
                         Port: 443 (Nginx SSL) ──> Port: 18082 (Harbor Portal)
                                │
+───────────────────────────────▼───────────────────────────────+
| HARBOR OCI REGISTRY PLATFORMU (Docker Compose Kümesi)         |
|                                                               |
|  [ harbor-portal ]   ───> Angular Tabanlı Web Arayüzü         |
|  [ harbor-core ]     ───> Projeler, RBAC ve Token Servisi     |
|  [ registry ]        ───> Docker Distribution (Layer & Blob)  |
|  [ registryctl ]     ───> Katman Kontrolü & Garbage Collect   |
|  [ trivy-adapter ]   ───> Statik CVE Zafiyet Güvenlik Tarayıcı|
|  [ harbor-db ]       ───> PostgreSQL Veritabanı (Metadata)    |
|  [ redis ]           ───> Asenkron İş Kuyruğu ve Önbellek     |
|  [ harbor-jobservice ]──> İmaj Çoğaltma (Replication)         |
+───────────────────────────────────────────────────────────────+
```

---

## 3. Kurulum ve Kritik Ağ Yapılandırması

### A. Otomatik Kurulum (NovaShop Scripti ile)
```bash
cd ~/novashop
sudo bash infra/harbor/install_harbor.sh student01
```

### B. Kritik Ağ Notu: Token Realm ve `/etc/hosts` Çözümü
Harbor `harbor.yml` dosyasındaki `hostname` direktifine göre bir **Token Realm URL** üretir:
`Www-Authenticate: Bearer realm="http://student01-harbor.devopsatolyesi.com:18082/service/token"`

Eğer sunucunuz Cloudflare gibi bir CDN arkasındaysa, genel DNS bu adresi Cloudflare IP'sine çözer. Cloudflare `18082` portunu desteklemediğinden paketleri düşürür ve `Client.Timeout` hatası alırsınız.

**Çözüm:** Sunucu içi trafiğin dışarı çıkmaması için `/etc/hosts` dosyasına loopback yönlendirmesi eklenmelidir:
```bash
echo "127.0.0.1 student01-harbor.devopsatolyesi.com" | sudo tee -a /etc/hosts
```

---

## 4. Laboratuvar Uygulaması: İmaj Dağıtımı ve Güvenlik Testleri

### Adım 1: Harbor'a Docker CLI ile Giriş
```bash
docker login student01-harbor.devopsatolyesi.com:18082 -u admin -p Harbor12345
```
*Beklenen çıktı: `Login Succeeded`*

### Adım 2: Harbor Web UI'da Proje Açma
1. Tarayıcıdan `https://student01-harbor.devopsatolyesi.com` paneline girin (`admin` / `Harbor12345`).
2. **Projects** -> **+ New Project** tıklayın.
3. Proje Adı: `novashop`, Erişim: **Public** seçip kaydedin.

### Adım 3: İlk İmajı Push Etme
```bash
# İmajı etiketleyin ve Harbor'a gönderin:
docker tag go-microservice:v1.0 127.0.0.1:18082/novashop/go-api:v1.0.0
docker push 127.0.0.1:18082/novashop/go-api:v1.0.0
```

### Adım 4: Trivy ile Zafiyet Taraması
1. Harbor panelinde `novashop` -> `go-api` reposuna girin.
2. `v1.0.0` etiketinin yanındaki **Scan** butonuna tıklayın.
3. İmajımız `FROM scratch` ile oluşturulduğu için **0 Zafiyet (0 Vulnerabilities)** çıktısını doğrulayın.

---

## 🛡️ 5. Kritik DevSecOps Kuralı: Tag Immutability (Değiştirilemez Etiket)

Üretim ortamında çalışan bir versiyonun üzerine kazara yeni veya bozuk bir imaj basılmasını önler.

### 1. Kuralı Aktif Etme:
1. Harbor UI'da `novashop` projesine girin.
2. **Tag Immutability** sekmesi -> **+ Add Rule** tıklayın.
3. **Repositories:** `**` | **Tags:** `v*` yazıp kaydedin (`Immutability rules 1/15` görünmelidir).

### 2. Mühendislik Ayrımı: İdempotent Push vs Mutasyon (Üzerine Yazma)

> ⚠️ **Önemli Test Detayı:**  
> Eğer aynı `go-api` imajını hiçbir değişiklik yapmadan tekrar push ederseniz:  
> `docker push 127.0.0.1:18082/novashop/go-api:v1.0.0`  
> Sistem **hata vermez!** Çünkü SHA256 parmak izi (digest) aynıdır. OCI standartlarında parmak izi değişmeyen çağrılar etkisiz (idempotent) sayılır.

### 3. Gerçek İhlal Testi (Farklı Bir İmaj ile Üzerine Yazma Deneyi):
Geliştiricinin veya pipeline'ın canlıdaki `v1.0.0` etiketine yanlışlıkla bambaşka bir imajı (örneğin `alpine`) basmaya çalıştığı senaryoyu simüle edelim:

```bash
# 1. Farklı bir imaj çekip v1.0.0 olarak etiketleyin (Digest değişecek!):
docker pull alpine:latest
docker tag alpine:latest 127.0.0.1:18082/novashop/go-api:v1.0.0

# 2. Canlıdaki v1.0.0 etiketinin üzerine push etmeyi deneyin:
docker push 127.0.0.1:18082/novashop/go-api:v1.0.0
```

🛑 **Beklenen Harbor Güvenlik Engeli:**
```text
The push refers to repository [127.0.0.1:18082/novashop/go-api]
55afa1ecc21d: Pushed
error from registry: Failed to process request due to 'go-api:v1.0.0' configured as immutable.
```
Harbor imajın parmak izi değiştiği anda işlemi **anında reddeder!**

### 4. Doğru İş Akışı: Yeni Sürüm (`v1.0.1`) Çıkma
Kural mevcut sürümleri korurken yeni sürüm yayınlanmasını engellemez:
```bash
docker tag go-microservice:v1.0 127.0.0.1:18082/novashop/go-api:v1.0.1
docker push 127.0.0.1:18082/novashop/go-api:v1.0.1
```
*Sonuç: Başarıyla yüklenir ve `v1.0.1` de otomatik olarak kilitlenir.*

---

## 6. CI/CD İçin Robot Hesabı Entegrasyonu

Canlı boru hatlarında (Jenkins, GitLab CI, GitHub Actions) kişisel admin şifresi yerine kısıtlı robot hesapları kullanılır:

```bash
# Robot hesabı ile giriş yapma:
docker login student01-harbor.devopsatolyesi.com:18082 -u 'robot$novashop+novashop-deployer' -p '<GIZLI_ROBOT_TOKEN>'

# Pipeline üzerinden güvenli push:
docker push 127.0.0.1:18082/novashop/go-api:v1.0.2
```
