# * LAB-09: İmaj Etiketleme ve Docker Hub (Public ve Private) Yayını

## 🎯 Labın Amacı
Docker imajlarını semantik versiyonlama kurallarıyla etiketlemek (`docker tag`); **Docker Hub** üzerinde hem **Public (Herkese Açık)** hem de **Private (Gizli / Yetkili)** iki ayrı repository oluşturmak, imajları yüklemek (`docker push`), oturumsuz (anonim) ve oturumlu çekme (`docker pull`) farklarını uygulamalı olarak gözlemlemek ve yetkisiz çekme hatasını (`pull access denied`) doğrulamak.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Ücretsiz bir [Docker Hub](https://hub.docker.com) hesabı.
- Docker Hub hesabınızda oluşturulmuş `Read & Write` yetkili bir **Personal Access Token (PAT)** (veya hesap şifreniz).
- Host üzerinde **8085** ve **8086** portları test için boşta olmalıdır.

---

## 🏛️ Mimari ve Çalışma Modeli

```text
[starter/Dockerfile + index.html]
              │
              ▼
  docker build: dockerhub-access-lab:1.0.0
              │
              ├───────────────────────────────────────────┐
              ▼                                           ▼
  <kullanici>/dockerhub-access-lab-public      <kullanici>/dockerhub-access-lab-private
              │                                           │
      [HERKESE AÇIK]                              [GİZLİ / KORUMALI]
              │                                           │
  - docker logout                             - docker logout
  - docker pull: ✅ BAŞARILI                   - docker pull: 🛑 ACCESS DENIED!
                                              - docker login
                                              - docker pull: ✅ BAŞARILI
```

---

## 🚀 Adım Adım Uygulama

### Adım 1: Çalışma Dizinine Geçin ve İmajı Derleyin
Lab dizinine geçip `starter` klasöründeki dosyalarla yerel bir test imajı derleyin:

```bash
cd lab-09-image-tagging-and-registry

# 1. Başlangıç dosyalarını inceleyin:
cat starter/Dockerfile
cat starter/index.html

# 2. Yerel imajı derleyin:
docker build -t dockerhub-access-lab:1.0.0 starter/

# 3. İmajın çalıştığını hızlıca test edin:
docker run --rm dockerhub-access-lab:1.0.0 cat /usr/share/nginx/html/index.html
```
*(Son komutta HTML içeriğini görüyorsanız imajınız yayına hazırdır).*

---

### Adım 2: Docker Hub'da Public ve Private Repository Açın
1. Tarayıcınızdan [hub.docker.com](https://hub.docker.com) adresine gidin ve giriş yapın.
2. Sağ üstteki **Repositories → Create repository** butonuna tıklayın.
3. **1. Repository:**
   - Adı: `dockerhub-access-lab-public`
   - Görünürlük: **Public** (Herkese Açık) seçin ve **Create** butonuna basın.
4. Tekrar **Create repository** butonuna tıklayın:
   - Adı: `dockerhub-access-lab-private`
   - Görünürlük: **Private** (Gizli) seçin ve **Create** butonuna basın.

---

### Adım 3: Docker Hub'a Güvenli Giriş Yapın
Terminalde kullanıcı adınızı ve erişim token'ınızı belirleyerek giriş yapın:

```bash
# Kullanıcı adınızı değişkene atayın:
DOCKERHUB_USERNAME="<DOCKERHUB_KULLANICI_ADINIZ>"

# Docker Hub'a oturum açın (Token veya şifrenizi girin):
docker login --username "${DOCKERHUB_USERNAME}"
```
*Beklenen Çıktı: `Login Succeeded`*

---

### Adım 4: Public ve Private İmajları Etiketleyin
Docker Hub'a imaj gönderebilmek için imaj adı `<kullanici_adi>/<repo_adi>:<etiket>` formatında olmalıdır:

```bash
# 1. Public imajı etiketleyin:
docker tag dockerhub-access-lab:1.0.0 "${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0"

# 2. Private imajı etiketleyin:
docker tag dockerhub-access-lab:1.0.0 "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"

# 3. Etiketleri listeleyin:
docker images | grep dockerhub-access-lab
```

---

### Adım 5: İmajları Docker Hub'a Gönderin (Push)
```bash
# 1. Public imajı gönderin:
docker push "${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0"

# 2. Private imajı gönderin:
docker push "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"
```
*(Her iki komutun sonunda katmanların yüklendiğini ve digest değerinin basıldığını görün).*

---

### Adım 6: Yetkili Olarak Private İmajı Çekme Testi
Oturumunuz açıkken yerel private imajı silip Docker Hub'dan çekmeyi deneyin:

```bash
# 1. Yerel kopyayı silin:
docker rmi "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"

# 2. Yetkili oturum açıkken indirin:
docker pull "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"
```
*Sonuç: Başarıyla indirilir.*

---

### Adım 7: Oturumu Kapatıp Anonim Public vs Private Farkını Kanıtlayın
Burası laboratuvarın en kritik deneyidir:

```bash
# 1. Docker Hub oturumunu tamamen kapatın:
docker logout

# 2. Yereldeki her iki imajı da tamamen silin:
docker rmi "${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0"
docker rmi "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"

# 3. Şifresiz / Anonim olarak PUBLIC imajı çekin:
docker pull "${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0"
# (SONUÇ: BAŞARILI! Public imajlar için login gerekmez).

# 4. Şifresiz / Anonim olarak PRIVATE imajı çekmeyi deneyin:
docker pull "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"
```

🛑 **BEKLENEN GÜVENLİK ENGELİ:**
```text
Error response from daemon: pull access denied for <kullanici>/dockerhub-access-lab-private, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
```
Docker Hub, private repository için kimlik doğrulama yapılmadığını görerek işlemi anında reddeder!

---

### Adım 8: Tekrar Giriş Yapıp Private İmajı Başlatın
```bash
# Tekrar giriş yapın:
docker login --username "${DOCKERHUB_USERNAME}"

# Şimdi private imajı başarıyla indirin:
docker pull "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"

# Konteyneri başlatıp test edin:
docker run -d --name private-test -p 8086:80 "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"
curl http://localhost:8086
```

---

### Adım 9: (Opsiyonel) Yerel Bağımsız Registry (`registry:2`)
Kurumsal ortamlarda Docker Hub kotasına takılmadan veya internet yokken yerel ağda imaj tutmak için standart `registry:2` kullanılır:

```bash
# 1. Yerel registry konteynerini başlatın:
docker run -d -p 5000:5000 --name local-registry registry:2

# 2. İmajı localhost:5000 için etiketleyin:
docker tag dockerhub-access-lab:1.0.0 localhost:5000/my-company-app:1.0.0

# 3. Yerel registry'ye yükleyin:
docker push localhost:5000/my-company-app:1.0.0

# 4. HTTP API ile registry kataloğunu sorgulayın:
curl http://localhost:5000/v2/_catalog
# Yanıt: {"repositories":["my-company-app"]}
```

---

## ✅ Doğrulama (Verification)
- `docker logout` yapıldığında `public` imajın sorunsuz indiğini, `private` imajın `access denied` hatası verdiğini bizzat test ettiniz.
- `docker login` sonrasında private imajın başarıyla indirilip çalıştığını doğruladınız.

---

## 🧹 Temizlik
```bash
# Çalışan test konteynerlerini durdurup silin:
docker rm -f private-test local-registry 2>/dev/null || true

# Yerel etiketleri silin:
docker rmi "${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0" \
  "${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0" \
  localhost:5000/my-company-app:1.0.0 \
  dockerhub-access-lab:1.0.0 2>/dev/null || true
```
