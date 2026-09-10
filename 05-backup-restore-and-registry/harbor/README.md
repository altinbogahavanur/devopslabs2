# Kurumsal Konteyner Deposu: Harbor Registry

Bu dizin, kurumsal Kubernetes ve CI/CD süreçlerinde standart olarak kullanılan **VMware Harbor Enterprise Registry** mimarisini ve Docker Compose ile kurulum adımlarını içerir.

---

## 1. Neden Basit Registry Yerine Harbor?

| Özellik | Docker Hub | Standart `registry:2` | Harbor Enterprise |
|---|---|---|---|
| **Kullanıcı & RBAC Yönetimi** | Temel | Yok | Kapsamlı Rol Tabanlı Erişim (RBAC) + OIDC / LDAP |
| **Zafiyet Taraması (Vulnerability Scanning)** | Sınırlı | Yok | Dahili **Trivy** Taraması (CVE tespiti) |
| **İmaj İmzalama (Content Trust)** | Yok | Yok | **Cosign / Notary** ile dijital imza doğrulama |
| **Kota ve Proje İzolasyonu** | Yok | Yok | Proje bazlı disk kotası ve temizlik kuralları (Retention Policy) |
| **Robot Hesapları (Robot Accounts)** | Var (Access Tokens) | Yok | CI/CD (Jenkins, GitLab) için süreli ve kısıtlı robot token'ları |

---

## 2. Hızlı Kurulum Adımları (Ubuntu / Docker Compose)

```bash
# 1. Harbor offline/online paketini indirme
export HARBOR_VER="v2.11.0"
curl -sSL https://github.com/goharbor/harbor/releases/download/${HARBOR_VER}/harbor-online-installer-${HARBOR_VER}.tgz | tar -xz

# 2. Örnek konfigürasyon dosyasını düzenleme
cd harbor
cp harbor.yml.tmpl harbor.yml

# 3. harbor.yml içindeki hostname ve şifreyi belirleme (Örn: hostname: 192.168.1.50)
sed -i 's/reg.mydomain.com/localhost/g' harbor.yml
# Not: Eğer SSL/TLS yoksa 'https:' bloğu geçici olarak devre dışı bırakılır veya self-signed cert üretilir.

# 4. Harbor bileşenlerini kurma ve başlatma
./prepare
./install.sh --with-trivy
```

---

## 3. Robot Hesapları ile CI/CD Entegrasyonu

Jenkins veya GitLab CI süreçlerinde şahsi kullanıcı şifresi yerine sadece **Push/Pull** yetkisi olan bir Robot Hesabı oluşturulur:

```bash
# Robot hesabı ile giriş yapma:
docker login localhost -u 'robot$gitlab-ci' -p 'supersecretrobottokan'

# İmajı etiketleyip Harbor projesine gönderme:
docker tag my-service:v1.0 localhost/production/my-service:v1.0
docker push localhost/production/my-service:v1.0
```
