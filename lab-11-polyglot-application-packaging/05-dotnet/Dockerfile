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
