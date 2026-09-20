# Pratik Lab 01: Docker `exec` ve `cp` İle Canlı Konteyner Teftişi ve Dosya Transferi

Bu pratik laboratuvarda, çalışan bir Nginx web konteynerinin içine interaktif kabuk açarak girecek (`docker exec`), ana makineden konteynere canlı hotfix dosyası kopyalayacak (`docker cp`) ve konteynerin içindeki logları dışarı aktaracaksınız.

---

## 1. Konteyneri Başlatma

```bash
docker run -d --name lab-web -p 19001:80 nginx:alpine
docker ps -f name=lab-web
```
* Tarayıcınızdan `http://localhost:19001` (veya sunucu IP'niz) adresine gidin; varsayılan "Welcome to nginx!" sayfasını görün.

---

## 2. Konteynerin İçine Girme (`docker exec`)

Konteyneri durdurmadan içine interaktif bir kabuk (`sh`) ile sızın:
```bash
docker exec -it lab-web sh
```

Konteyner içinde şu teftiş komutlarını çalıştırın:
```sh
# Çevre değişkenlerini görün
env

# Çalışan prosesleri listeleyin
ps aux

# Varsayılan karşılama sayfasını okuyun
cat /usr/share/nginx/html/index.html

# Konteynerden çıkın (Konteyner arka planda çalışmaya devam eder!)
exit
```

---

## 3. Canlı Hotfix Enjeksiyonu (`docker cp` — Host ➔ Konteyner)

Konteyneri yeniden derlemeden (rebuild) ve kapatmadan ana makinedeki `ornek-hotfix.html` dosyasını konteynere gönderin:
```bash
docker cp ornek-hotfix.html lab-web:/usr/share/nginx/html/index.html
```

Test edin:
```bash
curl http://localhost:19001
```
* Sayfanın anında değiştiğini ve servisin sıfır kesintiyle güncellendiğini doğrulayın!

---

## 4. İçeriden Dışarı Dosya Alma (`docker cp` — Konteyner ➔ Host)

Konteynerin içindeki Nginx konfigürasyonunu ve erişim logunu ana makineye çekin:
```bash
docker cp lab-web:/etc/nginx/nginx.conf ./cekilen-nginx.conf
docker cp lab-web:/var/log/nginx/access.log ./cekilen-access.log

ls -lh cekilen-*
head -n 10 cekilen-nginx.conf
```

---

## 5. Temizlik

```bash
docker rm -f lab-web
rm -f cekilen-*
```
