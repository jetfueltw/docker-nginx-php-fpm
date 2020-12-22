FROM php:7.2-fpm-alpine

RUN set -ex \
 # install package
 && apk update && apk upgrade \
 && apk add --no-cache freetype-dev libxpm-dev libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev librdkafka-dev \
    git nginx supervisor \
 # install php extension
 && docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-xpm-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-webp-dir=/usr/include/ \
 && docker-php-ext-configure zip --with-libzip=/usr/include/ \
 && docker-php-ext-install opcache bcmath gd zip pdo_mysql \
 # install php extension via pecl install
 && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
 && pecl install rdkafka redis \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable rdkafka redis \
 && apk del .phpize-deps

RUN set -ex \
 # install composer
 && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php --install-dir=/usr/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"

RUN set -ex \
 # remove unnecessary file
 && rm /usr/local/etc/php-fpm.d/docker.conf \
 && rm /usr/local/etc/php-fpm.d/zz-docker.conf \
 # forward request and error logs to docker log collector
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 # fix /var/lib/nginx permission denied
 && chown -Rf www-data:www-data /var/lib/nginx

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY php-fpm/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
COPY supervisor/supervisord.conf /etc/supervisord.conf
COPY start.sh /start.sh

# https://github.com/moby/moby/issues/34819
RUN chmod +x /start.sh;

# test phpinfo
# COPY --chown=www-data:www-data app /var/www/app

WORKDIR /var/www/app
EXPOSE 80

CMD ["/start.sh"]
