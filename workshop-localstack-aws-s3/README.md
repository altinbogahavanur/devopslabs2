# ☁️ İleri Seviye Atölye: Docker ile LocalStack Üzerinde Sıfır Maliyetli AWS S3 ve Python Backend Entegrasyonu

| Seviye | Profil / Araçlar | Açık Host Portları |
| --- | --- | :---:|
| İleri / Workshop | `docker compose`, `localstack:3.8`, `amazon/aws-cli`, `python:3.12`, `boto3`, `FastAPI` | `4566`, `19001` |

---

## 🎯 Labın Amacı

Bu atölye çalışmasında; gerçek bir AWS hesabı açmadan, kredi kartı bağlamadan veya bulut faturası ödeme riski taşımadan:
1. Docker Compose ile yerel bir **LocalStack (AWS Cloud Emulator)** servisini ayağa kaldırmak,
2. **AWS CLI** (ana makineye hiçbir şey kurmadan Docker üzerinden `amazon/aws-cli`) ile yerel S3 üzerinde bucket oluşturup dosya yüklemek (`s3 mb`, `s3 cp`, `s3 ls`),
3. **Python (FastAPI + Boto3)** ile geliştirilmiş modern bir mikroservisi bu yerel S3 servisine bağlayarak nesne depolama (Object Storage) operasyonlarını uçtan uca yürütmek ve Swagger arayüzünden test etmektir.

---

## 🏛️ Mimari ve Çalışma Modeli

```text
[GELİŞTİRİCİ / TEST İSTEMCİSİ]
         │
         ├─── [1. CLI Yolu] ────> amazon/aws-cli (Konteyner)
         │                         │ (AWS S3 Komutları)
         │                         ▼
         │                 ┌────────────────────────────────┐
         │                 │ LOCALSTACK (Port: 4566)        │
         │                 │ - Yerel AWS S3 Motoru          │
         │                 │ - Bucket: devops-training-bucket│
         │                 └────────────────────────────────┘
         │                                 ▲
         │                                 │ (boto3: endpoint_url="http://localstack:4566")
         │                                 │
         └─── [2. API Yolu] ────> PYTHON FASTAPI BACKEND (Port: 19001)
                                   - GET  /health (S3 bağlantı testi)
                                   - GET  /buckets
                                   - POST /upload-text
                                   - GET  /files
                                   - GET  /files/{filename}
                                   - GET  /docs (Swagger UI)
```

---

## 📋 Ön Koşullar & Açık Portlar

* Docker Engine ve Docker Compose v2 (`docker compose version`).
* Host üzerinde açık olması gereken portlar:
  * **Port 4566:** LocalStack AWS Gateway portu.
  * **Port 19001:** Backend API (App1 Slotu) ve Swagger UI.

---

## 🚀 Adım Adım Uygulama

### 1. Adım: Çalışma Dizinine Geçiş
```bash
cd ~/docker-labs/workshop-localstack-aws-s3
ls -la
```

### 2. Adım: Docker Compose Yapılandırmasını İnceleyin
`docker-compose.yaml` dosyasında LocalStack'in S3 servisini nasıl açtığını ve backend servisinin çevre değişkenlerini (`AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) inceleyin:

```bash
cat docker-compose.yaml
```

### 3. Adım: Stack'i Ayağa Kaldırın
```bash
docker compose up -d --build
```

Konteynerlerin sağlık durumunu denetleyin:
```bash
docker compose ps
```
*Gözlem:* `localstack-aws` konteynerinin `healthy` duruma geçmesini bekleyin (yaklaşık 10-15 saniye).

LocalStack sağlık endpoint'ini host üzerinden sorgulayın:
```bash
curl -s http://localhost:4566/_localstack/health | grep '"s3": "available"'
```

---

### 4. Adım: AWS CLI ile Yerel S3 Operasyonları (Host'a Araç Kurmadan!)

Ana makinenize AWS CLI kurmanıza gerek yoktur. Resmi `amazon/aws-cli` imajını aynı Docker ağına bağlayarak çalıştırabilirsiniz:

```bash
# 1. Hazır betiği çalıştırarak bucket açın ve test dosyası yükleyin:
./scripts/init-s3.sh
```

**İşlemi Manuel Olarak Yürütmek İsterseniz:**

```bash
# S3 Bucket oluşturma:
docker run --rm --network localstack-aws-net \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli --endpoint-url=http://localstack:4566 s3 mb s3://devops-training-bucket

# S3 içine dosya kopyalama:
echo "LocalStack S3 Testi" > /tmp/test.txt
docker run --rm --network localstack-aws-net -v /tmp:/data \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli --endpoint-url=http://localstack:4566 s3 cp /data/test.txt s3://devops-training-bucket/

# S3 içeriğini listeleme:
docker run --rm --network localstack-aws-net \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli --endpoint-url=http://localstack:4566 s3 ls s3://devops-training-bucket/
```

*(Eğer ana makinenizde yerel `aws` komutu kuruluysa: `aws --endpoint-url=http://localhost:4566 s3 ls s3://devops-training-bucket/` komutunu doğrudan kullanabilirsiniz).*

---

### 5. Adım: Python Backend Üzerinden S3 Entegrasyonu

Backend konteyneri `boto3` kütüphanesini kullanır ve doğrudan LocalStack S3'e bağlanır:

#### A. Otomatik Test Betiği
```bash
./scripts/test-backend.sh
```

#### B. Manuel curl İstekleri ile Test
```bash
# 1. Sağlık kontrolü:
curl http://localhost:19001/health

# 2. Mevcut bucket'ları listeleme:
curl http://localhost:19001/buckets

# 3. Backend üzerinden S3'e yeni dosya yükleme:
curl -X POST http://localhost:19001/upload-text \
  -F "filename=sunucu-raporu.txt" \
  -F "content=CPU: Normal, RAM: 4GB, Docker: Aktif"

# 4. S3 içindeki dosyaları listeleme:
curl http://localhost:19001/files

# 5. S3'ten dosya içeriğini çekme:
curl http://localhost:19001/files/sunucu-raporu.txt
```

#### C. Web Tarayıcısı ve Swagger Arayüzü
Tarayıcınızı açıp aşağıdaki adrese gidin:
* **Swagger UI:** `http://<SUNUCU-IP>:19001/docs` (veya `http://localhost:19001/docs`)
* Buradan tüm S3 operasyonlarını görsel arayüz üzerinden `Try it out` butonlarıyla test edebilirsiniz.

---

## ✅ Doğrulama (Verification)

1. `docker compose ps` komutunda hem `localstack-aws` hem de `localstack-s3-backend` konteynerlerinin `Up` ve `healthy` durumda olduğunu doğrulayın.
2. `curl http://localhost:19001/health` çıktısının `{"status":"healthy","s3_connection":"connected"}` döndüğünü teyit edin.
3. `curl http://localhost:19001/files` çıktısında yüklediğiniz dosyaların listelendiğini görün.

---

## 🧹 Temizlik

Laboratuvarı tamamladıktan sonra tüm kaynakları ve geçici LocalStack diskini temizlemek için:

```bash
./scripts/cleanup.sh
```
*(veya manuel olarak `docker compose down -v`)*
