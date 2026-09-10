# LAB-01 — Ubuntu 24.04/22.04 Üzerine Resmi Docker Engine ve Compose Kurulumu

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Başlangıç | 30 dakika | `docker-ce`, `docker-compose-plugin`, `portainer` | `9000, 9443` |

---

## Adım Adım Uygulama

### Adım 1: Eski veya Dağıtım Paketlerinin Temizlenmesi

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" 2>/dev/null || true
done
```

---

### Adım 2: Resmi Docker APT Deposunun ve GPG Anahtarının Eklenmesi

```bash
# 1. Gerekli sertifika araçlarını kurma
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Keyrings dizinini oluşturma ve GPG anahtarını indirme
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 3. Docker APT deposunu kaynak listesine ekleme
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Paket listesini güncelleme
sudo apt-get update
```

---

### Adım 3: Docker Engine, Buildx ve Compose Kurulumu

```bash
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

---

### Adım 4: Root Olmayan Kullanıcı İzni (`docker` Grubu)

Varsayılan olarak Docker UNIX soketi (`/var/run/docker.sock`) yalnızca `root` kullanıcısına aittir. Komutların başına `sudo` yazmadan çalışabilmek için mevcut kullanıcı `docker` grubuna eklenir:

```bash
# Mevcut kullanıcıyı docker grubuna ekleme
sudo usermod -aG docker "$USER"

# Grup yetkisini geçerli oturumda aktif etme
newgrp docker
```

---

### Adım 5: Log Rotasyonu Yapılandırması

Konteyner loglarının diski doldurmasını önlemek için `/etc/docker/daemon.json` içinde dosya boyutu sınırı tanımlanır:

```bash
sudo mkdir -p /etc/docker
cat <<'DAEMON_EOF' | sudo tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
DAEMON_EOF

# Servisi yeniden başlatma ve otomatik başlatmayı etkinleştirme
sudo systemctl restart docker
sudo systemctl enable docker
```

---

### Adım 6: Kurulumu Test Etme

```bash
# Servis ve sürüm denetimi
docker version
docker compose version

# Test konteyneri çalıştırma
docker run --rm hello-world
```

---

### Adım 7: Portainer CE ile Görsel Yönetim Paneli Kurulumu (Opsiyonel)

Konteynerları, imajları, volume ve ağları web arayüzünden izlemek için Portainer CE başlatılır:

```bash
# 1. Kalıcı volume oluşturma
docker volume create portainer_data

# 2. Portainer CE konteynerini başlatma
docker run -d -p 8000:8000 -p 9443:9443 -p 9000:9000 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

*Tarayıcınızdan `http://localhost:9000` veya `https://localhost:9443` adresine giderek ilk admin şifrenizi belirleyin.*

---

## Temizlik

İndirilen test imajını temizleyin:

```bash
docker rmi hello-world 2>/dev/null || true
```
