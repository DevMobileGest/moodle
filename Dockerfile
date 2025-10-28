# ---------- BASE IMAGE ----------
FROM php:8.2-apache

# ---------- SYSTEM DEPENDENCIES ----------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git unzip libpq-dev libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev \
    libzip-dev libssl-dev zlib1g-dev libonig-dev libicu-dev \
    libxslt1-dev ghostscript gnupg libcurl4-openssl-dev libsodium-dev && \
    rm -rf /var/lib/apt/lists/*

# ---------- PHP EXTENSIONS ----------
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd intl soap sodium pdo pdo_mysql zip

# ---------- ENABLE APACHE MODS ----------
RUN a2enmod rewrite headers env dir mime

# ---------- COMPOSER ----------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ---------- WORKDIR AND SOURCES ----------
WORKDIR /var/www/html
COPY . .

# ---------- PERMISSIONS ----------
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type f -exec chmod 0644 {} \; && \
    find /var/www/html -type d -exec chmod 0755 {} \;

# ---------- MOODLEDATA VOLUME ----------
VOLUME ["/var/www/moodledata"]

# ---------- ENVIRONMENT ----------
ENV MOODLE_DOCKER=1 \
    MOODLE_BROWSERTESTS_OUTPUT_DIR=/var/www/html/

# ---------- EXPOSE PORT ----------
EXPOSE 8100

# ---------- HEALTHCHECK ----------
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/login/index.php || exit 1

# ---------- PRODUCTION PHP SETTINGS ----------
COPY ./config/php-production.ini /usr/local/etc/php/conf.d/php-production.ini

# ---------- INSTALL DEPS ----------
RUN composer install --no-dev --optimize-autoloader --prefer-dist

# ---------- CLEANUP ----------
RUN rm -rf /root/.composer/cache /tmp/* /var/tmp/*

# ---------- INSTRUCTIONS
# - "config.php" should be provided via env/volume with correct credentials.
# - "moodledata" should be mapped as a persistent volume outside web root.
#
# - Example Docker run:
#   docker run -d -p 80:80 -v /host/moodledata:/var/www/moodledata -v /host/config.php:/var/www/html/config.php moodle
