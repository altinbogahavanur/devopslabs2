# * LAB-11: Kaynak Sınırlandırma (cgroups v2) ve OOMKilled Teşhisi

## 🎯 Labın Amacı
Üretim ortamında bir konteynerin kontrolsüz CPU ve bellek (RAM) tüketerek tüm sunucuyu kilitlemesini engellemek; Linux Kernel **Control Groups (cgroups v2)** ile kaynak kotaları koymak, kasıtlı bellek sızıntısı ile **Exit Code 137 (OOMKilled)** durumunu tetiklemek ve adli bilişim (forensic) teftişi yapmak.

## 📋 Ön Koşullar
- Docker Engine çalışır durumda olmalıdır.

---

## 🚀 Adım Adım Uygulama

### 1. CPU ve Bellek Kotalarını Belirleme
```bash
# Lab çalışma dizinine geçin:
cd ~/docker-labs/lab-11-cgroups-resource-limits-and-oom

# Konteyneri maksimum 128 MB RAM ve 0.5 CPU (Yarım çekirdek) ile sınırlandırın:
docker run -d --name limited-nginx \
  --memory=128m \
  --memory-swap=128m \
  --cpus=0.5 \
  nginx:alpine

# Konteynerin canlı kaynak limitlerini denetleyin:
docker stats --no-stream limited-nginx
```

### 2. Kasıtlı Bellek Sızıntısı Simülasyonu (stress-app)
Lab dizinindeki Python uygulaması belleğe sürekli veri basarak kotayı aşmaya çalışır:

```bash
# stress-app dizinine geçin:
cd ~/docker-labs/lab-11-cgroups-resource-limits-and-oom/stress-app
cat stress.py
```

Uygulamayı 50 MB bellek limiti ile çalıştırın:
```bash
# İmajı derleyin:
docker build -t oom-stress:1.0 .

# 50 MB RAM sınırı ile başlatın:
docker run --name stress-victim --memory=50m --memory-swap=50m oom-stress:1.0
```

### 3. Exit Code 137 ve OOM-Killer Tetiklenmesi
Konteyner 50 MB sınırına ulaştığı anda Linux çekirdeği (Kernel OOM-Killer) devreye girer ve sürece `SIGKILL` (9) gönderir:

```bash
# Konteynerin çıkış kodunu kontrol edin (128 + 9 = 137):
docker ps -a | grep stress-victim
# Durum: Exited (137) görünmelidir.
```

### 4. Adli İnceleme (Forensic Inspection)
```bash
# Docker'ın OOM kaydını doğrudan JSON içinden sorgulayın:
docker inspect -f 'OOMKilled: {{.State.OOMKilled}}, ExitCode: {{.State.ExitCode}}' stress-victim
# Beklenen Çıktı: OOMKilled: true, ExitCode: 137

# Kernel dmesg loglarında OOM-Killer kaydını arayın (Linux VM'lerde):
dmesg -T 2>/dev/null | grep -i -E "oom[-_]killer|killed process" | tail -n 5 || true
```

---

## ✅ Doğrulama (Verification)
- `docker inspect -f '{{.State.OOMKilled}}' stress-victim` komutunun `true` döndürdüğünü doğrulayın.

---

## 🧹 Temizlik
```bash
docker rm -f limited-nginx stress-victim 2>/dev/null || true
docker rmi oom-stress:1.0 2>/dev/null || true
```
