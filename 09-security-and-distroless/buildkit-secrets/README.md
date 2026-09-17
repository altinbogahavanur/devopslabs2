# LAB-DOC-09-04 (Advanced) — BuildKit Gizli Bilgi Yönetimi ve Katman Sızıntılarının Önlenmesi

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | Docker BuildKit, docker history, Linux sh | Yok (Build Time Security) |

---

## 1. Amaç ve Kubernetes Bağlantısı

Bu labın amacı; Docker imaj derleme aşamasında (build time) API tokenları, SSH anahtarları ve veritabanı parolaları gibi hassas bilgilerin `ARG` veya `ENV` ile imaj katmanlarına sızdırılması (Layer Leaks) tehlikesini incelemek ve Docker BuildKit'in **`--mount=type=secret`** mekanizması ile sıfır sızıntılı üretim imajları üretmektir.

### Kubernetes Karşılığı (K8s Zemin)
* **İmaj Güvenliği ve CI/CD Güvenlik Açıkları:** Bir Docker imajı public veya private bir registry'ye yüklendiğinde, `docker history --no-trunc` veya `dive` komutuyla imajın inşa edildiği tüm komutlar ve argümanlar okunabilir. Birçok kurumsal veri ihlali, Dockerfile içine yazılan GitHub/AWS tokenlarının imaj katmanlarından çalınmasıyla gerçekleşir.
* **Kubernetes Secret vs Build Secret:** Kubernetes'te podlar gizli verileri `Secret` objeleri üzerinden runtime'da RAM mount'u olarak alır. Docker BuildKit de aynı prensiple çalışır: Gizli token diske yazılmaz; yalnızca o derleme adımında `/run/secrets/` altına geçici RAM tabanlı sanal bir dosya olarak bağlanır ve adım biter bitmez imha edilir.

---

## 2. Mimari ve Katman Sızıntısı Modeli

```
+-------------------------------------------------------------------------------+
| SENARYO A: ARG KULLANIMI (Dockerfile.leaky)                                   |
|                                                                               |
|   docker build --build-arg SECRET_TOKEN=ghp_123...                            |
|        |                                                                      |
|        v                                                                      |
|   [ Katman 1: echo Token: ghp_123... ] ---> SHA256 İMAJ GEÇMİŞİNE YAZILIR! ❌ |
|   (Sonraki adımda dosyayı silseniz bile, parola alt katmanda sonsuza dek kalır)|
+-------------------------------------------------------------------------------+

+-------------------------------------------------------------------------------+
| SENARYO B: BUILDKIT SECRET MOUNT (Dockerfile.secure)                          |
|                                                                               |
|   docker build --secret id=api_token,src=token.txt                            |
|        |                                                                      |
|        v                                                                      |
|   [ RAM Mount: /run/secrets/api_token ] (Sadece o RUN satırında yaşar)         |
|        |                                                                      |
|        v                                                                      |
|   Komut Bitti: RAM Temizlendi. İmaj Katmanında SIFIR İZ! ✅                    |
+-------------------------------------------------------------------------------+
```

---

## 3. Ön Koşullar

* Docker Engine (BuildKit aktif) kurulu olmalıdır.
* Çalışma dizini: `docker-labs/16-buildkit-secrets-and-layer-leaks/`

---

## 4. Adım Adım Uygulama Rehberi

### Adım 1: Güvensiz Yaklaşımı İnceleme ve Derleme

`Dockerfile.leaky` dosyasını inceleyin. `ARG SECRET_TOKEN` parametresinin nasıl kullanıldığına bakın:

```bash
docker build --build-arg SECRET_TOKEN="super_secret_github_token_ghp_1234567890abcdef" -f Dockerfile.leaky -t secret-demo:leaky .
```

---

### Adım 2: Katman Geçmişinde Parola İfşasını Gözlemleme

`docker history` komutuyla imajın geçmişini dökün:

```bash
docker history --no-trunc secret-demo:leaky
```
*Gözlem:* Girdiğiniz tüm token açık metin (cleartext) olarak terminalde görünmektedir! Bu imajı çeken herkes parolanızı ele geçirebilir.

---

### Adım 3: Güvenli BuildKit Secret Mount ile Derleme

`Dockerfile.secure` dosyasında `# syntax=docker/dockerfile:1` ve `RUN --mount=type=secret,id=api_token` satırını inceleyin:

```bash
DOCKER_BUILDKIT=1 docker build --secret id=api_token,src=secrets/api_token.txt -f Dockerfile.secure -t secret-demo:secure .
```

---

### Adım 4: Otomatik Denetim Betiğini Çalıştırma

```bash
./test-secrets.sh
```

---

## 5. Doğrulama ve Beklenen Sonuç

Güvenli imajın geçmişinde token aratın:

```bash
docker history --no-trunc secret-demo:secure | grep "super_secret" || echo "✅ TEMİZ: Parola imaj katmanında kesinlikle YOK!"
```

---

## 6. Temizlik (Teardown)

```bash
docker rmi secret-demo:leaky secret-demo:secure 2>/dev/null || true
```
