# docker-nginx-php-fpm

```bash
# login (required by --push)
docker login

# create a multi-arch builder (or switch to it if it already exists: docker buildx use multiarch)
docker buildx create --name multiarch --driver docker-container --bootstrap --use

# build and push php7.4 (compiled from source with the PHP2Shell fix: CVE-2026-109618, CVE-2026-109619)
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --pull --push --no-cache \
    -t jetfueltw/nginx-php-fpm:7.4 \
    7.4

# build and push php8.2
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --pull --push --no-cache \
    -t jetfueltw/nginx-php-fpm:8.2 \
    8.2

# run
docker run --rm -p 80:80 jetfueltw/nginx-php-fpm:7.4
```

## Build linux/amd64 only

Pushing an amd64-only image replaces the tag on Docker Hub, so the tag no longer has linux/arm64.

```bash
# build and push linux/amd64 only
docker buildx build \
    --platform linux/amd64 \
    --pull --push --no-cache \
    -t jetfueltw/nginx-php-fpm:7.4 \
    7.4

# or build linux/amd64 into the local image store, test it, then push
docker buildx build \
    --platform linux/amd64 \
    --pull --load --no-cache \
    -t jetfueltw/nginx-php-fpm:7.4 \
    7.4
docker image inspect jetfueltw/nginx-php-fpm:7.4 --format '{{.Os}}/{{.Architecture}}'
docker push jetfueltw/nginx-php-fpm:7.4
```

# Test local build

```bash
# build the local image for testing
docker build --pull -t jetfueltw/nginx-php-fpm:7.4-local 7.4

docker run --rm jetfueltw/nginx-php-fpm:7.4-local php -v
docker run --rm jetfueltw/nginx-php-fpm:7.4-local php -m
docker run --rm jetfueltw/nginx-php-fpm:7.4-local php -i > phpinfo.txt
docker run --rm jetfueltw/nginx-php-fpm:7.4-local cat /usr/local/etc/php/php.ini > php.ini

# verify the PHP2Shell fix (expect 1)
docker run --rm jetfueltw/nginx-php-fpm:7.4-local sh -c 'grep -c zend_new_array_singleton /usr/local/sbin/php-fpm'
```
