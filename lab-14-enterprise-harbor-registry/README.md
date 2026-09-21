# LAB-14: Kurumsal OCI Registry: Harbor (Port 18444) ve Entegre Trivy Taraması

## 🎯 Labın Amacı
Kurumsal seviyede bir Docker imaj deposu olan **Harbor OCI Registry** mimarisini kavramak; **Port 18444** üzerinde Harbor'ı çalıştırmak, **Cloudflare 100 MB yükleme sınırını aşmak için yerel port (127.0.0.1:18444) stratejisini** uygulamak, Proje, Kullanıcı ve **Robot Account** oluşturarak imaj push/pull işlemlerini otomatize etmek ve Harbor'ın yerleşik **Trivy** motoruyla zafiyet taraması yapmak.

## 📋 Ön Koşullar & Portlar
- Docker Engine ve Docker Compose v2 kurulu olmalıdır.
- Host üzerinde **18444** portu açık veya kullanılabilir olmalıdır.

---

## ⚡ Kritik Bilgi: Cloudflare vs Yerel Port (18444) Stratejisi

> [!WARNING]
> **Neden Cloudflare Üzerinden Push Yapılmaz?**
> Cloudflare ücretsiz/standart katmanında **maksimum HTTP body boyutu 100 MB** ile sınırlıdır. Docker katmanları (`layer`) 150 MB veya 500 MB boyutlarına ulaştığında Cloudflare `413 Request Entity Too Large` hatası verir veya bağlantıyı zaman aşımına (timeout) uğratır.
> 
> **Çözüm:** 
> - **Web Arayüzü:** Tarayıcıdan alan adı veya `http://<SUNUCU-IP>:18444` üzerinden rahatça gezilebilir.
> - **Docker Push / Pull:** Cloudflare'e hiç takılmamak için doğrudan sunucu içindeki yerel port olan `127.0.0.1:18444` üzerinden yürütülür.

---

## 🚀 Adım Adım Uygulama

### 1. Docker Daemon'ı Yerel HTTP Registry İçin Yapılandırma
Harbor yerel HTTP modunda (18444) çalışırken Docker Daemon'ın güvenli olmayan yerel registry'ye izin vermesi gerekir:

```bash
# /etc/docker/daemon.json dosyasını düzenleyin (veya oluşturun):
sudo tee /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["127.0.0.1:18444", "localhost:18444"]
}
EOF

# Değişikliğin geçerli olması için Docker Daemon'ı yeniden yükleyin:
sudo systemctl reload docker 2>/dev/null || true
```

---

### 2. Harbor Servislerini Başlatma ve Web Arayüzü Erişimi
Platform üzerindeki Harbor servisi port `18444` üzerinde tanımlıdır:

```bash
# Servisin çalıştığını doğrulayın:
curl -I http://127.0.0.1:18444
# HTTP/1.1 200 OK veya yönlendirme dönmelidir.
```

- **Tarayıcıdan Giriş:** `http://<SUNUCU-IP>:18444` (veya `http://<SUNUCU-IP>/harbor`)
- **Varsayılan Giriş Bilgileri:** Kullanıcı: `admin` | Parola: `admin` (veya kurulumda belirlenen parola).

---

### 3. Harbor Üzerinde Proje ve Robot Account Oluşturma

#### A. Yeni Proje Açma
1. Harbor Web Arayüzünde **Projects → + New Project** butonuna tıklayın.
2. Proje Adı: `devops-labs`
3. Erişim: **Public** veya **Private** seçip kaydedin.

#### B. CI/CD Robot Hesabı (Robot Account) Tanımlama
Üretim ortamlarında gerçek kullanıcı şifreleri yerine sınırlı yetkili (yalnızca Push/Pull yapabilen) token tabanlı robot hesapları kullanılır:
1. Harbor sol menüsünden **Robot Accounts → + New Robot Account** yolunu izleyin.
2. Ad: `robot$ci-builder`
3. Yetkiler: `devops-labs` projesi için **Push** ve **Pull** kutucuklarını işaretleyin.
4. **Save** diyerek üretilen **Token / Secret** değerini kopyalayın.

---

### 4. Robot Account ile CLI Girişi (docker login)
```bash
ROBOT_USER="robot$ci-builder"
ROBOT_SECRET="<HARBOR_TARAFINDAN_VERİLEN_TOKEN>"

# Yerel 18444 portu üzerinden giriş yapın (Cloudflare'e takılmaz!):
echo "${ROBOT_SECRET}" | docker login 127.0.0.1:18444 -u "${ROBOT_USER}" --password-stdin
# Beklenen Çıktı: "Login Succeeded"
```

---

### 5. İmajı Harbor Formatında Etiketleme ve Push Etme
```bash
# 1. Küçük bir temel imaj çekin:
docker pull alpine:3.20

# 2. İmajı Harbor formatına göre etiketleyin:
# Format: <REGISTRY_HOST>/<PROJE_ADI>/<IMAJ_ADI>:<ETIKET>
docker tag alpine:3.20 127.0.0.1:18444/devops-labs/micro-app:1.0.0

# 3. İmajı yerel port üzerinden Harbor'a yükleyin:
docker push 127.0.0.1:18444/devops-labs/micro-app:1.0.0
```

---

### 6. Harbor Dahili Trivy Taraması ve Zafiyet Engelleme Kuralı
Harbor içinde yerleşik gelen **Trivy** güvenlik tarayıcısı bulunmaktadır:

1. **Otomatik Tarama (Scan on Push):**
   - Harbor Web UI'da **Projects → devops-labs → Configuration** sekmesine gidin.
   - **"Automatically scan images on push"** seçeneğini aktif edin.
2. **Manuel Tarama:**
   - **Repositories → micro-app** içine girin.
   - `1.0.0` etiketinin sağındaki **Actions (...) → Scan** butonuna tıklayın.
3. **Zafiyet Raporunu İnceleme:**
   - Tarama bittiğinde yeşil/kırmızı rozette bulunan zafiyet sayılarını (CRITICAL, HIGH, MEDIUM) tıklayın.
   - CVE numaralarını (`CVE-2024-...`) ve düzeltilmiş paket sürümlerini arayüzde inceleyin.
4. **Kritik Zafiyetli İmajı Engelleme Politikası:**
   - Configuration sekmesinden **"Prevent vulnerable images from running"** seçeneğini `High` veya `Critical` seviyesine getirin.
   - Böylece içinde kritik açık bulunan bir imaj sunucular tarafından `docker pull` ile çekilmek istendiğinde Harbor tarafından **bloke edilir**!

---

### 7. Harbor'dan İmaj Çekme (Pull) ve Çalıştırma
```bash
# 1. Yerel kopyayı silin:
docker rmi 127.0.0.1:18444/devops-labs/micro-app:1.0.0

# 2. Harbor'dan geri indirin:
docker pull 127.0.0.1:18444/devops-labs/micro-app:1.0.0

# 3. Çalıştırıp test edin:
docker run --rm 127.0.0.1:18444/devops-labs/micro-app:1.0.0 echo "Harbor OCI Registry basariyla calisti!"
```

---

## ✅ Doğrulama (Verification)
- Harbor Web Arayüzünde (`http://<IP>:18444`) `devops-labs/micro-app` imajının listelendiğini ve katmanlarının görüntülendiğini teyit edin.
- `docker run` çıktısında `Harbor OCI Registry basariyla calisti!` mesajını görün.

---

## 🧹 Temizlik
```bash
docker logout 127.0.0.1:18444 2>/dev/null || true
docker rmi 127.0.0.1:18444/devops-labs/micro-app:1.0.0 2>/dev/null || true
```
