# Stage 1: Build Frontend Assets
FROM node:20 AS node_build
WORKDIR /app

# Instalar dependencias de Node
COPY package*.json ./
RUN npm install

# Copiar todo el frontend y compilar
COPY . .
RUN npm run build

# Stage 2: PHP Application
FROM php:8.2-fpm

# System Dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip libpng-dev libonig-dev libxml2-dev libzip-dev libpq-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Composer (forma robusta sin pipe)
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

WORKDIR /var/www

# Copiar backend
COPY . .

# Copiar assets compilados del frontend
COPY --from=node_build /app/public/build ./public/build

# Instalar dependencias PHP
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Permisos
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 storage bootstrap/cache

# Ejecutar PHP-FPM
CMD ["php-fpm"]
