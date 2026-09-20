# Pratik Lab 03: Docker Volume ve Network İnceleme & Ağ İzolasyonu

Bu pratik laboratuvarda, Docker disk birimlerini (`volume`) teftiş edecek, özel bir bridge ağı oluşturup konteynerleri DNS isimleriyle haberleştirecek ve ağ bağlantılarını denetleyeceksiniz.

---

## 1. Docker Volume Teftişi (`docker volume inspect`)

1. **Named Volume Oluşturma ve Teftiş:**
   ```bash
   docker volume create lab-veri
   docker volume ls
   docker volume inspect lab-veri
   ```
   * `Mountpoint` kısmında diskin ana makinede nerede durduğunu (`/var/lib/docker/volumes/...`) görün.

2. **Volume ile Veri Yazma:**
   ```bash
   docker run --rm -v lab-veri:/data alpine sh -c "echo 'DevOps 2026 Kalici Veri' > /data/not.txt"
   ```
   * Konteyner işi bitip tamamen silindi (`--rm`).

3. **Verinin Korunduğunu Doğrulama:**
   Yepyeni bir konteynerle aynı volume'u okuyun:
   ```bash
   docker run --rm -v lab-veri:/data alpine cat /data/not.txt
   ```
   * Ekranda `DevOps 2026 Kalici Veri` çıktısını görün. Konteyner ölür, Volume kalır!

---

## 2. Docker Network İnceleme ve DNS İletişimi

Varsayılan `bridge` ağı konteyner adıyla DNS çözümlemeyi desteklemez, ancak kullanıcı tanımlı özel ağlar otomatik dahili DNS sunar:

1. **Özel Ağ Oluşturma:**
   ```bash
   docker network create devops-net
   docker network ls
   docker network inspect devops-net
   ```

2. **Aynı Ağa 2 Konteyner Bağlama:**
   ```bash
   # 1. Konteyner (Web):
   docker run -d --name servis-a --network devops-net nginx:alpine

   # 2. Konteyner (İstemci):
   docker run -d --name servis-b --network devops-net alpine sleep 3600
   ```

3. **Dahili DNS Testi (`docker exec`):**
   `servis-b` konteynerinin içine girip `servis-a` konteynerine ismiyle istek atın:
   ```bash
   docker exec servis-b ping -c 2 servis-a
   docker exec servis-b wget -qO- http://servis-a
   ```
   * İki konteynerin IP bilmeden doğrudan isimle (`servis-a`) konuştuğunu görün!

4. **Ağdan Ayırma ve Bağlama (`docker network connect / disconnect`):**
   ```bash
   # Bağlantıyı kopar:
   docker network disconnect devops-net servis-b
   docker exec servis-b ping -c 1 -W 2 servis-a || echo "Beklendiği gibi ağ koptu!"

   # Tekrar bağla:
   docker network connect devops-net servis-b
   docker exec servis-b ping -c 1 servis-a && echo "Ağ tekrar bağlandı!"
   ```

---

## 3. Temizlik

```bash
docker rm -f servis-a servis-b
docker volume rm lab-veri
docker network rm devops-net
```
