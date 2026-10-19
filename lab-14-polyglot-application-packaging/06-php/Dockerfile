FROM php:8.3-cli-alpine

WORKDIR /var/www/html

# 1. OPcache eklentisini kurma
RUN docker-php-ext-install opcache

# 2. Composer ikili aracını resmi imajdan kopyalama (Multi-stage pattern)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# 3. Bağımlılık dosyasını kopyalama ve yükleme
COPY composer.json ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# 4. Kaynak kodları kopyalama
COPY . .

# 5. İzinleri www-data kullanıcısına verme
RUN chown -R www-data:www-data /var/www/html
USER www-data

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "public/"]
