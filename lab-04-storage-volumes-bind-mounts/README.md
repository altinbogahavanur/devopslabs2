# LAB-DOC-04 — Kalıcı Depolama ve Veri Yönetimi: Volumes ve Bind Mounts

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|---|---|---|---|
| Orta | 40 Dakika | `docker-ce`, `named-volume`, `bind-mount`, `tmpfs` | 8080 |

## Amaç
- Konteynerlerin varsayılan olarak geçici (stateless / ephemeral) çalışma mantığını ve veri kaybı riskini kavramak.
- Veritabanları ve durum saklayan uygulamalar için Docker Engine tarafından yönetilen **Named Volume** mimarisini kurmak.
- Geliştiriciler için ana makinedeki kaynak kodun anında konteyner içinde güncellenmesini sağlayan **Host Bind Mount** yapısını uygulamak.
- Hassas parolaların diske yazılmasını önleyen bellek içi **`tmpfs`** depolamayı ve UID/GID izin uyuşmazlıklarının çözümünü öğrenmek.

## Ön Koşullar
- `lab-01-docker-engine-and-warmup` ve `lab-02-dockerfile-and-caching` tamamlanmış olmalıdır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Alt Dizin | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-volumes-and-bind-mounts`](01-volumes-and-bind-mounts/README.md) | Orta | Kalıcı veritabanı depolama için Named Volume oluşturma, Host Bind Mount ve salt-okunur (`:ro`) dizin eşleme. |
| **02** | [`02-tmpfs-in-memory`](02-tmpfs-in-memory/README.md) | Orta | Bellek içi (`--tmpfs`) RAM diski oluşturma, hassas verilerin diske yazılmasını önleme ve anında sıfırlama. |
| **03** | [`advanced/03-volume-backup-restore-and-permissions`](advanced/03-volume-backup-restore-and-permissions/README.md) | İleri | Host ve konteyner non-root UID/GID uyuşmazlığı (`Permission Denied`) çözümü ve `--user` bayrağı kullanımı. |

---

## Hızlı Başlangıç

```bash
cd lab-04-storage-volumes-bind-mounts/01-volumes-and-bind-mounts
cat README.md
```
