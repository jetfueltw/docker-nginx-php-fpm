FROM php:8.2-fpm-alpine

RUN set -ex \
 && apk update && apk upgrade \
 # install php extension
 && apk add --no-cache --virtual .phpize-deps \
    $PHPIZE_DEPS \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    freetype-dev \
    icu-dev \
    libzip-dev \
 && docker-php-ext-configure gd \
    --with-jpeg \
    --with-webp \
    --with-freetype \
 && docker-php-ext-install gd \
 && docker-php-ext-configure intl \
 && docker-php-ext-install intl \
 && docker-php-ext-install zip \
 && docker-php-ext-install pcntl \
 && docker-php-ext-install opcache \
 && docker-php-ext-install bcmath \
 && docker-php-ext-install pdo_mysql \
 && pecl install redis \
 && docker-php-ext-enable redis \
 && rm -rf /tmp/pear \
 && apk del .phpize-deps

RUN set -ex \
 # install package
 && apk add --no-cache \
    libpng \
    libjpeg-turbo \
    libwebp \
    freetype \
    icu-libs \
    icu-data-full \
    libzip \
    bash \
    git \
    nginx \
    supervisor

RUN set -ex \
 # install composer
 && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"

RUN set -ex \
 # use the default production configuration
 && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
 # remove unnecessary file
 && rm /usr/local/etc/php-fpm.d/docker.conf \
 && rm /usr/local/etc/php-fpm.d/zz-docker.conf \
 # fix /var/lib/nginx permission denied
 && chown -Rf www-data:www-data /var/lib/nginx

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/http.d/default.conf

COPY php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY supervisor/supervisord.conf /etc/supervisord.conf

COPY --chmod=755 start.sh /start.sh

# test phpinfo
# COPY --chown=www-data:www-data app /var/www/app

WORKDIR /var/www/app

EXPOSE 80
CMD ["/start.sh"]
