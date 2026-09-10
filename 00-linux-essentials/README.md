# LAB-00 — Temel Linux Becerileri, Sunucu Hazırlığı ve 16 GB Swap Yapılandırması

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 45 dakika | `bash`, `apt`, `procps`, `iproute2` | `22` |

---

## 1. Amaç

Bu laboratuvarın amacı; Docker ve konteyner platformlarını çalıştırmadan önce **Ubuntu Linux sunucusunu kurumsal üretime hazırlamak**, temel Linux sistem yönetimi becerilerini kazanmak ve donanım kaynaklarını optimize etmektir:

1. **Sunucu Donanım Kısıtı:** 16 GB RAM, 4 vCPU ve 100 GB diskli tek bir sunucuda çalışılacaktır. İlerleyen aşamalarda GitLab, Jenkins, Harbor veya Spring Boot gibi ağır iş yükleri açıldığında bellek kilitlenmesi (OOM - Out Of Memory) yaşamamak için **16 GB Swap Alanı** yapılandırmak.
2. **Temel Linux İşlemleri:** Dosya/klasör yönetimi, `apt` paket yönetimi, süreç yönetimi (`ps`, `top`, `htop`), arşivleme (`tar`, `gzip`, `unzip`).
3. **Güvenlik ve Yetki:** `sudo` yetkili kullanıcı oluşturma, root yerine standart kullanıcı ile çalışma, SSH anahtar (`ssh-keygen`, `authorized_keys`) güvenliği.
4. **Preflight Denetimi:** Ağ portlarının (`ss -tulpn`) ve disk durumunun (`df -hT`) denetlenmesi.

---

## 2. Ön Koşullar

* Ubuntu 22.04 veya 24.04 LTS kurulu sunucu erişimi.
* `sudo` yetkisine sahip kullanıcı oturumu.
* En az 25 GB boş disk alanı (`df -h /`).

---

## 3. Mimari ve Çalışma Modeli

```text
+─────────────────────────────────────────────────────────────────────────────+
|                         UBUNTU SUNUCU DONANIMI                              |
|   - 4 vCPU (x86_64 / ARM64)                                                 |
|   - 16 GB Fiziksel Bellek (RAM)                                             |
|   - 100 GB SSD Disk                                                         |
+─────────────────────────────────────────────────────────────────────────────+
                                      │
            KAYNAK ESNETME (SWAP) & GÜVENLİK YAPILANDIRMASI
                                      ▼
+───────────────────────────────────+   +─────────────────────────────────────+
| BELLEK ESNETME: 16 GB SWAP ALANI  |   | GÜVENLİ KULLANICI & SSH             |
| - /swapfile (16 GB - chmod 600)   |   | - devops kullanıcısı (sudo grubu)   |
| - vm.swappiness = 10              |   | - ~/.ssh/authorized_keys (700/600)  |
| - /etc/fstab (Yeniden Başlatmada) |   | - Root oturumu yerine anahtar ile   |
| - Efektif Bellek: 16+16 = 32 GB!  |   |   şifresiz güvenli bağlantı         |
+───────────────────────────────────+   +─────────────────────────────────────+
```

---

## 4. Görevler (Tasks)

1. **Paket Listesi ve Temel Araçlar:** Sunucu paket listesini güncelleyin (`sudo apt update`) ve temel DevOps araçlarını (`curl`, `wget`, `git`, `htop`, `procps`, `iproute2`, `net-tools`, `unzip`, `tar`) kurun.
2. **Dosya ve Dizin Operasyonları:** `/tmp/devops-test` altında `logs`, `data` ve `config` dizinleri oluşturup içine örnek yapılandırma dosyaları ekleyin; ardından bu yapıyı `tar.gz` formatında sıkıştırın ve başka bir test dizinine açın.
3. **16 GB Swap Alanı Tahsisi:** `fallocate` ile 16 GB `/swapfile` tahsis edin, dosya yetkisini `600` yapın, Linux Swap formatına biçimlendirip (`mkswap`) aktif edin (`swapon`).
4. **Kalıcılık ve Performans:** Swap alanının yeniden başlatmalarda korunması için `/etc/fstab` dosyasına ekleyin; `vm.swappiness` değerini `10` yaparak diske gereksiz yazmayı sınırlandırın.
5. **Güvenli DevOps Kullanıcısı:** Root oturumu yerine `devops` adında sudo yetkili bir kullanıcı oluşturun ve SSH anahtar dizini (`~/.ssh`) izinlerini yapılandırın (`700`/`600`).
6. **Preflight Doğrulama:** `free -h`, `swapon --show`, `ss -tulpn` ve `df -hT` ile sistem kaynaklarını denetleyin.

---

## 5. İpuçları

<details>
<summary>💡 İpucu 1: Fallocate vs dd</summary>

Bazı dosya sistemlerinde (örneğin XFS veya eski ext4) `fallocate` komutu swap için blok tahsisinde hata verebilir. Bu durumda `sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress` komutu kesin ve güvenli alternatiftir.
</details>

<details>
<summary>💡 İpucu 2: Port Çakışmalarını Tespit Etme</summary>

Docker kurmadan önce 80 veya 443 gibi portların başka bir yerel servis (Apache, eski Nginx vb.) tarafından dinlenip dinlenmediğini kontrol etmek için `sudo ss -tulpn | grep -E ':80|:443'` komutu kullanılır.
</details>

<details>
<summary>💡 İpucu 3: Swappiness Mantığı</summary>

`vm.swappiness` değeri Linux çekirdeğinin RAM ne kadar dolduğunda swap diskine yazmaya başlayacağını belirler (0-100 arası). Varsayılan 60 sunucu için erkendir; `10` değeri yalnızca fiziksel RAM %90 dolduğunda swap'e geçilmesini sağlayarak disk I/O darboğazını önler.
</details>

---

## 6. Doğal Doğrulama ve Beklenen Sonuç

Aşağıdaki komutlarla sistemin Docker kurulumuna hazır olduğunu teyit edin:

```bash
# 1. Swap alanının doğrulanması
swapon --show

# 2. Toplam bellek ve swap kontrolü
free -h

# 3. Swappiness ayarı
sysctl vm.swappiness

# 4. Dinleyen kritik servislerin kontrolü
ss -tulpn
```

* **Beklenen Başarı Çıktısı:**
  * `swapon --show` çıktısında `/swapfile` 16G görünmelidir.
  * `free -h` çıktısında `Swap: 16Gi` görünmelidir.
  * `sysctl vm.swappiness` sonucu `vm.swappiness = 10` olmalıdır.
  * Kök dizinde (`/`) en az **25+ GB** boş alan bulunmalıdır.

---

## 7. Temizlik

Laboratuvarda oluşturulan geçici arşiv ve test dizinlerini temizleyin (Kurulan Swap alanı ve `devops` kullanıcısı sonraki tüm laboratuvarlar için korunmalıdır):

```bash
rm -rf /tmp/devops-test /tmp/restore-test /tmp/devops-yedek.tar.gz
```
