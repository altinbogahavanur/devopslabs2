# 📚 Docker Komut Rehberi ve Hızlı Başvuru (Docker Cheatsheet)

Modern DevOps ve konteyner mühendisliğinde en sık kullanılan Docker komutlarını işlevlerine göre kategorilere ayıran, tek komutluk kopyalanabilir bloklardan ve gerçek hayat örneklerinden oluşan modüler başvuru kaynağıdır.

---

## 🧭 Konu Başlıklarına Göre Modüler Rehberler

İncelemek istediğiniz konunun detaylı dokümanına aşağıdaki tablodan doğrudan erişebilirsiniz:

| No | Modül / Konu | Açıklama | Dosya Bağlantısı |
|:---:|:---|:---|:---:|
| **01** | **📦 Konteyner Yönetimi** | Konteyner başlatma, yaşam döngüsü (`stop`/`rm`), canlı kabuk (`exec`), loglar, dosya kopyalama (`cp`), canlı kaynak izleme (`stats`) ve `inspect`. | [**01-containers.md**](01-containers.md) |
| **02** | **🖼️ İmaj Yönetimi** | Katmanlı imaj derleme (`build`), multi-stage targets, imaj etiketleme (`tag`), Docker Hub / Harbor'a gönderme (`push`/`pull`), `save`/`load`. | [**02-images.md**](02-images.md) |
| **03** | **💾 Depolama (Storage)** | Named Volume, Bind Mount (canlı kod bağlama, `:ro`), tmpfs (RAM mount) ve Helper Container ile veritabanı yedekleme/kurtarma. | [**03-storage.md**](03-storage.md) |
| **04** | **🌐 Ağ Yönetimi (Networking)** | Bridge, host ve none ağ sürücüleri, dahili DNS (`127.0.0.11`) ile servis keşfi, canlı ağa bağlama (`connect`) ve izolasyon. | [**04-networking.md**](04-networking.md) |
| **05** | **🐙 Docker Compose** | Çok konteynerli mimarileri tek komutla yönetme (`up -d`, `down -v`), canlı log takibi, servis ölçekleme (`--scale`) ve YAML doğrulama. | [**05-compose.md**](05-compose.md) |
| **06** | **🧹 Sistem, Bakım ve Temizlik** | Disk alanı analizi (`system df`), güvenli ve agresif temizlik (`system prune`), BuildKit cache temizliği ve olay akışı (`events`). | [**06-system-and-cleanup.md**](06-system-and-cleanup.md) |
| **07** | **🔐 Güvenlik ve Hata Ayıklama** | Linux cgroups (RAM/CPU) kotaları, non-root çalıştırma, Trivy CVE zafiyet taraması ve konteyner Çıkış Kodları (Exit Codes) tablosu. | [**07-security-and-troubleshooting.md**](07-security-and-troubleshooting.md) |

---

## ⚡ Günlük Operasyonlarda En Sık Kullanılan 20 Komut

Aşağıdaki tablo, bir DevOps mühendisinin terminalde en çok çalıştırdığı kritik komutların hızlı özetidir:

| No | Amaç | Komut |
|:---:|:---|:---|
| **1** | Port yönlendirmeli web konteyneri başlatma | `docker run -d --name web -p 8080:80 nginx:alpine` |
| **2** | Geçici test konteynerinde interaktif kabuk açma | `docker run -it --rm ubuntu:24.04 bash` |
| **3** | Çalışan konteynerleri listeleme | `docker ps` |
| **4** | Durmuş konteynerler dahil tümünü listeleme | `docker ps -a` |
| **5** | Konteynerin canlı log akışını izleme | `docker logs -f --tail 50 <container>` |
| **6** | Çalışan konteynerin içine interaktif kabuk açma | `docker exec -it <container> sh` |
| **7** | Konteyneri nazikçe durdurma (SIGTERM) | `docker stop <container>` |
| **8** | Durmuş konteyneri silme | `docker rm <container>` |
| **9** | Dockerfile ile yeni bir imaj derleme | `docker build -t my-app:1.0 .` |
| **10** | Sistemdeki yerel imajları listeleme | `docker images` |
| **11** | İmajı uzak kayıt defteri için etiketleme | `docker tag my-app:1.0 user/repo:tag` |
| **12** | İmajı Registry'ye yükleme | `docker push user/repo:tag` |
| **13** | İmajı silme | `docker rmi <image>` |
| **14** | Kalıcı depolama alanı (Volume) oluşturma | `docker volume create my_data` |
| **15** | Özel bridge ağı oluşturma | `docker network create my_net` |
| **16** | Çok servisli yığını arka planda ayağa kaldırma | `docker compose up -d` |
| **17** | Compose servislerini ve ağlarını temizleme | `docker compose down` |
| **18** | Anlık CPU ve RAM tüketimini izleme | `docker stats --no-stream` |
| **19** | Docker disk kullanımını analiz etme | `docker system df` |
| **20** | Kullanılmayan tüm atıl kaynakları temizleme | `docker system prune -f` |

---

## 💡 İpuçları ve En İyi Pratikler (Best Practices)

1. **İsimlendirme:** Her zaman `--name` bayrağını kullanın. Rastgele üretilen konteyner isimleri yerine işlevini belirten isimler operasyonu kolaylaştırır.
2. **Kalıcılık:** Üretim ortamında veritabanı gibi durum bilgisi tutan (stateful) servislerde mutlaka **Named Volume** kullanın.
3. **İzolasyon:** Farklı projeleri ve mikroservis gruplarını mutlaka kendi özel bridge ağlarında (`--network`) çalıştırın.
4. **Güvenlik:** Konteynerleri varsayılan root kullanıcısıyla çalıştırmaktan kaçının; Dockerfile içinde `USER 10001` tanımlayın veya `docker run --user` parametresini kullanın.
5. **Temizlik:** Disk doluluk krizlerini önlemek için `docker system prune -f` ve `docker builder prune -f` komutlarını düzenli bakım adımı olarak uygulayın.
