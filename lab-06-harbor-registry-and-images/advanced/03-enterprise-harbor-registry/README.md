# LAB-DOC-06-02 (Advanced) — Kurumsal Harbor OCI Registry ve Trivy Güvenlik Taraması

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `harbor`, `trivy`, `docker-ce`, `robot-accounts` | 18444 |

> **Önemli Erişim Notu:** Platformumuzda kurumsal Harbor OCI Registry servisi halihazırda çalışır durumdadır. Web arayüzüne `http://<SUNUCU-IP>:18444` (veya Reverse Proxy üzerinden `https://studentXX-harbor.<domain>` / `/harbor`) adresinden erişebilirsiniz. Varsayılan yönetici kullanıcısı `admin`dir.

---

## Amaç

- Standart `registry:2` yerine kurumsal ortamlarda neden **Harbor Enterprise Registry** tercih edildiğini kavramak.
- Rol Tabanlı Erişim Denetimi (RBAC), Proje Kotaları ve Değiştirilemez Etiket (Tag Immutability) kurallarını öğrenmek.
- CI/CD (Jenkins, GitLab CI) süreçleri için kısıtlı yetkili **Robot Hesapları (Robot Accounts)** oluşturmak.
- Dahili **Trivy** güvenlik tarayıcısı ile registry'ye yüklenen imajlardaki CVE zafiyetlerini otomatik denetlemek.

---

## Ön Koşullar

- LAB-DOC-06-01 tamamlanmış olmalıdır.
- Platform Harbor servisinin (`18444`) aktif olması (`docker ps | grep harbor`).

---

## Mimari ve Güvenlik Modeli

```text
[Geliştirici / CI/CD Robotu]
            │
            ├── 1. docker login harbor.domain:18444 (Robot Token)
            ├── 2. docker push harbor.domain:18444/prod/app:v1.0
            ▼
+───────────────────────────────────────────────────────────────+
| HARBOR ENTERPRISE PLATFORMU (:18444)                          |
|                                                               |
|  [ harbor-core / portal ]  ──> RBAC & Proje İzolasyonu        |
|  [ registry ]              ──> OCI Uyumlu Katman Deposu       |
|  [ trivy-adapter ]         ──> 🛡️ OTOMATİK ZAFİYET TARAMASI    |
|                                (HIGH/CRITICAL CVE varsa durdur|
|  [ tag-immutability ]      ──> 'v1.0' etiketinin ezilmesini engelle|
+───────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Harbor Mimarisi ve Proje Oluşturma
Harbor web arayüzünde (veya API üzerinden):
1. `devops-team` adında **Private** bir proje oluşturun.
2. Proje ayarlarından **Automatically scan images on push** (İmaj yüklendiğinde otomatik tara) seçeneğini aktif edin.
3. **Tag Immutability:** `v*` formatındaki etiketlerin silinmesini veya üzerine yazılmasını engelleyen kural tanımlayın.

### 2. CI/CD Robot Hesabı Üretme
1. Proje sekmesinden **Robot Accounts** menüsüne gidin.
2. `robot-cicd-pusher` adında yeni bir hesap açıp sadece `Push Image` ve `Pull Image` izinleri verin.
3. Üretilen gizli token'ı güvenli bir yere kaydedin.

### 3. Docker CLI ile Robot Girişi ve İmaj Gönderme
```bash
# 1. Robot hesabı ile giriş yapın:
# docker login 127.0.0.1:18444 -u "robot$robot-cicd-pusher" -p "<TOKEN>"

# 2. İmajı kurumsal proje yoluyla etiketleyin:
# docker tag my-app:1.0 127.0.0.1:18444/devops-team/my-app:v1.0

# 3. İmajı depoya yükleyin:
# docker push 127.0.0.1:18444/devops-team/my-app:v1.0
```

### 4. Trivy Zafiyet Raporunu İnceleme
Harbor arayüzünde yüklenen imajın yanında beliren güvenlik raporuna tıklayın:
- `CRITICAL`, `HIGH`, `MEDIUM` CVE listesini ve düzeltme sürümlerini (Fixed in) inceleyin.

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
# Harbor API üzerinden proje listesini sorgulayın:
curl -s http://127.0.0.1:18444/api/v2.0/projects
```

---

## Temizlik

Laboratuvarda push edilen test imajını Harbor Web UI üzerinden `devops-team` projesinden silebilirsiniz:
```bash
docker rmi 127.0.0.1:18444/devops-team/my-app:v1.0 2>/dev/null || true
```
