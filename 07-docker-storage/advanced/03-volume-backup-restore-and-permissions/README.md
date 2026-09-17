# LAB-DOC-07-03 (Advanced) — Volume İzinleri (UID/GID Mismatch) ve Veri Göçü

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| İleri | `docker-ce`, `node:alpine`, `chown` | - |

---

## Amaç

- Kurumsal üretimde en sık karşılaşılan **"Permission Denied"** hatasının (Host UID/GID ile Konteyner UID/GID uyuşmazlığı) kök nedenini anlamak.
- Güvenlik gereği `non-root` (örneğin UID 10001) çalışan bir konteynerın host bind mount dizinine nasıl sorunsuz yazmasını sağlayabileceğimizi öğrenmek.
- `--user $(id -u):$(id -g)` bayrağını doğru uygulamak.

---

## Ön Koşullar

- LAB-DOC-07-01 ve 02 tamamlanmış olmalıdır.

---

## Mimari ve İzin Çakışma Modeli

```text
HOST DİZİNİ: /tmp/app-data (Sahibi: hakan - UID: 1000)
                    │
                    ▼ (Bind Mount)
KONTEYNER SÜRECİ: node (Çalışan: appuser - UID: 10001)
                    │
                    ▼
          💥 ERROR: EACCES: permission denied, open '/data/log.txt'
                    │
                    ▼
     ÇÖZÜM: chown -R 10001:10001 veya docker run --user $(id -u):$(id -g)
```

---

## Adım Adım Uygulama Rehberi

### 1. Yetki Reddi Hatasını (Permission Denied) Simüle Etme
```bash
# 1. Host üzerinde root sahipliğinde bir dizin oluşturun:
sudo mkdir -p /tmp/locked-data
sudo chmod 755 /tmp/locked-data

# 2. Non-root (UID 1000) bir konteyner ile bu dizine yazmayı deneyin:
docker run --rm -u 1000:1000 -v /tmp/locked-data:/data alpine \
  sh -c "echo test > /data/file.txt" 2>&1 || true
# HATA: Permission denied!
```

### 2. Çözüm 1: Dizin Sahipliğini Konteyner Kullanıcısına Eşitleme
```bash
# Host üzerindeki dizin sahipliğini konteynerın UID değerine verin:
sudo chown -R 1000:1000 /tmp/locked-data

# Şimdi yazma işlemini tekrar deneyin:
docker run --rm -u 1000:1000 -v /tmp/locked-data:/data alpine \
  sh -c "echo 'Basariyla Yazildi' > /data/file.txt"

cat /tmp/locked-data/file.txt
```

### 3. Çözüm 2: Çalışma Zamanında Host Kullanıcı Kimliğini Enjekte Etme
```bash
# Geliştiricinin kendi UID/GID değerini konteynere aktarması:
docker run --rm --user "$(id -u):$(id -g)" -v /tmp/locked-data:/data alpine \
  sh -c "touch /data/host-matched.txt"

ls -l /tmp/locked-data/host-matched.txt
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
ls -l /tmp/locked-data/file.txt
# Dosya izinlerinde yazma işlemi başarıyla tamamlanmış olmalıdır.
```

---

## Temizlik

```bash
sudo rm -rf /tmp/locked-data
```
