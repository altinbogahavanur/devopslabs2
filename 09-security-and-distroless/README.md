# LAB-09 — Üretim Seviyesi Güvenlik, Distroless, Konteyner Sertleştirme (Hardening) ve Trivy/Scout Taraması

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| İleri / Uzman | 60 dakika | `distroless`, `trivy`, `docker scout`, `cgroups v2`, `tini` | `8080` |

---

## 1. Amaç

Bu laboratuvarın amacı (Sunum Slayt 100-101, Lab 7B); çalışan bir konteyneri kurumsal siber güvenlik standartlarına (CIS Docker Benchmark, NIST SP 800-190) uygun hale getirmek, saldırı yüzeyini sıfırlamak ve kaynak tüketimini garantiye almaktır:

1. **Google Distroless Mimarisi:** İçinde hiçbir shell (`bash`, `sh`), paket yöneticisi (`apt`, `apk`) veya gereksiz ikili dosya barındırmayan, saldırganların içine sızsa bile komut çalıştıramayacağı ultra güvenli imajlar üretmek.
2. **Konteyner Sertleştirme (Hardening):**
   * Root kullanıcısını tamamen yasaklama (`USER 10001:10001`).
   * Tüm Linux yetkilerini sıfırlama (`--cap-drop=ALL`).
   * Dosya sistemini değiştirilemez (salt-okunur) yapma (`--read-only`) ve yalnızca bellekte geçici `tmpfs` tahsis etme.
   * Yetki yükseltmeyi (privilege escalation) engelleme (`no-new-privileges:true`).
3. **Güvenlik Açığı Taraması:** **Trivy** ve **Docker Scout** ile imajlardaki CVE açıklarını tespit etmek ve CI/CD güvenlik kapısı kurmak.
4. **Kaynak Limitleri ve OOM Yönetimi:** Linux Cgroups v2 ile bellek sızıntılarını izole etmek ve Exit Code 137 teşhisi yapmak.
5. **PID 1 ve Zarif Kapanma (Graceful Shutdown):** Tini ile `SIGTERM` sinyallerini yakalayıp veri kaybı olmadan temiz kapanma sağlamak.

---

## 2. Ön Koşullar

* Docker Engine çalışır durumda olmalıdır (`docker info`).
* Host üzerinde `8080` portu boşta olmalıdır.
* LAB-03 ve LAB-04 imaj derleme bilgisi.

---

## 3. Savunma Derinliği ve Sertleştirme Mimarisi

```text
                     SALDIRGAN / GÜVENLİK TEHDİDİ
                                  │
                                  ▼
+─────────────────────────────────────────────────────────────────────────────+
| 1. DİSTROLESS VE SHELL-LESS İMAJ (gcr.io/distroless/static-debian12)        |
|    - 'sh' veya 'bash' YOKTUR! Saldırgan reverse shell açamaz.                |
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

## 4. Görevler (Tasks)

1. **Sertleştirilmiş Konteyner İncelemesi:** `docker-compose.yaml` dosyasındaki `read_only`, `tmpfs`, `cap_drop` ve `user` direktiflerini inceleyin; `docker compose up -d` ile servisi ayağa kaldırın.
2. **Konteyner Sertleştirme Denetimi:** `docker exec` ile kök dizine dosya yazmayı deneyerek salt-okunur dosya sistemi (`Read-only file system`) engelini bizzat test edin; çalışan kullanıcının UID 10001 olduğunu kanıtlayın.
3. **Bellek Limiti ve OOMKilled (Exit Code 137) Simülasyonu:** 128 MB RAM sınırı tanımlanmış `stress-app` konteynerini çalıştırarak cgroup bellek aşımı durumunda Linux Kernel'ın konteyneri nasıl izole ettiğini gözlemleyin.
4. **PID 1 ve Tini ile Zarif Kapanma (Graceful Shutdown):** Doğrudan Python çalıştıran konteyner ile `/sbin/tini` öncülüğünde çalışan konteynerin `SIGTERM` sinyallerine tepkisini (`docker stop`) karşılaştırın.
5. **Güvenlik Açığı Taraması (Trivy):** `trivy` aracı ile temel ve sertleştirilmiş imajları tarayarak CVE raporunu inceleyin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Neden /sbin/tini Kullanıyoruz?</summary>

Linux çekirdeğinde PID 1 olan süreç özel bir muamele görür ve varsayılan sinyal işleyicilerini devre dışı bırakır. Eğer uygulamanız kendi içinde `SIGTERM` yakalama kodu yazmadıysa `docker stop` gönderildiğinde 10 saniye bekler ve zorla kesilir (SIGKILL). `tini` gibi hafif bir init yöneticisi PID 1 olduğunda tüm sinyalleri alt çocuk süreçlere kusursuz dağıtır ve zombi süreçleri (zombie processes) temizler.
</details>

<details>
<summary>💡 İpucu 2: Google Distroless İmajlarında Hata Ayıklama</summary>

Distroless imajlarında `sh` veya `bash` olmadığı için `docker exec -it my-app sh` komutu çalışmaz. Eğer test amacıyla kabuk gerekiyorsa Google'ın debug varyantları kullanılır (Örn: `gcr.io/distroless/static-debian12:debug` veya `gcr.io/distroless/java17-debian12:debug`).
</details>

<details>
<summary>💡 İpucu 3: Exit Code 137 Matematiksel Anlamı</summary>

Linux sistemlerinde bir süreç sinyalle sonlandırıldığında çıkış kodu `128 + SİNYAL_NUMARASI` formülüyle hesaplanır. OOM Killer süreci sonlandırmak için `SIGKILL (9)` sinyalini gönderir. Dolayısıyla: `128 + 9 = 137`.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla güvenlik ve cgroup sınırlarının devrede olduğunu teyit edin:

```bash
# 1. Güvenlik bayraklarının denetimi
docker inspect hardened-app | grep -E '"ReadOnlyRootfs"|"CapDrop"|"Memory"'

# 2. OOM durumunun incelenmesi
docker inspect -f 'OOMKilled: {{.State.OOMKilled}} - ExitCode: {{.State.ExitCode}}' oom-demo 2>/dev/null || true
```

* **Beklenen Başarı Kriteri:**
  * `"ReadOnlyRootfs": true`
  * `"CapDrop": ["ALL"]`
  * `"Memory": 268435456` (256 MB)
  * `oom-demo` için `OOMKilled: true - ExitCode: 137`

---

## 7. Temizlik

Laboratuvar tamamlandığında test konteynerlarını ve ortamı temizleyin:

```bash
docker compose down 2>/dev/null || true
docker rm -f oom-demo test-signals 2>/dev/null || true
```
