FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 10001 -S appgroup && adduser -u 10001 -D -S -G appgroup appuser
COPY --from=builder --chown=appuser:appgroup /build/node_modules ./node_modules
COPY --chown=appuser:appgroup package.json server.js ./
USER 10001
EXPOSE 3000
CMD ["node", "server.js"]
