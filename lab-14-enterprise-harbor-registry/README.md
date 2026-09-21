# LAB-14: Kurumsal OCI Registry: Harbor Kurulumu, Public/Private Projeler ve Trivy Taraması

## 🎯 Labın Amacı
Kurumsal ortamlarda konteyner depolama standardı olan **Harbor Enterprise OCI Registry** mimarisini kavramak; **Port 18444** üzerinde Harbor'ı kurmak veya doğrulamak, Cloudflare 100 MB sınırını aşmak için **yerel port (127.0.0.1:18444)** stratejisini uygulamak, Harbor üzerinde hem **Public** hem de **Private** projeler açmak, CI/CD için **Robot Account** oluşturmak, imaj push/pull işlemlerini test etmek, **Tag Immutability (Değiştirilemez Etiket)** ile sürüm üzerine yazılmasını engellemek ve Harbor'ın yerleşik **Trivy** motoruyla zafiyet taraması yapmak.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- Host üzerinde **18444** portu kullanılabilir olmalıdır.

---

## 🏛️ Harbor Mimarisi ve Neden Standarttır?

| Özellik | Standart `registry:2` | Docker Hub | Harbor Enterprise |
|---|---|---|---|
| **Kullanıcı & RBAC Yönetimi** | Yok | Temel | Kapsamlı Rol Tabanlı Erişim (RBAC) + OIDC / LDAP |
| **Proje İzolasyonu & Kota** | Yok | Sadece Tekil Kullanıcı | Proje bazlı depolama kotası ve temizlik kuralları |
| **Zafiyet Taraması** | Yok | Ücretli | Dahili **Trivy** Motoru (Otomatik CVE Taraması) |
| **Değiştirilemez Etiket (Tag Immutability)** | Yok | Ücretli | `v*` etiketlerinin üzerine yazılmasını engelleme |
| **Robot Hesapları (Robot Accounts)** | Yok | Access Tokens | Süreli ve sadece belirli projelere yetkili CI/CD token'ları |

---

## ⚡ Kritik Bilgi: Cloudflare vs Yerel Port (18444) Stratejisi

> [!WARNING]
> **Neden Cloudflare Üzerinden Push Yapılmaz?**  
> Cloudflare ücretsiz/standart katmanında **maksimum HTTP gövde (body) boyutu 100 MB** ile sınırlıdır. Docker katmanları (`layer`) 150 MB veya 500 MB boyutlarına ulaştığında Cloudflare `413 Request Entity Too Large` hatası verir.  
> **Çözüm:**  
> - **Web Arayüzü:** Tarayıcıdan `http://<SUNUCU-IP>:18444` (veya ters proxy üzerinden) rahatça gezilebilir.  
> - **Docker Push / Pull:** Sunucu içindeki yerel port olan `127.0.0.1:18444` üzerinden yürütülür.

---

## 🚀 Adım Adım Uygulama

### Adım 1: Docker Daemon'ı Yerel HTTP Registry İçin Yapılandırın
Harbor yerel HTTP modunda çalışırken Docker Daemon'ın güvenli olmayan yerel registry'ye izin vermesi gerekir:

```bash
# /etc/docker/daemon.json dosyasını yapılandırın:
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["127.0.0.1:18444", "localhost:18444"]
}
EOF

# Değişikliğin geçerli olması için Docker'ı yeniden yükleyin:
sudo systemctl reload docker 2>/dev/null || true
```

---

### Adım 2: Harbor Servisini Başlatma / Kurma

#### Seçenek A: Platform Üzerinde Hazır Harbor Varsa
Eğitim ortamınızda Harbor servisi çalışıyorsa doğrudan durumunu denetleyin:
```bash
curl -I http://127.0.0.1:18444
# HTTP/1.1 200 OK veya yönlendirme dönmelidir.
```

#### Seçenek B: Sıfırdan Harbor Kurulumu (Kendi Sunucunuzda)
Dizindeki hazır kurulum betiğini çalıştırarak Harbor ve Trivy bileşenlerini tek adımda kurabilirsiniz:
```bash
cd lab-14-enterprise-harbor-registry
sudo bash ./install_harbor.sh
```

- **Web Arayüzü:** `http://<SUNUCU-IP>:18444`
- **Varsayılan Yönetici:** Kullanıcı: `admin` | Parola: `Harbor12345` (veya `admin`)

---

### Adım 3: Harbor Web Arayüzünde Public ve Private Proje Açın
1. Tarayıcınızdan `http://<SUNUCU-IP>:18444` adresine girin ve `admin` kullanıcısıyla oturum açın.
2. Sol menüden **Projects → + New Project** butonuna tıklayın:
   - **1. Proje (Public):**
     - Proje Adı: `devops-public`
     - Access Level: **Public** kutucuğunu İŞARETLEYİN ve kaydedin.
   - **2. Proje (Private):**
     - Proje Adı: `devops-private`
     - Access Level: **Public** kutucuğunu İŞARETLEMEYİN (Private kalsın) ve kaydedin.

---

### Adım 4: CI/CD Robot Hesabı (Robot Account) Oluşturun
Üretim ortamlarında kişisel admin şifresi yerine sadece push/pull yetkisi olan token tabanlı robot hesapları kullanılır:

1. Sol menüden **Robot Accounts → + New Robot Account** yolunu izleyin.
2. **Name:** `robot$ci-builder`
3. **Permissions:** `devops-private` ve `devops-public` projeleri için **Push Image** ve **Pull Image** kutularını işaretleyin.
4. **Save** diyerek üretilen **Token / Secret** değerini kopyalayın.

---

### Adım 5: CLI ile Robot Girişi Yapın (docker login)
```bash
ROBOT_USER="robot$ci-builder"
ROBOT_SECRET="<HARBOR_TARAFINDAN_VERILEN_TOKEN>"

# 127.0.0.1:18444 üzerinden robot hesabıyla giriş yapın:
echo "${ROBOT_SECRET}" | docker login 127.0.0.1:18444 -u "${ROBOT_USER}" --password-stdin
```
*Beklenen Çıktı: `Login Succeeded`*

*(Not: Dilerseniz doğrudan admin kullanıcısıyla da giriş yapabilirsiniz: `docker login 127.0.0.1:18444 -u admin -p Harbor12345`)*

---

### Adım 6: Public ve Private Projelere İmaj Yükleme (Push)
Harbor'da imaj adresi: `<REGISTRY_HOST>/<PROJE_ADI>/<IMAJ_ADI>:<ETIKET>` formatındadır:

```bash
# 1. Küçük bir temel imaj çekin:
docker pull alpine:3.20

# 2. Public proje için etiketleyin ve yükleyin:
docker tag alpine:3.20 127.0.0.1:18444/devops-public/demo-app:1.0.0
docker push 127.0.0.1:18444/devops-public/demo-app:1.0.0

# 3. Private proje için etiketleyin ve yükleyin:
docker tag alpine:3.20 127.0.0.1:18444/devops-private/demo-app:1.0.0
docker push 127.0.0.1:18444/devops-private/demo-app:1.0.0
```

---

### Adım 7: Oturumu Kapatıp Public vs Private İndirme Farkını Doğrulayın
```bash
# 1. Oturumu tamamen kapatın:
docker logout 127.0.0.1:18444

# 2. Yereldeki imajları silin:
docker rmi 127.0.0.1:18444/devops-public/demo-app:1.0.0
docker rmi 127.0.0.1:18444/devops-private/demo-app:1.0.0

# 3. Şifresiz / Anonim olarak PUBLIC projeden indirin:
docker pull 127.0.0.1:18444/devops-public/demo-app:1.0.0
# (SONUÇ: BAŞARILI! Public projeden herkes imaj çekebilir).

# 4. Şifresiz / Anonim olarak PRIVATE projeden indirmeyi deneyin:
docker pull 127.0.0.1:18444/devops-private/demo-app:1.0.0
```

🛑 **BEKLENEN GÜVENLİK ENGELİ:**
```text
Error response from daemon: pull access denied for 127.0.0.1:18444/devops-private/demo-app, repository does not exist or may require 'docker login': unauthorized: authentication required
```
Harbor, private projenin izinsiz indirilmesini anında engeller!

---

### Adım 8: Tag Immutability (Değiştirilemez Etiket) Kuralı Tanımlama
Canlıdaki `v*` veya `1.0.0` etiketinin üzerine yanlışlıkla başka bir imaj basılmasını önler:

1. Harbor arayüzünde **Projects → devops-public** içine girin.
2. **Tag Immutability** sekmesine gelin ve **+ Add Rule** butonuna tıklayın:
   - **Repositories:** `**` (Tüm repository'ler)
   - **Tags:** `*` (Tüm etiketler) veya `1.*`
   - **Save** butonuna tıklayın.

#### 🧪 Mutasyon Testi (Canlıdaki İmajın Üzerine Yazma Deneyi)
Tekrar login olun ve canlıdaki `demo-app:1.0.0` etiketine başka bir imajı (örneğin Nginx) basmayı deneyin:

```bash
# 1. Giriş yapın:
docker login 127.0.0.1:18444 -u admin -p Harbor12345

# 2. Tamamen farklı bir imaj çekip aynı etiketle etiketleyin:
docker pull nginx:alpine
docker tag nginx:alpine 127.0.0.1:18444/devops-public/demo-app:1.0.0

# 3. Mevcut etiketin üzerine push etmeyi deneyin:
docker push 127.0.0.1:18444/devops-public/demo-app:1.0.0
```

🛑 **BEKLENEN HARBOR GÜVENLİK ENGELİ:**
```text
error from registry: Failed to process request due to 'demo-app:1.0.0' configured as immutable.
```
Harbor imaj parmak izi (SHA256) değiştiği anda işlemi **anında bloke eder!**

---

### Adım 9: Harbor Entegre Trivy Güvenlik Taraması
1. **Manuel Tarama:**
   - Harbor Web UI'da **Projects → devops-public → Repositories → demo-app** içine girin.
   - `1.0.0` etiketinin sağındaki **Actions (...) → Scan** butonuna tıklayın.
2. **Otomatik Tarama (Scan on Push):**
   - **Configuration** sekmesinden **"Automatically scan images on push"** özelliğini aktif edin.
3. **Zafiyet Raporunu İnceleme:**
   - Birkaç saniye içinde beliren yeşil veya kırmızı güvenlik rozetine tıklayarak tespit edilen CVE zafiyetlerini ve giderilmiş sürümleri (Fixed in) inceleyin.
4. **Zafiyetli İmaj Engelleme Politikası:**
   - **Configuration** sekmesinden **"Prevent vulnerable images from running"** seçeneğini `High` yaparak güvenlik skoru düşük imajların çekilmesini engelleyin.

---

## ✅ Doğrulama (Verification)
- Harbor Web Arayüzünde `devops-public` ve `devops-private` projelerinin oluştuğunu gördünüz.
- Private projeye anonim erişimin `unauthorized` ile reddedildiğini teyit ettiniz.
- Tag Immutability kuralının sürüm üzerine yazmayı engellediğini bizzat test ettiniz.
- Harbor dahili Trivy motorunun imajı tarayıp CVE raporu ürettiğini gözlemlediniz.

---

## 🧹 Temizlik
```bash
docker logout 127.0.0.1:18444 2>/dev/null || true
docker rmi 127.0.0.1:18444/devops-public/demo-app:1.0.0 127.0.0.1:18444/devops-private/demo-app:1.0.0 2>/dev/null || true
```
