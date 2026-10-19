# LAB-13: Kurumsal OCI Registry: Harbor Kurulumu, Public/Private Projeler ve Trivy Taraması

## 🎯 Labın Amacı
Kurumsal ortamlarda konteyner depolama standardı olan **Harbor Enterprise OCI Registry** mimarisini kavramak; **Port 18444** üzerinde Harbor'ı kurmak veya doğrulamak, Cloudflare 100 MB sınırını aşmak için **yerel port (127.0.0.1:18444)** stratejisini uygulamak, Harbor üzerinde hem **Public** hem de **Private** projeler açmak, CI/CD için **Robot Account** oluşturmak, imaj push/pull işlemlerini test etmek, **Tag Immutability (Değiştirilemez Etiket)** ile sürüm üzerine yazılmasını engellemek ve Harbor'ın yerleşik **Trivy** motorunu aktif kurup zafiyet taraması yapmak.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- Host üzerinde **18444** portu kullanılabilir olmalıdır.
- Nginx Master Reverse Proxy **Port 443** üzerinde Harbor'a yönlendirme yapmalıdır.

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

## ⚡ Kritik Mimari: İkili Erişim (Dual Access) Stratejisi

> [!WARNING]
> **Neden Web için Domain, CLI Push için Lokal Port (18444)?**  
> Cloudflare ücretsiz/standart proxy katmanında **maksimum HTTP request body boyutu 100 MB** ile sınırlıdır. Docker katmanları (`layer`) 150 MB veya 500 MB boyutlarına ulaştığında Cloudflare `413 Request Entity Too Large` hatası verir.  
> **Kurumsal Çözüm:**  
> - 🌐 **Web Arayüzü Erişimi (Tarayıcı):** `http://harbor.devopsatolyesi.com:18444` (veya `http://127.0.0.1:18444` ya da sunucu domaini `https://<SUNUCU-DOMAIN>/`). Cloudflare Wildcard SSL sertifikası ve Nginx ters proxy arkasından güvenle kullanılır.  
> - 🐳 **Docker CLI Push / Pull Erişimi (Terminal):** Sunucu içindeki yerel port olan `127.0.0.1:18444` üzerinden yürütülür. Böylece hiçbir proxy/boyut kısıtına takılmadan devasa imajlar dahi doğrudan depoya aktarılır.

---

## 🚀 Adım Adım Uygulama

### Adım 1: Çalışma Dizinine Geçiş ve DNS / Docker Daemon Ayarları

> [!IMPORTANT]
> **Harbor Hostname Kuralı:**  
> Harbor'ın `prepare` doğrulama motoru `hostname` alanında `127.0.0.1` veya `localhost` kullanımına izin vermez (`ERROR:root:127.0.0.1 can not be the hostname`). Bu nedenle kurumsal FQDN (`harbor.devopsatolyesi.com`) tanımlanır ve yerel çözümleme için `/etc/hosts` içine eklenir.

```bash
# 1. Lab çalışma dizinine geçin:
cd ~/docker-labs/lab-13-enterprise-harbor-registry

# 2. Yerel alan adını /etc/hosts dosyasına ekleyin (eğer yoksa):
if ! grep -q "harbor.devopsatolyesi.com" /etc/hosts; then
  echo "127.0.0.1 harbor.devopsatolyesi.com" | sudo tee -a /etc/hosts
fi

# 3. /etc/docker/daemon.json dosyasında insecure registries tanımlayın:
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["harbor.devopsatolyesi.com:18444", "127.0.0.1:18444", "localhost:18444"]
}
EOF

# 4. Değişikliğin geçerli olması için Docker daemon'ı yeniden yükleyin:
sudo systemctl reload docker 2>/dev/null || true
```

---

### Adım 2: Harbor ve Dahili Trivy Servisini Kurma / Başlatma

#### Seçenek A: Platform Üzerinde Hazır Harbor Varsa
Eğitim ortamınızda Harbor servisi çalışıyorsa durumunu denetleyin:
```bash
curl -s http://127.0.0.1:18444/api/v2.0/systeminfo
# Yanıt olarak auth_mode vb. içeren JSON nesnesi dönmelidir.
```

#### Seçenek B: Sıfırdan Harbor ve Trivy Kurulumu (Tavsiye Edilen)
Platform altyapı dokümanına (`devops-platform-infrastructure/docs/09-container-registry-harbor.md`) birebir uyumlu otomatik kurulum betiğini çalıştırın:

```bash
cd ~/docker-labs/lab-13-enterprise-harbor-registry
sudo bash ./install_harbor.sh
```

**Betiğin Gerçekleştirdiği İşlemler:**
1. `/opt/devops-platform/harbor` dizinini oluşturur ve resmi online installer paketini indirip açar.
2. `harbor.yml` dosyasını yapılandırır (`hostname: harbor.devopsatolyesi.com`, `port: 18444`, `data_volume: /opt/devops-platform/harbor/data`).
3. SSL sonlandırmayı Nginx Master Proxy'ye devretmek için `https:` bloğunu devre dışı bırakır.
4. `./prepare --with-trivy` ve `./install.sh --with-trivy` komutlarıyla Harbor bileşenlerini ve **Trivy Adapter** servisini ayağa kaldırır.

Kurulum tamamlandıktan sonra konteynerlerin durumunu kontrol edin:
```bash
docker ps --filter "name=harbor" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
*Trivy servisinin (`trivy-adapter`) listede çalıştığını teyit edin.*

#### Seçenek C: Düşük Kaynaklı Ortamlar İçin Hafif OCI Registry (docker-compose.yml)
Eğer sisteminizde Harbor ve Trivy çalıştırmak için yeterli RAM/kaynak yoksa (Harbor en az 4-8 GB RAM gerektirir), bu dizindeki hafif `docker-compose.yml` dosyasını kullanarak ~50 MB RAM tüketen resmi bir Docker Registry ve Web Arayüzü başlatabilirsiniz:

```bash
cd ~/docker-labs/lab-13-enterprise-harbor-registry
docker compose up -d
```
- **Web UI:** `http://localhost:8085`
- **Registry Port:** `5000` (`localhost:5000` veya `127.0.0.1:5000`)
*(Not: Bu hafif alternatif modda push/pull komutlarında port olarak `18444` yerine `5000` kullanılır).*

---

### Adım 3: Harbor Web Arayüzüne Giriş ve Projeleri Açma

1. Tarayıcınızdan **`http://harbor.devopsatolyesi.com:18444`** (veya yerel test için `http://127.0.0.1:18444`) adresine gidin.
2. Giriş yapın:
   - **Kullanıcı:** `admin`
   - **Parola:** `Harbor12345`
3. Sol menüden **Projects → + New Project** butonuna tıklayın:
   - **1. Proje (Public):**
     - Proje Adı: `devops-public`
     - Access Level: **Public** kutucuğunu İŞARETLEYİN ve **OK** butonuna basın.
   - **2. Proje (Private):**
     - Proje Adı: `devops-private`
     - Access Level: **Public** kutucuğunu İŞARETLEMEYİN (Private kalsın) ve **OK** butonuna basın.

---

### Adım 4: CI/CD Robot Hesabı (Robot Account) Oluşturun
Üretim ortamlarında kişisel admin şifresi yerine sadece push/pull yetkisi olan token tabanlı robot hesapları kullanılır:

1. Sol menüden **Robot Accounts → + New Robot Account** yolunu izleyin.
2. **Name:** `robot$ci-builder`
3. **Permissions:** `devops-private` ve `devops-public` projeleri için **Push Image** ve **Pull Image** kutularını işaretleyin.
4. **Save** diyerek üretilen **Token / Secret** değerini kopyalayın.

---

### Adım 5: CLI ile Oturum Açma (docker login)
İmaj gönderme ve çekme işlemlerinde Cloudflare body limitine takılmamak için **`127.0.0.1:18444`** adresini kullanın:

```bash
# Robot token ile giriş (Önerilen CI/CD yöntemi):
# ⚠️ DİKKAT: Shell'in (Bash/Zsh) '$' işaretini değişken sanıp yutmaması için TEK TIRNAK ('...') kullanın:
ROBOT_USER='robot$ci-builder'
ROBOT_SECRET='<HARBOR_TARAFINDAN_VERILEN_TOKEN>'
echo "${ROBOT_SECRET}" | docker login 127.0.0.1:18444 -u "${ROBOT_USER}" --password-stdin

# Veya doğrudan admin hesabı ile giriş:
docker login 127.0.0.1:18444 -u admin -p Harbor12345
```
*Beklenen Çıktı: `Login Succeeded`*

---

### Adım 6: Public ve Private Projelere İmaj Yükleme (Push)
Harbor'da imaj formatı: `127.0.0.1:18444/<PROJE_ADI>/<IMAJ_ADI>:<ETIKET>` şeklindedir:

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
# (SONUÇ: BAŞARILI! Public projeden kimlik doğrulaması olmadan herkes imaj çekebilir).

# 4. Şifresiz / Anonim olarak PRIVATE projeden indirmeyi deneyin:
docker pull 127.0.0.1:18444/devops-private/demo-app:1.0.0
```

🛑 **BEKLENEN GÜVENLİK ENGELİ:**
```text
Error response from daemon: pull access denied for 127.0.0.1:18444/devops-private/demo-app, repository does not exist or may require 'docker login': unauthorized: authentication required
```
Harbor, private projeden anonim imaj çekilmesini anında engeller.

---

### Adım 8: Tag Immutability (Değiştirilemez Etiket) Kuralı Tanımlama
Canlıdaki bir release etiketinin (`1.0.0` veya `v*`) üzerine yanlışlıkla başka bir derlemenin basılmasını önler:

1. Harbor arayüzünde **Projects → devops-public** içine girin.
2. **Tag Immutability** sekmesine gelin ve **+ Add Rule** butonuna tıklayın:
   - **Repositories:** `**` (Tüm repository'ler)
   - **Tags:** `*` (Tüm etiketler) veya `1.*`
   - **Save** butonuna tıklayın.

#### 🧪 Mutasyon Testi (Canlıdaki İmajın Üzerine Yazma Deneyi)
Tekrar giriş yapın ve canlıdaki `demo-app:1.0.0` etiketine farklı bir imajı (örneğin Nginx) basmayı deneyin:

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
Harbor imaj SHA256 parmak izi değiştiği anda işlemi bloke eder ve sürüm bütünlüğünü korur.

---

### Adım 9: Harbor Entegre Trivy Güvenlik Taraması & Security Gate Deneyi

1. **Trivy Sağlık Durumunu Kontrol Etme:**
   - Harbor Web UI'da sol menüden **Administration → Interrogation Services** sekmesine gidin.
   - **Vulnerability** başlığı altında tarayıcının **Trivy** olduğunu ve durumunun **Healthy** olduğunu doğrulayın.

2. **Otomatik Tarama ve Güvenlik Kapısını (Security Gate) Açma:**
   - **Projects → devops-private → Configuration** sekmesine gidin.
   - **"Automatically scan images on push"** kutusunu işaretleyin (Push anında otomatik tarama).
   - **"Prevent vulnerable images from running"** kutusunu işaretleyin ve eşik değerini **`High`** (veya `Critical`) olarak belirleyip **Save** butonuna tıklayın.

3. **Kasıtlı Zafiyetli İmajı Derleme ve Harbor'a Yükleme:**
   Lab dizinindeki `vulnerable-app` uygulamasını (eski Python tabanı ve bilinen kritik CVE zafiyetleri içeren `urllib3`, `requests`, `werkzeug` paketleri) derleyip private depoya gönderin:

   ```bash
   # 1. Zafiyetli uygulama dizinine geçin:
   cd ~/docker-labs/lab-13-enterprise-harbor-registry/vulnerable-app

   # 2. İmajı derleyin:
   docker build -t 127.0.0.1:18444/devops-private/vulnerable-app:1.0.0 .

   # 3. Harbor'a push edin:
   docker push 127.0.0.1:18444/devops-private/vulnerable-app:1.0.0
   ```

4. **Trivy Raporunu İnceleme:**
   - Harbor arayüzünde **Projects → devops-private → Repositories → vulnerable-app** sayfasına gidin.
   - `1.0.0` etiketinin karşısında Trivy'nin otomatik tarama başlattığını ve birkaç saniye içinde **CRITICAL** ve **HIGH** zafiyet rozetlerinin belirdiğini görün.
   - Rozete tıklayarak CVE kodlarını (`CVE-2019-11324`, `CVE-2018-18074` vb.) ve hangi paketlerde zafiyet olduğunu inceleyin.

5. **🛑 Güvenlik Kapısının (Security Gate) Çalıştığını Kanıtlama:**
   Harbor, bünyesinde kritik zafiyet barındıran bu imajın canlı ortamlara veya Kubernetes kümelerine çekilmesini (`docker pull`) **otomatik olarak engeller**:

   ```bash
   # 1. Yereldeki imajı silin:
   docker rmi 127.0.0.1:18444/devops-private/vulnerable-app:1.0.0 2>/dev/null || true

   # 2. Harbor'dan tekrar çekmeyi (pull) deneyin:
   docker pull 127.0.0.1:18444/devops-private/vulnerable-app:1.0.0
   ```

   **🛑 Beklenen Harbor Güvenlik Engeli:**
   ```text
   Error response from daemon: pull access denied for 127.0.0.1:18444/devops-private/vulnerable-app, repository does not exist or may require 'docker login': unknown: current image with 'CRITICAL' vulnerability cannot be pulled
   ```
   *Tebrikler! Harbor'ın sadece pasif bir depo olmadığını, zafiyetli kodun prodüksiyona girmesini engelleyen bir **DevSecOps Güvenlik Kapısı (Quality Gate)** olduğunu kanıtladınız.*

---

## ✅ Doğrulama (Verification)
- `curl -s http://127.0.0.1:18444/api/v2.0/systeminfo` komutunun sağlıklı yanıt verdiğini gördünüz.
- Tarayıcı üzerinden `http://harbor.devopsatolyesi.com:18444` (veya `http://127.0.0.1:18444`) adresinden Harbor portalına ulaştınız.
- `127.0.0.1:18444` üzerinden imaj push ve pull işlemlerini başarıyla tamamladınız.
- Private projeye şifresiz erişimin engellendiğini ve Tag Immutability kuralının çalıştığını test ettiniz.
- Trivy motorunun aktif olarak CVE zafiyet taraması yaptığını ve güvenlik kapısının (Security Gate) zafiyetli imajı başarıyla engellediğini doğruladınız.

---

## 🧹 Temizlik
```bash
docker logout 127.0.0.1:18444 2>/dev/null || true
docker rmi 127.0.0.1:18444/devops-public/demo-app:1.0.0 127.0.0.1:18444/devops-private/demo-app:1.0.0 127.0.0.1:18444/devops-private/vulnerable-app:1.0.0 2>/dev/null || true
```
