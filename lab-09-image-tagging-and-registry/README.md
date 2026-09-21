# LAB-09: İmaj Etiketleme, Docker Hub (Public/Private) ve Yerel Registry

## 🎯 Labın Amacı
Docker imajlarını semantik versiyonlama ile etiketlemek (`docker tag`); **Docker Hub** üzerinde hem **Public** (herkese açık) hem de **Private** (gizli/yetkili) imaj yayınlamak, yetkisiz çekme hatasını (`access denied`) gözlemlemek, token ile giriş yaparak imajı çekip çalıştırmak ve kurumsal yerel registry (`registry:2`) mantığını kavramak.

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Ücretsiz bir Docker Hub hesabı (veya yerel test için port 5000).

---

## 🚀 Adım Adım Uygulama

### 1. Basit Bir Test Uygulaması ve İmaj Derleme
Önce yayınlayacağımız hafif bir test imajı oluşturalım:

```bash
mkdir -p /tmp/registry-demo && cd /tmp/registry-demo

# 1. Basit bir HTML sayfası hazırlayın:
echo "<h1>DevOps Registry Egitimi - v1.0.0</h1>" > index.html

# 2. Minimal Nginx Dockerfile oluşturun:
cat <<'EOF' > Dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# 3. İmajı yerelde derleyin:
docker build -t hello-registry:1.0.0 .
```

---

### 2. AŞAMA: Docker Hub Public İmaj Yayını (Herkese Açık)

#### Adım 1: Docker Hub Kullanıcı Adınızla Etiketleme
Docker Hub'a imaj yüklemek için imaj adı `kullanici_adiniz/imaj_adi:etiket` formatında olmalıdır:

```bash
DOCKERHUB_USER="<DOCKERHUB_KULLANICI_ADINIZ>"

# İmajı etiketleyin:
docker tag hello-registry:1.0.0 ${DOCKERHUB_USER}/hello-public:1.0.0
```

#### Adım 2: Docker Hub'a Giriş ve Push
```bash
# Docker Hub'a oturum açın (Şifre veya Personal Access Token girin):
docker login -u ${DOCKERHUB_USER}

# Public imajı Docker Hub'a gönderin:
docker push ${DOCKERHUB_USER}/hello-public:1.0.0
```

#### Adım 3: Şifresiz / Anonim Pull ve Çalıştırma
Public repository'ler oturum açmadan herkes tarafından indirilebilir:
```bash
# 1. Yereldeki imajı tamamen silin:
docker rmi ${DOCKERHUB_USER}/hello-public:1.0.0 hello-registry:1.0.0

# 2. Docker oturumunu kapatın (Anonim duruma geçin):
docker logout

# 3. Şifresiz olarak Docker Hub'dan çekin ve çalıştırın:
docker run -d --name public-app -p 8085:80 ${DOCKERHUB_USER}/hello-public:1.0.0

# 4. Test edin:
curl http://localhost:8085
docker rm -f public-app
```

---

### 3. AŞAMA: Docker Hub Private İmaj Yayını (Gizli / Yetkili)

#### Adım 1: Docker Hub Arayüzünde Private Repo Açma
1. Tarayıcıdan [hub.docker.com](https://hub.docker.com) adresine gidin.
2. **Create Repository** butonuna tıklayın.
3. Repository adını `hello-private` yapın ve görünürlüğü **Private** seçip kaydedin.

#### Adım 2: İmajı Private Repo Adresine Etiketleyip Push Etme
```bash
# 1. Tekrar giriş yapın:
docker login -u ${DOCKERHUB_USER}

# 2. İmajı private repoya göre etiketleyin:
docker tag ${DOCKERHUB_USER}/hello-public:1.0.0 ${DOCKERHUB_USER}/hello-private:1.0.0 2>/dev/null || \
docker build -t ${DOCKERHUB_USER}/hello-private:1.0.0 .

# 3. Push edin:
docker push ${DOCKERHUB_USER}/hello-private:1.0.0
```

#### Adım 3: Yetkisiz İndirme Deneyi (Hata Alma)
```bash
# 1. Yerel kopyayı silin:
docker rmi ${DOCKERHUB_USER}/hello-private:1.0.0

# 2. Oturumu kapatın:
docker logout

# 3. Giriş yapmadan private imajı çekmeyi deneyin:
docker pull ${DOCKERHUB_USER}/hello-private:1.0.0
# BEKLENEN HATA: "pull access denied, repository does not exist or may require 'docker login'"
```

#### Adım 4: Kimlik Doğrulama ile Çekme ve Çalıştırma
```bash
# Yetkili token ile giriş yapın:
docker login -u ${DOCKERHUB_USER}

# Şimdi çekin (Başarılı olacaktır):
docker pull ${DOCKERHUB_USER}/hello-private:1.0.0

# Konteyneri başlatıp test edin:
docker run -d --name private-app -p 8086:80 ${DOCKERHUB_USER}/hello-private:1.0.0
curl http://localhost:8086
docker rm -f private-app
```

---

### 4. AŞAMA: Yerel Bağımsız Registry (registry:2) Mantığı
İnternet veya Docker Hub kotasına takılmadan yerel ağda `localhost:5000` üzerinden hızlı imaj deposu:

```bash
# 1. Yerel hafif registry başlatın:
docker run -d -p 5000:5000 --name local-reg registry:2

# 2. İmajı yerel porta etiketleyip push edin:
docker tag ${DOCKERHUB_USER}/hello-private:1.0.0 localhost:5000/my-app:1.0.0
docker push localhost:5000/my-app:1.0.0

# 3. Registry kataloğunu HTTP API ile sorgulayın:
curl http://localhost:5000/v2/_catalog
# Yanıt: {"repositories":["my-app"]}
```

---

## ✅ Doğrulama (Verification)
- Public imajın `docker logout` sonrasında dahi çekilip çalıştığını görün.
- Private imajın `docker logout` sonrasında `access denied` hatası verdiğini, `docker login` sonrasında başarıyla çekildiğini teyit edin.

---

## 🧹 Temizlik
```bash
docker rm -f local-reg 2>/dev/null || true
docker rmi localhost:5000/my-app:1.0.0 2>/dev/null || true
rm -rf /tmp/registry-demo
```
