# LAB-DOC-18 — Docker Compose Profilleri ve Çoklu Ortam (Dev/Prod) Yönetimi

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---|:---:|:---|:---:|
| Uzman | 35 Dakika | Docker Compose V2, YAML Overrides | 8080 (App), 8081 (Adminer) |

[18-compose-profiles-and-overrides.zip](18-compose-profiles-and-overrides.zip)

---

## 1. Amaç ve Kubernetes Bağlantısı

Bu labın amacı; Docker Compose V2'de **Servis Profilleri (`profiles`)** kullanarak isteğe bağlı servisleri (Monitoring, Debugging, DB Admin araçları) yönetmeyi ve tek bir ana `docker-compose.yaml` dosyasını bozmadan geliştirme (`dev`) ve üretim (`prod`) ortamlarını **Compose Overrides** tekniğiyle modüler olarak yapılandırmayı öğrenmektir.

### Kubernetes Karşılığı (K8s Zemin)
* **Kubernetes Kustomize Overlays (`base/` vs `overlays/`):** Docker Compose'daki dosya ezme (override) mekanizması, Kubernetes'te YAML kopyalamayı engelleyen Kustomize aracının doğrudan karşılığıdır:
  * `docker-compose.yaml` -> Kustomize `base/`
  * `docker-compose.prod.yaml` -> Kustomize `overlays/prod/`
* **Helm Values Katmanlama:** Helm ile dağıtım yaparken varsayılan `values.yaml` üzerine `helm install -f values-prod.yaml` ile üretim değerlerini bindirme mantığıyla tamamen örtüşür.
* **Kaynak Tasarrufu:** Geliştiricinin bilgisayarında her zaman Prometheus, Jaeger veya Adminer çalışmasına gerek yoktur. `profiles: ["monitoring"]` sayesinde bu servisler yalnızca ihtiyaç duyulduğunda RAM tüketir.

---

## 2. Mimari ve Profil Modeli

```
+-----------------------------------------------------------------------+
| DOCKER COMPOSE YÖNETİMİ                                               |
|                                                                       |
|   1. VARSAYILAN ÇALIŞMA:                                              |
|      docker compose up -d                                             |
|      ├── web (Her zaman aktif)                                        |
|      └── db  (Her zaman aktif)                                        |
|                                                                       |
|   2. PROFİL İLE ÇALIŞMA:                                              |
|      docker compose --profile monitoring up -d                        |
|      ├── web                                                          |
|      ├── db                                                           |
|      └── monitoring-agent (Sadece profil çağrılınca eklenir!)         |
|                                                                       |
|   3. ÜRETİM OVERRIDE:                                                 |
|      docker compose -f docker-compose.yaml -f docker-compose.prod.yaml|
|      └── DEBUG=false, restart: always, prod credentials enjekte olur! |
+-----------------------------------------------------------------------+
```

---

## 3. Ön Koşullar

* Docker Engine ve Docker Compose V2 kurulu olmalıdır.
* Çalışma dizini: `docker-labs/18-compose-profiles-and-overrides/`

---

## 4. Adım Adım Uygulama Rehberi

### Adım 1: Standart Başlatma ve Profil Filtresi

Herhangi bir profil bayrağı vermeden stack'i başlatın:

```bash
docker compose up -d --build || docker-compose up -d --build
docker compose ps || docker-compose ps
```
*Gözlem:* Yalnızca `web` ve `db` ayağa kalkmıştır. `monitoring-agent` ve `db-admin` servisleri bekletilmektedir.

---

### Adım 2: Belirli Bir Profili Devreye Alma

Sadece `monitoring` bileşenlerini ekleyerek ayağa kaldırın:

```bash
docker compose --profile monitoring up -d || docker-compose --profile monitoring up -d
docker compose ps || docker-compose ps
```
*Gözlem:* Artık `profile-metrics-collector` servisi de çalışmaktadır.

---

### Adım 3: Üretim Override Konfigürasyonunu Doğrulama

Docker Compose'un iki dosyayı nasıl dinamik olarak birleştirdiğini (Merge) test edin:

```bash
docker compose -f docker-compose.yaml -f docker-compose.prod.yaml config
```
*Gözlem:* `APP_ENV: production` ve `restart: always` değerlerinin temel konfigürasyonun üzerine yazıldığını (override) inceleyin.

---

### Adım 4: Otomasyon Test Betiğini Çalıştırma

```bash
./test-profiles.sh
```

---

## 5. Doğrulama ve Beklenen Sonuç

Web servisinin yanıtını test edin:

```bash
curl -s http://localhost:8080/
```

*Beklenen JSON Çıktısı:*
```json
{
  "debug_mode": "true",
  "environment": "development",
  "message": "Compose Profiles & Overrides Başarıyla Çalışıyor",
  "service": "Profile Demo Service"
}
```

---

## 6. Temizlik (Teardown)

Tüm profillere ait servisleri kapatmak için `--profile "*"` kullanın:

```bash
docker compose --profile "*" down -v || docker-compose --profile "*" down -v
docker rmi 18-compose-profiles-and-overrides-web 2>/dev/null || true
```
