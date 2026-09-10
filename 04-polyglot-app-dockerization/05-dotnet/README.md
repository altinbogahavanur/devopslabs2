# LAB-05-05 — .NET 8 (ASP.NET Core) Web API Uygulamasını Multi-Stage ile Dockerize Etme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta | 35 dakika | `dotnet/sdk:8.0`, `dotnet/aspnet:8.0-alpine`, `curl` | `8080` |

---

## 1. Uygulama Hakkında

Modern kurumsal ortamlarda C# ve ASP.NET Core yaygın bir omurgadır. 

.NET ekosisteminde:
* **.NET SDK (`mcr.microsoft.com/dotnet/sdk:8.0`):** Roslyn derleyicisi, MSBuild, NuGet istemcisi içerir ve yaklaşık **850 MB** boyutundadır.
* **ASP.NET Core Alpine Runtime (`mcr.microsoft.com/dotnet/aspnet:8.0-alpine`):** Yalnızca derlenmiş DLL'leri çalıştıran hafif motordur ve yaklaşık **110 MB** boyutundadır.

**Amaç:** Multi-Stage build ile SDK derleyicisini üretim imajından tamamen soyutlamak, yerleşik `app` kullanıcısıyla (non-root) güvenli ve hafif bir .NET imajı üretmektir.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Derleme ve Çalıştırma

Dockerfile direktiflerini kurgulamak için referans Linux çalıştırma adımları:

```bash
# 1. Ubuntu'ya .NET 8 SDK kurulması
sudo apt update && sudo apt install -y dotnet-sdk-8.0

# 2. Çalışma dizini ve kodların yerleşimi
mkdir -p /app && cd /app
cp -r /path/to/source/* /app/

# 3. Bağımlılıkların çözümlenmesi (NuGet restore)
dotnet restore

# 4. Üretime hazır Release modunda derleme ve yayımlama
dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# 5. DERLEYİCİYE ARTIK İHTİYAÇ YOKTUR!
# Üretim makinesinde sadece ASP.NET Core Runtime ile DLL çalıştırılır:
ASPNETCORE_URLS="http://+:8080" dotnet /app/publish/DevOpsApi.dll
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Multi-Stage Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| .NET 8 SDK Kurulumu | `FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build` | 1. Aşama (Build): Sadece derleme için |
| `dotnet restore` | `COPY *.csproj ./ && RUN dotnet restore` | NuGet bağımlılık katmanı önbelleğe alınır |
| `dotnet publish` | `RUN dotnet publish -c Release -o /app/publish` | Üretime hazır optimize DLL'ler çıkarılır |
| Runtime Kurulumu | `FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine` | 2. Aşama: Hafif, derleyicisiz Alpine JRE eşdeğeri |
| DLL'leri Kopyalama | `COPY --from=build /app/publish .` | Sadece derlenmiş çıktılar aktarılır |
| Non-Root Kullanıcı | `USER $APP_UID` | .NET 8 ile gelen yerleşik `app` kullanıcısı (UID 1654) |
| Başlatma | `ENTRYPOINT ["dotnet", "DevOpsApi.dll"]` | DLL çalıştırılır |

---

## 4. Adım Adım Uygulama ve Doğrulama

**`Dockerfile`:**
```dockerfile
# ==========================================
# 1. AŞAMA: DERLEME (BUILD)
# ==========================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# Bağımlılıkları önbelleğe almak için önce sadece proje dosyası kopyalanır
COPY ["DevOpsApi.csproj", "./"]
RUN dotnet restore "DevOpsApi.csproj"

# Kaynak kodlar kopyalanıp Release modunda yayımlanır
COPY . .
RUN dotnet publish "DevOpsApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# ==========================================
# 2. AŞAMA: ÇALIŞMA ZAMANI (RUNTIME - ALPINE)
# ==========================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine

WORKDIR /app

# .NET 8 yerleşik non-root kullanıcısı
USER $APP_UID

# Sadece derleme çıktıları aktarılır
COPY --from=build /app/publish .

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "DevOpsApi.dll"]
```

**Derleme ve Çalıştırma:**
```bash
# 1. İmajı derleme
docker build -t dotnet-devops-api:v1.0 .

# 2. Konteynerı çalıştırma
docker run -d --name my-dotnet-api -p 8080:8080 dotnet-devops-api:v1.0

# 3. Test etme
curl -i http://localhost:8080/health
```

---

## 5. Beklenen Sonuç ve Doğrulama

```bash
curl -s http://localhost:8080/
```

* **JSON Çıktısı:**
```json
{
  "message": ".NET 8 ASP.NET Core API Basariyla Calisiyor!",
  "framework": ".NET 8.0 Minimal API",
  "os": "Linux...",
  "timestamp": "..."
}
```
