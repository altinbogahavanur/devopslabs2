# * LAB-09: İmaj Etiketleme ve Docker Hub (Public ve Private) Yayını

## 🎯 Labın Amacı
Docker imajlarını ürün ve versiyon standartlarına uygun etiketlemek (`docker tag`); **Docker Hub** üzerinde hem **Public (Herkese Açık)** hem de **Private (Gizli / Yetkili)** iki ayrı repository oluşturmak; imajları sırayla göndermek (`docker push`), çalıştırmak, lokalden silip tekrar çekmek (`docker pull`) ve yetkisiz çekme hatasını (`pull access denied`) uygulamalı olarak doğrulamak.

---

## 📋 Ön Koşullar & Portlar
- Docker Engine çalışır durumda olmalıdır.
- Ücretsiz bir [Docker Hub](https://hub.docker.com) hesabı.
- Docker Hub hesabınızda oluşturulmuş `Read & Write` yetkili bir **Personal Access Token (PAT)** (veya hesap şifreniz).
- Host üzerinde **8085** ve **8086** portları test için boşta olmalıdır.

---

## 🏛️ Mimari ve Repository Özeti

| Repository Türü | Docker Hub Depo Adı | Örnek Tam İmaj Adı | Erişim Kuralı |
| :--- | :--- | :--- | :--- |
| **Public (Açık)** | `devops-app-pub` | `hbayraktar/devops-app-pub:nginx-1.0` | Herkes çekebilir (`docker logout` olsa bile). |
| **Private (Gizli)** | `devops-app` | `hbayraktar/devops-app:nginx-1.0` | Sadece `docker login` yapmış yetkili hesap çekebilir. |

```text
[starter/Dockerfile + index.html]
              │
              ▼
    devops-app:nginx-1.0
              │
   ┌──────────┴─────────────────────────┐
   ▼                                    ▼
1. BÖLÜM: PUBLIC                     2. BÖLÜM: PRIVATE
hbayraktar/devops-app-pub:nginx-1.0  hbayraktar/devops-app:nginx-1.0
   │                                    │
   ├─ Push                              ├─ Push
   ├─ Run & Curl (8085)                 ├─ Run & Curl (8086)
   ├─ Lokalden Sil (rmi)                ├─ Lokalden Sil (rmi)
   ├─ Hub'dan Geri Çek (pull)           ├─ Oturumu Kapat (logout)
   └─ Çalıştır ve Doğrula               ├─ Çekmeyi Dene 🛑 (Access Denied!)
                                        ├─ Tekrar Giriş Yap (login)
                                        └─ Çek (pull) ve Doğrula ✅
```

---

## 🚀 Adım Adım Uygulama

### Adım 1: Çalışma Dizinine Geçin ve Yerel İmajı Derleyin
Lab dizinine geçip `starter` klasöründeki dosyalarla temel bir test imajı derleyin:

```bash
# 1. Adım: Lab çalışma dizinine geçin:
cd ~/docker-labs/lab-09-image-tagging-and-registry

# 2. Adım: Başlangıç dosyalarını inceleyin:
cat starter/Dockerfile
cat starter/index.html

# 3. Adım: Yerel imajı ürün ve sürüm etiketiyle derleyin:
docker build -t devops-app:nginx-1.0 starter/

# 4. Adım: İmajın derlendiğini teyit edin:
docker images | grep devops-app
```

---

### Adım 2: Docker Hub'da Public ve Private İki Repository Açın
1. Web tarayıcınızdan [hub.docker.com](https://hub.docker.com) adresine gidin ve oturum açın.
2. Sağ üstteki **Repositories → Create repository** butonuna tıklayın.
3. **1. Repository (Public):**
   - Repository Name: `devops-app-pub`
   - Visibility: **Public** (Herkese Açık) seçin ve **Create** butonuna basın.
4. Tekrar **Create repository** butonuna tıklayın:
5. **2. Repository (Private):**
   - Repository Name: `devops-app`
   - Visibility: **Private** (Gizli) seçin ve **Create** butonuna basın.

---

### Adım 3: Docker Hub'a Giriş Yapın
Terminalde kullanıcı adınızı tanımlayarak oturum açın:

```bash
# Kullanıcı adınızı değişkene atayın (Kendi kullanıcı adınızı yazın):
DOCKERHUB_USERNAME="<DOCKERHUB_KULLANICI_ADINIZ>"
# (Örnek: DOCKERHUB_USERNAME="hbayraktar")

# Docker Hub'a oturum açın (Şifrenizi veya Personal Access Token'ınızı girin):
docker login --username "${DOCKERHUB_USERNAME}"
```
*Beklenen Çıktı:* `Login Succeeded`

---

## 🌐 1. BÖLÜM: Public Repository Akışı (`devops-app-pub`)

### Adım 4: Public İmajı Etiketleyin ve Docker Hub'a Gönderin (Push)
```bash
# 1. Yerel imajı public repository için etiketleyin:
docker tag devops-app:nginx-1.0 "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"

# 2. Docker Hub'a gönderin:
docker push "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"
```
*(Docker Hub arayüzünde `devops-app-pub` reposuna gidip `nginx-1.0` etiketini görüntüleyin).*

### Adım 5: Konteyneri Çalıştırıp Test Edin
```bash
# 1. Konteyneri 8085 portundan başlatın:
docker run -d --name test-pub -p 8085:80 "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"

# 2. HTTP yanıtını test edin:
curl http://localhost:8085
```

### Adım 6: Lokalden Silin, Docker Hub'dan Tekrar Çekin (Pull)
```bash
# 1. Test konteynerini durdurup silin:
docker rm -f test-pub

# 2. Lokal imajı tamamen silin:
docker rmi "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"

# 3. İmajı doğrudan Docker Hub'dan tekrar çekin:
docker pull "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"

# 4. İndirilen imajı çalıştırıp doğrulayın:
docker run -d --name test-pub-pulled -p 8085:80 "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0"
curl http://localhost:8085

# 5. Konteyneri temizleyin:
docker rm -f test-pub-pulled
```
*(Public repo akışı başarıyla tamamlandı).*

---

## 🔒 2. BÖLÜM: Private Repository Akışı (`devops-app`)

### Adım 7: Private İmajı Etiketleyin ve Docker Hub'a Gönderin (Push)
```bash
# 1. Yerel imajı private repository için etiketleyin:
docker tag devops-app:nginx-1.0 "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"

# 2. Docker Hub'a gönderin (Oturumunuz açık olduğu için yetkiyle yüklenir):
docker push "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"
```

### Adım 8: Konteyneri Çalıştırıp Test Edin
```bash
# 1. Konteyneri 8086 portundan başlatın:
docker run -d --name test-priv -p 8086:80 "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"

# 2. HTTP yanıtını test edin:
curl http://localhost:8086
```

### Adım 9: Lokalden Silin ve Oturumu Kapatın (docker logout)
```bash
# 1. Test konteynerini silin:
docker rm -f test-priv

# 2. Lokal private imajları tamamen silin:
docker rmi "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0" devops-app:nginx-1.0

# 3. Docker Hub oturumunu tamamen kapatın:
docker logout
```
*Beklenen Çıktı:* `Removing login credentials for https://index.docker.io/v1/`

### Adım 10: Anonim Olarak Çekmeyi Deneyin (Beklenen Yetkisiz Hata!)
Oturum kapalıyken gizli depodan imaj indirmeye çalışın:

```bash
docker pull "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"
```

🛑 **BEKLENEN GÜVENLİK ENGELİ:**
```text
Error response from daemon: pull access denied for hbayraktar/devops-app, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
```
*(Gözlem: Repository gizli olduğu için Docker Hub anonim indirmeye izin vermedi).*

### Adım 11: Tekrar Giriş Yapın, Private İmajı İndirin ve Çalıştırın
```bash
# 1. Tekrar yetkili giriş yapın:
docker login --username "${DOCKERHUB_USERNAME}"

# 2. Şimdi private imajı sorunsuz indirin:
docker pull "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"

# 3. Konteyneri başlatıp çalıştığını teyit edin:
docker run -d --name test-priv-pulled -p 8086:80 "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0"
curl http://localhost:8086
```

---

## ✅ Doğrulama (Verification)
- **Public Repo:** `docker logout` yapılsa dahi herkes tarafından çekilebilir.
- **Private Repo:** Yalnızca `docker login` ile kimlik doğrulaması yapmış yetkili hesap tarafından çekilebilir; yetkisiz çekimlerde `pull access denied` hatası döner.

---

## 🧹 Temizlik
```bash
# Çalışan test konteynerini kaldırın:
docker rm -f test-priv-pulled 2>/dev/null || true

# Yerel test imajlarını temizleyin:
docker rmi "${DOCKERHUB_USERNAME}/devops-app-pub:nginx-1.0" \
  "${DOCKERHUB_USERNAME}/devops-app:nginx-1.0" 2>/dev/null || true
```
