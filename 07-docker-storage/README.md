# LAB-DOC-07 — Kalıcı Depolama ve Veri Yönetimi

| Seviye | Profil / Araçlar | Açık Portlar |
| --- | --- | --- |
| Orta - İleri | `docker-ce`, `named-volume`, `bind-mount`, `tmpfs` | 8080 |

Konteynerlar varsayılan olarak geçicidir (stateless / ephemeral). Veritabanları ve kalıcı durum saklayan uygulamalar için Docker'ın depolama mekanizmalarını bilmek zorunludur. Bu modülde Named Volume, Host Bind Mount, bellek içi `tmpfs` ve UID/GID izin uyuşmazlıkları ele alınır.

---

## Modül Laboratuvarları

Aşağıdaki laboratuvarları sırasıyla uygulayınız:

| No | Modül Yolu | Seviye | Odak Konusu |
|:---:|:---|:---:|:---|
| **01** | [`01-volumes-and-bind-mounts`](01-volumes-and-bind-mounts/README.md) | Orta | Kalıcı veritabanı depolama için Named Volume oluşturma, Host Bind Mount ve salt-okunur (`:ro`) dizin eşleme. |
| **02** | [`02-tmpfs-in-memory`](02-tmpfs-in-memory/README.md) | Orta | Bellek içi (`--tmpfs`) RAM diski oluşturma, hassas verilerin diske yazılmasını önleme ve anında sıfırlama. |
| **03** | [`advanced/03-volume-backup-restore-and-permissions`](advanced/03-volume-backup-restore-and-permissions/README.md) | İleri | Host ve konteyner non-root UID/GID uyuşmazlığı (`Permission Denied`) çözümü ve `--user` bayrağı kullanımı. |

---

## Hızlı Başlangıç

İlk laboratuvar ile çalışmaya başlayın:

```bash
cd 01-volumes-and-bind-mounts
cat README.md
```
