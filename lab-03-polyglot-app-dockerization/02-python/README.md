# LAB-DOC-03-02 — Python Uygulamasını Üretime Hazır Dockerize Etme

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Temel - Orta | `python:3.12-slim`, `pip`, `curl` | 8000 |

---

## 1. Uygulama Hakkında

Bu laboratuvarda, `app/main.py` içinde yer alan ve REST endpoint'leri sunan modern bir Python mikroservisi yer almaktadır.

Python uygulamalarını Dockerize ederken en sık yapılan hatalar:
* İmaj içinde gereksiz `.pyc` bytecode önbellek dosyaları oluşturmak,
* Python'un logları buffer'da (arabellekte) tutup anında stdout'a yazmaması,
* Root kullanıcısı ile konteyner çalıştırmak,
* `pip install` önbellek dosyalarını imaj içinde bırakıp imajı şişirmektir.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Kurulum ve Çalıştırma

Öğrencinin Dockerfile direktiflerini kurgulayabilmesi için referans Linux akışı:

```bash
# 1. Python 3 ve pip ortamının kurulması
sudo apt update && sudo apt install -y python3 python3-pip

# 2. Çalışma dizininin açılması ve kodların yerleşimi
mkdir -p /app && cd /app
cp -r /path/to/source/* /app/

# 3. Bağımlılıkların kurulması
pip install --no-cache-dir -r requirements.txt

# 4. Ortam değişkenleri (Bytecode üretmeme ve logları anında akıtma)
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1
export PORT=8000

# 5. Standart kullanıcı ile uygulamanın başlatılması
python3 app/main.py
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| Python Kurulumu | `FROM python:3.12-slim` | Tam Ubuntu yerine hafif Debian tabanlı `slim` imaj |
| Ortam Değişkenleri | `ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1` | Logların anında `docker logs` ile görünmesi için hayati kural |
| `cd /app` | `WORKDIR /app` | Standart uygulama kök dizini |
| Bağımlılık Dosyası | `COPY requirements.txt .` | Kod değiştiğinde pip adımı önbellekten (`CACHED`) gelsin |
| `pip install` | `RUN pip install --no-cache-dir ...` | `--no-cache-dir` ile geçici dosyalar imaja yazılmaz |
| Kullanıcı Oluşturma | `RUN useradd -u 10001 appuser` | Root yerine kısıtlı Linux kullanıcısı |
| `USER appuser` | `USER appuser` | Non-root çalışma zamanı |
| Başlatma | `CMD ["python", "app/main.py"]` | Exec Form ile sinyal yönetimi |

---

## 4. Görevler (Tasks)

1. `app/main.py` ve `requirements.txt` dosyalarını inceleyin.
2. `PYTHONDONTWRITEBYTECODE=1` ve `PYTHONUNBUFFERED=1` ortam değişkenlerini tanımlayan bir `Dockerfile` hazırlayın.
3. Root olmayan bir kullanıcı (`appuser`) oluşturup yetkilendirin.
4. İmajı `python-devops-api:v1.0` adıyla derleyin.
5. Konteyneri başlatıp `http://localhost:8000/health` adresinden çalıştığını doğrulayın.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: PYTHONUNBUFFERED=1 Neden Önemlidir?</summary>

Varsayılan olarak Python, standart çıktı akışını (`stdout`) biriktirir ve bloklar halinde yazar. `PYTHONUNBUFFERED=1` dendiğinde ise `print()` veya logger çıktıları anında ekrana basılır; böylece `docker logs -f` komutunda loglar gecikmesiz gerçek zamanlı akar.
</details>

<details>
<summary>💡 İpucu 2: Non-Root Kullanıcı UID Seçimi</summary>

Linux sistemlerinde 1000'den küçük UID'ler sistem servislerine ayrılmıştır. Bu nedenle uygulama kullanıcıları için genellikle `10001` gibi 1000'in üzerindeki UID'ler tercih edilir (`useradd -u 10001 appuser`).
</details>

---

## 6. Referans Çözüm

<details>
<summary>🎯 Referans Dockerfile ve Doğrulama Adımları</summary>

**`Dockerfile`:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

# 1. Python runtime ortam optimizasyonları
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# 2. Güvenlik: Non-root kullanıcı oluşturma
RUN useradd -m -u 10001 appuser

# 3. Bağımlılıkları kopyalama ve yükleme (Cache optimize)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Kaynak kodları kopyalama ve izinleri kullanıcıya verme
COPY . .
RUN chown -R appuser:appuser /app

# 5. Non-root kullanıcıya geçiş
USER appuser

EXPOSE 8000

# 6. Uygulamayı başlatma
CMD ["python", "app/main.py"]
```

**Derleme ve Çalıştırma:**
```bash
# 1. İmajı derleme
docker build -t python-devops-api:v1.0 .

# 2. Konteyneri çalıştırma
docker run -d --name my-python-api -p 8000:8000 python-devops-api:v1.0

# 3. Test etme
curl -i http://localhost:8000/health
```
</details>

---

## 7. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:8000/
```

* **JSON Çıktısı:**
```json
{"message": "Python DevOps API Basariyla Calisiyor!", "python_version": "3.12...", "port": 8000}
```
