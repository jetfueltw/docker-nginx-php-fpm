FROM php:7.2-fpm-alpine3.9

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
 && apk add --no-cache nginx supervisor \
 # forward request and error logs to docker log collector
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 && docker-php-ext-install pdo_mysql bcmath

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm/docker-var.ini /usr/local/etc/php/conf.d/docker-var.ini
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY start.sh /start.sh

RUN chmod 755 /start.sh

WORKDIR /var/www/app
# COPY app .

EXPOSE 80

CMD ["/start.sh"]
