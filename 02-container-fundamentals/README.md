# LAB-02 — Konteyner Yaşam Döngüsü, docker cp, docker commit ve Teşhis Araçları

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 45 dakika | `docker-ce`, `curl` | `8080, 8081` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 17 & 35, Lab 1 & 2); Docker konteynerlarının yaşam döngüsünü baştan sona yönetmek, çalışan bir konteyner ile ana makine arasında çift yönlü dosya transferi yapmak (`docker cp`), canlı değişiklikleri imaja dönüştürmek (`docker commit`), süreç çıkış kodlarını (ExitCode) incelemek ve üretim seviyesinde hata ayıklama araçlarını (`stats`, `top`, `inspect`, `logs`) etkin kullanmaktır.

---

## 2. Ön Koşullar

* Docker Engine çalışır durumda olmalıdır (`docker info`).
* Host üzerinde `8080` ve `8081` portları boşta olmalıdır.

---

## 3. Mimari ve Çalışma Modeli

```text
               HOST MAKİNE (Ubuntu)                          KONTEYNER (Nginx)
        +──────────────────────────────────+        +──────────────────────────────────+
        |                                  |        |                                  |
        |  ./app/index.html                |───────>|  /usr/share/nginx/html/index.html|
        |               (docker cp HOST CONTAINER)  |                                  |
        |                                  |        |                                  |
        |  /tmp/nginx.conf                 |<───────|  /etc/nginx/nginx.conf           |
        |               (docker cp CONTAINER HOST)  |                                  |
        +──────────────────────────────────+        +──────────────────────────────────+
                         │                                           │
                         ▼                                           ▼
             +───────────────────────+                   +───────────────────────+
             |   docker commit       | ───────────────>  |  custom-nginx:v1.0    |
             |  (Anlık Durum İmajı)  |                   |  (Yeni İmaj Üretildi) |
             +───────────────────────+                   +───────────────────────+
```

---

## 4. Görevler (Tasks)

1. **İlk Konteyner (Lab 1):** `nginx:alpine` imajını kullanarak arka planda çalışan, hostun `8080` portuna bağlı ve adı `my-web` olan bir konteyner başlatın. Tarayıcıdan veya `curl` ile erişimi doğrulayın.
2. **Çift Yönlü Dosya Kopyalama:** `app/index.html` dosyasını `docker cp` ile konteynerin `/usr/share/nginx/html/index.html` yoluna kopyalayın; konteyner içindeki `/etc/nginx/nginx.conf` dosyasını ise hostun `/tmp/` dizinine çekin.
3. **İmaj Üretme (docker commit):** Değiştirilmiş `my-web` konteynerini `custom-nginx:v1.0` adında yeni bir imaja dönüştürün. Orijinal konteyneri silip yeni imajdan yeni bir konteyner başlatın ve HTML değişikliğinin korunduğunu test edin.
4. **Yaşam Döngüsü ve ExitCode Teşhisi (Lab 2):** Kasten hata ile kapanan (`sh -c 'echo start; exit 1'`) bir `exit-demo` konteyneri başlatın. `docker inspect` kullanarak `ExitCode` değerini okuyun.
5. **Canlı Kaynak İzleme:** `docker stats --no-stream` ve `docker top` ile çalışan süreçleri ve kaynak tüketimini denetleyin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: -p (Publish) Formatı</summary>

`-p [HOST_PORT]:[CONTAINER_PORT]` şeklinde çalışır. Örneğin `-p 8080:80` dendiğinde sunucunun 8080 portuna gelen istek konteynerın 80 portuna iletilir.
</details>

<details>
<summary>💡 İpucu 2: Neden docker commit Üretimde Anti-Pattern Kabul Edilir?</summary>

`docker commit` ile üretilen imajların içinde tam olarak hangi adımların yapıldığı bir kod dosyası olarak izlenemez (Kara kutu - Black box). Bu yüzden profesyonel dünyada imajlar **her zaman `Dockerfile` ile şeffaf, sürümlenebilir ve tekrarlanabilir (reproducible)** olarak derlenir.
</details>

<details>
<summary>💡 İpucu 3: ExitCode Format Filtreleme</summary>

`docker inspect` tüm JSON çıktısını döker. Yalnızca durum ve çıkış kodunu filtrelemek için Go şablonu kullanılır: `docker inspect -f '{{.State.Status}} {{.State.ExitCode}}' <container-adi>`.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

```bash
# 1. Web sunucusu erişimi
curl -s http://localhost:8080 | grep -i "html"

# 2. Hata kodu teşhisi
docker inspect -f '{{.State.ExitCode}}' exit-demo
```

* **Beklenen Çıktılar:**
  * `curl` çıktısında özel HTML içeriği dönmelidir.
  * `exit-demo` için `1` çıkış kodu görülmelidir.

---

## 7. Temizlik

Laboratuvar tamamlandığında bir sonraki modülle çakışmaması için konteynerları ve geçici imajı temizleyin:

```bash
docker rm -f my-custom-web exit-demo 2>/dev/null || true
docker rmi custom-nginx:v1.0 2>/dev/null || true
rm -f /tmp/nginx_extracted.conf
```
