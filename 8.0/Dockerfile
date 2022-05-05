FROM php:8.0-fpm-alpine

RUN set -ex \
 # install package
 && apk update && apk upgrade \
 && apk add --no-cache \
    git nginx supervisor

# RUN set -ex \-f
 # install composer
#  && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
#  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
#  && php -r "if (hash_file('sha384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
#  && php composer-setup.php --install-dir=/usr/bin --filename=composer \
#  && php -r "unlink('composer-setup.php');"

RUN set -ex \
 # use the default production configuration
 && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# RUN set -ex \
#  # forward request and error logs to docker log collector
#  && ln -sf /dev/stdout /var/log/nginx/access.log \
#  && ln -sf /dev/stderr /var/log/nginx/error.log \
#  # fix /var/lib/nginx permission denied
#  && chown -Rf www-data:www-data /var/lib/nginx

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/http.d /etc/nginx/http.d

COPY php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY supervisor/supervisord.conf /etc/supervisord.conf

# https://github.com/moby/moby/issues/34819
COPY start.sh /start.sh
RUN chmod +x /start.sh;

# test phpinfo
COPY --chown=www-data:www-data app /var/www/app

WORKDIR /var/www/app
EXPOSE 80

CMD ["/start.sh"]
