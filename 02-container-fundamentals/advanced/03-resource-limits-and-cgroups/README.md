# LAB-DOC-02-03 (Advanced) — Kaynak Sınırları, Cgroups v2 ve OOMKilled Teşhisi

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker-ce`, `cgroups-v2`, `stress` | - |

---

## Amaç

- Konteynerların ana makine (host) CPU ve RAM kaynaklarını tüketip sistemi kilitlemesini önlemek.
- `--memory`, `--memory-swap` ve `--cpus` sınırlarını uygulamalı olarak belirlemek.
- Bellek sınırını aşan bir uygulamanın Linux çekirdeği tarafından öldürülmesini (OOMKilled) tetiklemek.
- `docker inspect` ile **Exit Code 137** (128 + SIGKILL 9 = 137) hatasını teşhis etmek.

---

## Ön Koşullar

- LAB-DOC-02-01 ve 02 tamamlanmış olmalıdır.
- Temel cgroups v2 desteğine sahip Linux ortamı.

---

## Mimari ve Çalışma Modeli

```text
[Host Belleği: 16 GB]
       │
       ▼ (cgroups v2 Kısıtlaması: --memory 64m)
+───────────────────────────────────────────────+
| Konteyner Bellek Alanı: 64 MB                 |
|                                               |
| [Uygulama: 40 MB]  ➔  [Kullanım: 60 MB]       |
|                                 │             |
|                                 ▼             |
|                  [TALEP: 100 MB RAM]          |
|                                 │             |
|                                 ▼             |
|              💥 LINUX OOM-KILLER DEVREDE!     |
|              - Sinyal: SIGKILL (9)            |
|              - Durum: OOMKilled: true         |
|              - Çıkış Kodu: 137                |
+───────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Bellek Sınırı Belirleme ve Güvenli Çalıştırma
```bash
# Konteyneri 128 MB RAM ve 0.5 CPU çekirdeği ile sınırlandırarak başlatın:
docker run -d --name limited-nginx --memory 128m --cpus 0.5 -p 8082:80 nginx:alpine

# Konteynerın kaynak limitlerini denetleyin:
docker stats --no-stream limited-nginx

docker rm -f limited-nginx
```

### 2. OOMKilled Senaryosu (Aşırı Bellek Tüketimi Simülasyonu)
```bash
# 64 MB RAM sınırı koyduğumuz konteynerda, 120 MB bellek tahsis etmeye çalışan bir python kodu çalıştıralım:
docker run --name oom-victim --memory 64m python:3.12-alpine \
  python3 -c "a = 'x' * (120 * 1024 * 1024)" 2>&1 || true
```

### 3. Exit Code 137 ve OOM Teşhisi
```bash
# 1. Konteynerın durumunu ve çıkış kodunu listeleyin:
docker ps -a | grep oom-victim

# 2. docker inspect ile OOMKilled bayrağını ve ExitCode'u kesinleştirin:
docker inspect -f 'ExitCode: {{.State.ExitCode}} | OOMKilled: {{.State.OOMKilled}}' oom-victim
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker inspect -f '{{.State.OOMKilled}}' oom-victim
# Çıktı: 'true' olmalıdır.
docker inspect -f '{{.State.ExitCode}}' oom-victim
# Çıktı: '137' olmalıdır.
```

---

## Temizlik

```bash
docker rm -f oom-victim 2>/dev/null || true
```
