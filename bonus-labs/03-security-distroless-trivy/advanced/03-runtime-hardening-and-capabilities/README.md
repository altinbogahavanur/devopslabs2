# LAB-DOC-09-03 (Advanced) — Konteyner Sertleştirme (Runtime Hardening) ve Linux Yetenekleri

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Uzman | `docker-ce`, `capabilities`, `read-only`, `security-opt` | 8080 |

---

## Amaç

- Konteynerlerin varsayılan Linux çekirdek yeteneklerini sıfırlamak (`--cap-drop=ALL`).
- Dosya sistemini değiştirilemez (salt-okunur) yaparak kötü amaçlı yazılım indirilmesini engellemek (`--read-only`).
- Sadece gereken geçici dizinleri bellekte açmak (`--tmpfs /tmp:rw,noexec,nosuid`).
- SUID ikili dosyalarıyla yetki yükseltilmesini yasaklamak (`--security-opt=no-new-privileges:true`).

---

## Ön Koşullar

- LAB-DOC-09-01 ve 02 tamamlanmış olmalıdır.
- Host üzerinde `8080` portu boşta olmalıdır.

---

## Mimari ve Sertleştirme Modeli

```text
+───────────────────────────────────────────────────────────────────+
| SERTLEŞTİRİLMİŞ (HARDENED) KONTEYNER                              |
|  - User: UID 10001 (Non-root, host üzerinde yetkisiz)             |
|  - Rootfs: Read-Only (Diske hiçbir dosya yazılamaz) 🔒            |
|  - Tmpfs: /tmp:rw,noexec,nosuid (Sadece RAM'de geçici izin)       |
|  - Capabilities: --cap-drop=ALL (Tüm kernel yetkileri kapalı)     |
|  - Security Opt: no-new-privileges:true (Yetki yükseltme bloke)   |
+───────────────────────────────────────────────────────────────────+
```

---

## Adım Adım Uygulama Rehberi

### 1. Güvenli Nginx Yapılandırması Hazırlama
Standart Nginx root olarak başlar ve `/var/run` dizinine yazar. Non-root ve salt-okunur çalışması için yolları `/tmp` dizinine yönlendirelim:

```bash
mkdir -p /tmp/hardened-demo && cd /tmp/hardened-demo

cat <<'EOF' > nginx.conf
pid /tmp/nginx.pid;
events { worker_connections 1024; }
http {
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;
    server {
        listen 8080;
        location / {
            return 200 '{"security":"Hardened Runtime Aktif"}\n';
            add_header Content-Type application/json;
        }
    }
}
EOF
```

### 2. Hardened Dockerfile
```bash
cat <<'EOF' > Dockerfile
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
USER 10001:10001
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
EOF
```

### 3. İmajı Derleme ve Güvenlik Bayraklarıyla Başlatma
```bash
docker build -t nginx-hardened:1.0 .

# Ultra güvenli parametrelerle başlatın:
docker run -d --name secure-web \
  -p 8080:8080 \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop=ALL \
  --security-opt=no-new-privileges:true \
  nginx-hardened:1.0

# Servisi test edin:
curl http://localhost:8080
```

### 4. Güvenlik Kısıtlarını Test Etme
```bash
# 1. Dosya sistemine yazma denemesi (Read-only file system hatası vermelidir!):
docker exec secure-web touch /etc/hacked.txt 2>&1 || true

# 2. Yetki yükseltme ve kernel yetkilerini denetleme:
docker inspect -f 'CapDrop: {{.HostConfig.CapDrop}} | ReadonlyRootfs: {{.HostConfig.ReadonlyRootfs}}' secure-web
```

---

## Doğal Doğrulama ve Beklenen Sonuç

```bash
docker inspect -f '{{.HostConfig.ReadonlyRootfs}}' secure-web
# Çıktı 'true' olmalıdır.
docker inspect -f '{{.HostConfig.CapDrop}}' secure-web
# Çıktı '[ALL]' olmalıdır.
```

---

## Temizlik

```bash
docker rm -f secure-web 2>/dev/null || true
docker rmi nginx-hardened:1.0 2>/dev/null || true
rm -rf /tmp/hardened-demo
```
