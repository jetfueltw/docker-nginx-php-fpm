FROM php:7.2-fpm-alpine

RUN set -ex \
 && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
 && apk add --no-cache --virtual .cert-deps openssl curl ca-certificates \
 && curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
 && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
        echo "key verification succeeded!"; \
        mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
    else \
        echo "key verification failed!"; \
        exit 1; \
    fi \
 && printf "%s%s%s\n" "http://nginx.org/packages/alpine/v" `egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release` "/main" | tee -a /etc/apk/repositories \
 && apk del .cert-deps 

RUN set -ex \
 && apk update && apk upgrade \
 && apk add --no-cache freetype-dev libxpm-dev libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev \
    git \
    nginx \
    supervisor \
 # forward request and error logs to docker log collector
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 && docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-xpm-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-webp-dir=/usr/include/ \
 && docker-php-ext-configure zip --with-libzip=/usr/include/ \
 && docker-php-ext-install opcache bcmath gd zip pdo_mysql \
 && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('SHA384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Composer.phar installer verified'; } else { echo 'Composer.phar installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php --install-dir=/usr/bin --filename=composer \
 && php -r "unlink('composer-setup.php');" \
 && composer global require hirak/prestissimo

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY php-fpm/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
COPY supervisor/supervisord.conf /etc/supervisord.conf
COPY start.sh /start.sh

RUN rm /usr/local/etc/php-fpm.d/docker.conf \
 && rm /usr/local/etc/php-fpm.d/zz-docker.conf \
 && rm -rf /var/www/html \
 && chmod 755 /start.sh

WORKDIR /var/www/app
# COPY app .

EXPOSE 80

CMD ["/start.sh"]
