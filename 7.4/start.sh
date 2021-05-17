#!/bin/sh

# Enable custom nginx config files if they exist
if [ -f /var/www/app/docker/nginx/nginx.conf ]; then
  cp /var/www/app/docker/nginx/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f /var/www/app/docker/nginx/default.conf ]; then
  cp /var/www/app/docker/nginx/default.conf /etc/nginx/conf.d/default.conf
fi

if [ -f /var/www/app/docker/php-fpm/php-fpm.conf ]; then
  cp /var/www/app/docker/php-fpm/php-fpm.conf /usr/local/etc/php-fpm.conf
fi

if [ -f /var/www/app/docker/php-fpm/www.conf ]; then
  cp /var/www/app/docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
fi

if [ -f /var/www/app/docker/php-fpm/docker-var.ini ]; then
  cp /var/www/app/docker/php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
fi

if [ -f /var/www/app/docker/supervisor/program.conf ]; then
  mkdir -p /etc/supervisor/conf.d && cp /var/www/app/docker/supervisor/program.conf /etc/supervisor/conf.d/program.conf
fi

if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
  sed -i "s/client_max_body_size [[:digit:]]\+m;/client_max_body_size ${PHP_POST_MAX_SIZE}m;/g" /etc/nginx/nginx.conf
  sed -i "s/upload_max_filesize = [[:digit:]]\+M/upload_max_filesize = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-var.ini
  sed -i "s/post_max_size = [[:digit:]]\+M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /usr/local/etc/php/conf.d/docker-var.ini
fi

if [ ! -z "$PHP_MEMORY_LIMIT" ]; then
  sed -i "s/memory_limit = [[:digit:]]\+M/memory_limit = ${PHP_MEMORY_LIMIT}M/g" /usr/local/etc/php/conf.d/docker-var.ini
fi

if [ -z "$SKIP_CHOWN" ]; then
  chown -Rf www-data:www-data /var/www/app
fi

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
