#!/bin/sh

# Enable custom nginx config files if they exist
if [ -f /var/www/app/docker/nginx/nginx.conf ]; then
  cp /var/www/app/docker/nginx/nginx.conf /etc/nginx/nginx.conf
fi

if [ -f /var/www/app/docker/nginx/default.conf ]; then
  cp /var/www/app/docker/nginx/default.conf /etc/nginx/conf.d/default.conf
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
  chown -Rf nginx:nginx /var/www/app
fi

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
