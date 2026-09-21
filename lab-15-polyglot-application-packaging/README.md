# LAB-15: Polyglot Uygulama Paketleme Atölyesi (7 Farklı Yazılım Dili)

## 🎯 Labın Amacı
Farklı programlama dillerindeki uygulamaların **normal bir Linux sunucusunda elle nasıl kurulup çalıştırıldığını** ve bu geleneksel Linux adımlarının **Dockerfile direktiflerine satır satır nasıl uyarlandığını** kavramak; 7 popüler dili ana makineye tek bir kütüphane bile kurmadan izole şekilde paketlemek.

> [!IMPORTANT]
> **🛡️ Sıfır Host Kirliliği Prensibi (Zero Host Pollution):**
> Bu dilleri derlemek için ana makinenize (Ubuntu sunucunuza) **Node.js, Python, Go, Java veya .NET KESİNLİKLE KURMAYINIZ!**
> `docker build` komutu derleme ortamını izole konteyner katmanında (`FROM ...`) otomatik ayağa kaldırır. Ana makinenin işletim sistemine, kütüphanelerine ve mevcut Kubernetes/Docker mimarisine **asla yük veya kirlilik getirmez, sisteminizi bozmaz.**

---

## 🌐 Web Arayüzü ve Port Slotları
Tüm web tabanlı konteynerler sunucunuzdaki **App Slotları** ile tam uyumludur:
- **Port 19001 (App1 Slotu):** Tarayıcıdan `http://<SUNUCU-IP>/app1` veya `https://student.app1.<domain>`
- **Port 19002 (App2 Slotu):** Tarayıcıdan `http://<SUNUCU-IP>/app2` veya `https://student.app2.<domain>`
- **Port 19003 (App3 Slotu):** Tarayıcıdan `http://<SUNUCU-IP>/app3` veya `https://student.app3.<domain>`

---

## 🚀 Dil Bazlı Karşılaştırma ve Paketleme Rehberi

### 1. Python (Flask REST API)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# 1. Sunucuda Python ve pip kurarsınız:
sudo apt update && sudo apt install -y python3 python3-pip

# 2. Çalışma klasörü açıp kodları atarsınız:
mkdir -p /opt/app && cd /opt/app
# (scp / rsync app.py requirements.txt /opt/app/)

# 3. Bağımlılıkları yüklersiniz:
pip install -r requirements.txt

# 4. Uygulamayı arka planda çalıştırırsınız:
python3 app.py &
```

#### 🐳 Dockerfile'da Nasıl Tanımladık?
```dockerfile
FROM python:3.12-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: Python dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/02-python

# 2. Adım: İmajı derleyin:
docker build -t app-python:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-py -p 19001:8000 app-python:1.0

# 4. Adım: Tarayıcıdan veya curl ile test edin:
curl http://localhost:19001
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-py
```

---

### 2. Node.js (Express Web API)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
mkdir -p /var/www/app && cd /var/www/app
npm install --only=production
export PORT=3000
node server.js
```

#### 🐳 Dockerfile'da Nasıl Tanımladık?
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: Node.js dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/01-nodejs

# 2. Adım: İmajı derleyin:
docker build -t app-node:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-node -p 19001:3000 app-node:1.0

# 4. Adım: Test edin:
curl http://localhost:19001
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-node
```

---

### 3. Golang (Ultra-Hafif Scratch İmajı - ~8 MB)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
CGO_ENABLED=0 go build -ldflags="-w -s" -o /bin/server main.go
/bin/server
```

#### 🐳 Dockerfile'da Nasıl Tanımladık? (Multi-Stage)
```dockerfile
# 1. Aşama: Derleyici (Builder)
FROM golang:1.23-alpine AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o /bin/server main.go

# 2. Aşama: Sıfır boyutlu saf ikili (Runtime)
FROM scratch
COPY --from=builder /bin/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: Go dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/03-golang

# 2. Adım: İmajı derleyin (800 MB'lık Go SDK yerine 8 MB'lık imaj üretilir):
docker build -t app-go:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-go -p 19001:8080 app-go:1.0

# 4. Adım: Test edin:
curl http://localhost:19001
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-go
```

---

### 4. React (Vite Multi-Stage + Nginx SPA)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
npm install && npm run build
cp -r dist/* /var/www/html/
cp nginx.conf /etc/nginx/conf.d/default.conf
systemctl restart nginx
```

#### 🐳 Dockerfile'da Nasıl Tanımladık?
```dockerfile
# 1. Aşama: Node.js ile statik HTML/JS derleme
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 2. Aşama: Hafif Nginx ile web sunumu
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: React frontend dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/07-frontend-react

# 2. Adım: Multi-Stage imajı derleyin:
docker build -t app-react:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-react -p 19001:80 app-react:1.0

# 4. Adım: Tarayıcıdan açın:
# Webden: http://<SUNUCU-IP>/app1 veya https://student.app1.<domain>
curl -I http://localhost:19001

# 5. Adım: Temizlik:
docker rm -f test-react
```

---

### 5. Java (Spring Boot & Maven Petclinic - Layered JAR)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
sudo apt install -y openjdk-17-jdk maven
mkdir -p /app && cd /app
mvn clean package -DskipTests
java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar target/petclinic-demo-1.0.0.jar
```

#### 🐳 Dockerfile'da Nasıl Tanımladık? (Multi-Stage & Layered JAR)
```dockerfile
# 1. Aşama: Derleyici (Maven)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests
WORKDIR /build/extracted
RUN java -Djarmode=layertools -jar /build/target/*.jar extract

# 2. Aşama: Çalışma Zamanı (Hafif JRE)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/extracted/dependencies/ ./
COPY --from=builder /build/extracted/spring-boot-loader/ ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/ ./
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: Java dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/04-java-petclinic

# 2. Adım: Multi-stage imajı derleyin:
docker build -t app-java:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-java -p 19001:8080 --memory=512m app-java:1.0

# 4. Adım: Test edin:
curl http://localhost:19001/api/pets
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-java
```

---

### 6. .NET Core (ASP.NET Web API)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
sudo apt install -y dotnet-sdk-8.0
mkdir -p /app && cd /app
dotnet restore
dotnet publish -c Release -o /app/publish /p:UseAppHost=false
dotnet /app/publish/DevOpsApi.dll
```

#### 🐳 Dockerfile'da Nasıl Tanımladık? (Multi-Stage)
```dockerfile
# 1. Aşama: Derleyici (SDK)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["DevOpsApi.csproj", "./"]
RUN dotnet restore "DevOpsApi.csproj"
COPY . .
RUN dotnet publish "DevOpsApi.csproj" -c Release -o /app/publish /p:UseAppHost=false

# 2. Aşama: Çalışma Zamanı (Hafif Alpine)
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
WORKDIR /app
USER $APP_UID
COPY --from=build /app/publish .
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "DevOpsApi.dll"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: .NET dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/05-dotnet

# 2. Adım: Multi-stage imajı derleyin:
docker build -t app-dotnet:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-dotnet -p 19001:8080 app-dotnet:1.0

# 4. Adım: Test edin:
curl http://localhost:19001/health
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-dotnet
```

---

### 7. PHP (Apache / FPM & Composer)

#### 🐧 Geleneksel Linux Sunucusunda Elle Ne Yapardık?
```bash
# Linux terminalinde elle:
sudo apt install -y php8.3-cli composer
mkdir -p /var/www/html && cd /var/www/html
composer install --no-dev -o
php -S 0.0.0.0:8000 -t public/
```

#### 🐳 Dockerfile'da Nasıl Tanımladık?
```dockerfile
FROM php:8.3-cli-alpine
WORKDIR /var/www/html
RUN docker-php-ext-install opcache
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
COPY . .
USER www-data
EXPOSE 8000
CMD ["php", "-S", "0.0.0.0:8000", "-t", "public/"]
```

#### 💻 Uygulama Adımları:
```bash
# 1. Adım: PHP dizinine geçin:
cd ~/docker-labs/lab-15-polyglot-application-packaging/06-php

# 2. Adım: İmajı derleyin:
docker build -t app-php:1.0 .

# 3. Adım: Konteyneri App1 slotundan (19001) başlatın:
docker run -d --name test-php -p 19001:8000 app-php:1.0

# 4. Adım: Test edin:
curl http://localhost:19001/health
# Webden: http://<SUNUCU-IP>/app1

# 5. Adım: Temizlik:
docker rm -f test-php
```

---

## ✅ Doğrulama (Verification)
- Çalıştırdığınız herhangi bir web servisi için tarayıcınızdan `http://<SUNUCU-IP>/app1` veya `https://student.app1.<domain>` adresine gittiğinizde uygulamanın görsel arayüzünün hatasız yüklendiğini teyit edin.
- Terminalden `curl http://localhost:19001` yanıtının döndüğünü teyit edin.

---

## 🧹 Toplu Temizlik
```bash
docker rm -f test-go test-py test-node test-react test-java test-dotnet test-php 2>/dev/null || true
docker rmi app-go:1.0 app-python:1.0 app-node:1.0 app-react:1.0 app-java:1.0 app-dotnet:1.0 app-php:1.0 2>/dev/null || true
```
