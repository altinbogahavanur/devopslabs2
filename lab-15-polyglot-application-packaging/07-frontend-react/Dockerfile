# ==========================================
# 1. AŞAMA: DERLEYİCİ (BUILDER)
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Bağımlılıkları önbelleğe alma
COPY package*.json ./
RUN npm install

# Kaynak kodları kopyalayıp derleme
COPY . .
RUN npm run build

# ==========================================
# 2. AŞAMA: ÇALIŞMA ZAMANI (RUNTIME - NGINX)
# ==========================================
FROM nginx:1.25-alpine

# Varsayılan Nginx karşılama dosyalarını temizleme
RUN rm -rf /usr/share/nginx/html/*

# Özel SPA yönlendirmeli Nginx konfigürasyonunu kopyalama
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Builder aşamasından sadece derlenen statik dosyaları aktarma
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
