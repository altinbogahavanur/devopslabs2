# LAB-DOC-06-03 — Docker Hub Public ve Private Image Yayını

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
| --- | --- | --- | --- |
| Orta | 35 dakika | `docker-ce`, `docker-hub`, `pat` | Yok |

## Amaç

- Küçük bir NGINX tabanlı imajı Dockerfile ile oluşturmak.
- Docker Hub üzerinde bir public ve bir private repository oluşturmak.
- Aynı imajı iki repository adına etiketleyip Docker Hub'a göndermek.
- Public imajın oturumsuz, private imajın ise yalnızca kimliği doğrulanmış erişimle çekilebildiğini göstermek.
- Docker Hub erişim tokenını komut geçmişine veya dosyaya yazmadan kullanmak.

## Ön Koşullar

- `LAB-DOC-01`, `LAB-DOC-02` ve bu modüldeki yerel registry laboratuvarı tamamlanmış olmalıdır.
- Docker Hub'da size ait bir hesap bulunmalıdır.
- Docker Hub hesabında yalnızca bu laboratuvar için `Read & Write` yetkili bir Personal Access Token oluşturulmalıdır.
- Yerel Docker daemon çalışmalıdır: `docker version` komutu hem Client hem Server bilgisini göstermelidir.
- Kullanıcı adınız küçük harfli Docker Hub repository adlarıyla kullanılabilir olmalıdır.

## Mimari ve Çalışma Modeli

```text
[starter/Dockerfile + index.html]
              |
              v
  docker build: dockerhub-access-lab:1.0.0
              |
              +-----------------------------+
              |                             |
              v                             v
  <kullanici>/dockerhub-access-lab-public   <kullanici>/dockerhub-access-lab-private
              |                             |
      oturumsuz docker pull          yalnızca docker login ile docker pull
```

## Adım Adım Uygulama Rehberi

### 1. Çalışma Alanını Hazırlama ve İmajı Oluşturma

Bu laboratuvarın dizinine geçin. Başlangıç dosyalarını yalnızca bu laboratuvara ait `work` dizinine kopyalayın.

```bash
cd lab-06-harbor-registry-and-images/03-docker-hub-public-private
mkdir -p work
cp starter/Dockerfile starter/index.html work/
cd work

LOCAL_IMAGE="dockerhub-access-lab:1.0.0"
docker build -t "$LOCAL_IMAGE" .
docker run --rm "$LOCAL_IMAGE" sh -c 'grep -F "Docker Hub access lab" /usr/share/nginx/html/index.html'
```

Son komutun `Docker Hub access lab` metnini göstermesi, oluşturduğunuz imajın beklenen dosyayı içerdiğini kanıtlar.

### 2. Docker Hub'da Public ve Private Repository Oluşturma

Docker Hub arayüzünde **My Hub → Repositories → Create repository** yolunu izleyin ve aşağıdaki iki boş repository'yi kendi hesabınız altında oluşturun:

| Repository adı | Görünürlük |
| --- | --- |
| `dockerhub-access-lab-public` | `Public` |
| `dockerhub-access-lab-private` | `Private` |

Repository'leri oluştururken aynı Docker Hub namespace'i altında olduklarını doğrulayın. Bu laboratuvar yalnızca kendi hesabınıza ait repository'leri kullanır.

### 3. Tokenı Güvenli Şekilde Okuma ve Docker Hub'a Giriş

Kullanıcı adı ve token değeri dosyaya yazılmaz. Aşağıdaki komutlar tokenı ekranda göstermeden okur; `docker login` değeri standart girdiden alır.

```bash
read -r -p "Docker Hub kullanıcı adınız: " DOCKERHUB_USERNAME
read -r -s -p "Read & Write access token: " DOCKERHUB_TOKEN
printf '\n'

export DOCKERHUB_USERNAME
printf '%s' "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin
unset DOCKERHUB_TOKEN
```

Beklenen sonuç `Login Succeeded` ifadesidir. Tokenı komut satırına `-p` ile yazmayın ve shell geçmişine kaydetmeyin.

### 4. Public ve Private Image'ları Etiketleme ve Gönderme

```bash
PUBLIC_IMAGE="${DOCKERHUB_USERNAME}/dockerhub-access-lab-public:1.0.0"
PRIVATE_IMAGE="${DOCKERHUB_USERNAME}/dockerhub-access-lab-private:1.0.0"

docker tag "$LOCAL_IMAGE" "$PUBLIC_IMAGE"
docker tag "$LOCAL_IMAGE" "$PRIVATE_IMAGE"

docker push "$PUBLIC_IMAGE"
docker push "$PRIVATE_IMAGE"
```

Her iki `docker push` komutu sonunda digest ve `1.0.0` etiketi görünmelidir. Docker Hub arayüzünde public repository'nin görünürlüğünün `Public`, private repository'nin görünürlüğünün `Private` kaldığını denetleyin.

### 5. Kimliği Doğrulanmış Private Pull Doğrulaması

Önce yerel private etiketi silerek imajın gerçekten registry'den çekildiğini doğrulayın. Bu adımda Docker Hub oturumu açıktır.

```bash
docker image rm "$PRIVATE_IMAGE"
docker pull "$PRIVATE_IMAGE"
docker image inspect "$PRIVATE_IMAGE" --format '{{index .RepoDigests 0}}'
```

`docker pull` başarılı olmalı; `docker image inspect` çıktısında repository digest'i görünmelidir.

### 6. Oturumsuz Public ve Private Erişim Farkını Doğrulama

```bash
docker logout

docker image rm "$PUBLIC_IMAGE"
docker pull "$PUBLIC_IMAGE"

docker image rm "$PRIVATE_IMAGE"
docker pull "$PRIVATE_IMAGE"
```

Public imajın `docker pull` işlemi başarılı olmalıdır. Private imaj için ikinci `docker pull` işleminin erişim reddiyle başarısız olması beklenir. Bu, repository görünürlüğü ve kimlik doğrulaması farkını gösterir.

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker image inspect "$PUBLIC_IMAGE" --format '{{index .RepoDigests 0}}'
docker image ls --format '{{.Repository}}:{{.Tag}}' | grep "dockerhub-access-lab-public:1.0.0"
```

Public imajın digest'i ve yerel etiketi görünmelidir. Private imaj, Docker Hub oturumu açıkken çekilir; oturum kapalıyken çekme denemesi erişim reddi ile sonuçlanır.

## Temizlik

Bu komutlar yalnızca bu laboratuvarda oluşturulan yerel etiketleri ve çalışma dizinini hedefler. Docker Hub'daki repository'leri silmez.

```bash
docker image rm "dockerhub-access-lab:1.0.0" "$PUBLIC_IMAGE" "$PRIVATE_IMAGE" 2>/dev/null || true
rm -rf ./work
unset DOCKERHUB_USERNAME PUBLIC_IMAGE PRIVATE_IMAGE LOCAL_IMAGE
```
