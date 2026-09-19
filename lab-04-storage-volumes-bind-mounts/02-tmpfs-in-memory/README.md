# LAB-DOC-04-02 — Bellek İçi Depolama: tmpfs Mounts

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta | `docker-ce`, `alpine` | - |

---

## Amaç

- Hassas verilerin (geçici anahtarlar, oturum bilgileri) sunucu diskine yazılmasını engellemek.
- Doğrudan ana makinenin RAM belleği üzerinde çalışan geçici dosya sistemi (`--tmpfs`) tanımlamak.
- Konteyner durduğunda belleğin anında serbest kalmasını ve verinin silinmesini doğrulamak.

---

## Ön Koşullar

- LAB-DOC-04-01 tamamlanmış olmalıdır.

---

## Mimari ve Çalışma Modeli

```text
[Host Fiziksel Belleği (RAM)]
            │
            ▼ --tmpfs /app/secure-temp:size=64m,noexec
+───────────────────────────────────────────────+
| KONTEYNER                                     |
|  - /app/secure-temp (Yalnızca RAM'de yaşar)   |
|  - Diske (SSD/HDD) hiçbir şey yazılmaz!       |
+───────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. tmpfs Mount ile Konteyner Başlatma
```bash
# /secure-cache dizinini 64 MB RAM diski olarak bağlayın:
docker run -d --name memory-app --tmpfs /secure-cache:rw,size=64m,noexec alpine sleep 3600
```

### 2. Dosya Sistemini ve Bellek Bağlantısını Denetleme
```bash
# Konteyner içinde dosya sistemini kontrol edin (tmpfs olarak listelenmelidir):
docker exec memory-app df -hT /secure-cache
```

### 3. RAM Üzerinde Veri Yazma
```bash
# Belleğe geçici bir dosya yazın:
docker exec memory-app sh -c "echo 'Gizli Token' > /secure-cache/secret.txt"
docker exec memory-app cat /secure-cache/secret.txt
```

### 4. Konteyner Yeniden Başladığında Verinin Silinmesi
```bash
# Konteyneri durdurup yeniden başlatın:
docker restart memory-app

# Dosyanın RAM'den tamamen silindiğini teyit edin (No such file):
docker exec memory-app ls /secure-cache
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker exec memory-app df -T /secure-cache | grep "tmpfs"
# Çıktıda Type 'tmpfs' olmalıdır.
```

---

## Temizlik

```bash
docker rm -f memory-app 2>/dev/null || true
```
