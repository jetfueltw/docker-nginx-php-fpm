# docker-nginx-php-fpm

```
# build php7.4
docker build --pull --no-cache 7.4 -t jetfueltw/nginx-php-fpm:7.4

# build php7.4 (compiled from source with the PHP2Shell fix: CVE-2026-109618, CVE-2026-109619)
docker build --pull --no-cache 7.4 -t jetfueltw/nginx-php-fpm:7.4-php2shell

# build php8.2
docker build --pull --no-cache 8.2 -t jetfueltw/nginx-php-fpm:8.2

# run
docker run --rm -p 80:80 jetfueltw/nginx-php-fpm:8.2

# push images
docker push jetfueltw/nginx-php-fpm:7.4
docker push jetfueltw/nginx-php-fpm:7.4-php2shell
docker push jetfueltw/nginx-php-fpm:8.2
```
