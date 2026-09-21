# 1. Taban imaj: Hafif ve guvenli Node.js Alpine
FROM node:20-alpine

# 2. Konteyner ici calisma dizini
WORKDIR /app

# 3. Ortam degiskeni tanimi (ENV)
ENV APP_ENV=production \
    PORT=3000

# 4. Uygulama kaynak kodunu kopyala (COPY)
COPY server.js .

# 5. Dokumantasyon amacli port bildirimi (EXPOSE)
EXPOSE 3000

# 6. Konteyner calistiginda yurutulecek varsayilan komut (CMD)
CMD ["node", "server.js"]
