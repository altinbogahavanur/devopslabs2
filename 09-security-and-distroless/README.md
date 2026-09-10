# LAB-09 — Üretim Seviyesi Güvenlik, Distroless, Konteyner Sertleştirme (Hardening) ve Trivy Taraması

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri / Uzman | 60 dakika | `distroless`, `trivy`, `cgroups v2`, `tini` | `8080` |

---

## Savunma Derinliği ve Sertleştirme Mimarisi

```text
                     SALDIRGAN / GÜVENLİK TEHDİDİ
                                  │
                                  ▼
+─────────────────────────────────────────────────────────────────────────────+
| 1. DİSTROLESS VE SHELL-LESS İMAJ (gcr.io/distroless/static-debian12)        |
|    - 'sh' veya 'bash' YOKTUR! Saldırgan reverse shell açamaz.               |
+─────────────────────────────────────────────────────────────────────────────+
                                  │
                                  ▼
+─────────────────────────────────────────────────────────────────────────────+
| 2. NON-ROOT KULLANICI (UID 10001)                                           |
|    - Konteynerdan kaçış olsa bile host makinede root olunamaz.              |
+─────────────────────────────────────────────────────────────────────────────+
                                  │
                                  ▼
+─────────────────────────────────────────────────────────────────────────────+
| 3. SALT-OKUNUR DOSYA SİSTEMİ (--read-only)                                  |
|    - Dosya sistemine zararlı yazılım (.sh, malware) indirilemez / yazılamaz.|
|    - Sadece geçici /tmp dizini RAM üzerinde (tmpfs) açılır.                 |
+─────────────────────────────────────────────────────────────────────────────+
                                  │
                                  ▼
+─────────────────────────────────────────────────────────────────────────────+
| 4. LINUX CAPABILITIES DÜŞÜRME (--cap-drop=ALL)                              |
|    - Raw soket açma, sistem saatini değiştirme gibi kernel yetkileri kapalı.|
+─────────────────────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama

### Adım 1: Sertleştirilmiş Konteyneri Başlatma

```bash
# Sertleştirilmiş stack'i ayağa kaldırma
docker compose up -d
docker compose ps
```

---

### Adım 2: Güvenlik ve Sertleştirme Kısıtlarını Test Etme

```bash
# 1. Çalışan kullanıcı kimliğini sorgulama (UID 10001 dönmelidir)
docker exec hardened-app id

# 2. Salt-okunur dosya sistemine yazma denemesi (Read-only file system hatası vermelidir)
docker exec hardened-app touch /root/evil.sh || echo "Yazma engellendi: Dosya sistemi salt-okunur!"

# 3. RAM tabanlı geçici /tmp dizinine yazma testi (Başarılı olmalıdır)
docker exec hardened-app touch /tmp/legit.log && echo "Geçici log RAM üzerine başarıyla yazıldı."
```

---

### Adım 3: Bellek Sınırı ve OOMKilled (Exit Code 137) Simülasyonu

128 MB RAM sınırı tanımlanmış konteynerde bellek aşımı simülasyonu yapın:

```bash
# Sınırı aşan bellek yükü çalıştırma
docker run --name oom-demo -m 128m --memory-swap 128m -e MEMORY_MB=256 ghcr.io/devopsatolyesi/stress-tester:v1 || true

# Linux kernel tarafından atanan çıkış kodunu okuma (137 dönmelidir)
docker inspect -f 'OOMKilled: {{.State.OOMKilled}} - ExitCode: {{.State.ExitCode}}' oom-demo
```

---

### Adım 4: PID 1 Problemi ve Tini ile Zarif Kapanma (Graceful Shutdown)

```bash
# Tini init yöneticisi kullanan imajı çalıştırma
docker run -d --name graceful-demo app/Dockerfile.tini 2>/dev/null || true

# SIGTERM sinyaline anında (0.2s) yanıt verdiğini doğrulama
time docker stop hardened-app
```

---

### Adım 5: Trivy ile İmaj Zafiyet Taraması

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --severity HIGH,CRITICAL python:3.12-slim
```

---

## Temizlik

Laboratuvar kaynaklarını temizleyin:

```bash
docker compose down 2>/dev/null || true
docker rm -f oom-demo graceful-demo 2>/dev/null || true
```
