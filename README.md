# docker-nginx-php-fpm



# run
docker run --rm -p 80:80 jetfueltw/nginx-php-fpm:8.2
```

## Build linux/amd64 only

Pushing an amd64-only image replaces the tag on Docker Hub, so the tag no longer has linux/arm64.

```bash
# build and push linux/amd64 only
docker buildx build \
    --platform linux/amd64 \
    --pull --push --no-cache \
    -t jetfueltw/nginx-php-fpm:7.4-php2shell \
    7.4

# or build linux/amd64 into the local image store, test it, then push
docker buildx build \
    --platform linux/amd64 \
    --pull --load --no-cache \
    -t jetfueltw/nginx-php-fpm:7.4-php2shell \
    7.4
docker image inspect jetfueltw/nginx-php-fpm:7.4-php2shell --format '{{.Os}}/{{.Architecture}}'
docker push jetfueltw/nginx-php-fpm:7.4-php2shell
```

<!--
# verify platforms
docker buildx imagetools inspect jetfueltw/nginx-php-fpm:7.4-php2shell

# verify php version and modules
docker run --rm --entrypoint sh jetfueltw/nginx-php-fpm:8.2 -c 'php -v; php -m'
docker run --rm --entrypoint sh jetfueltw/nginx-php-fpm:7.4-php2shell -c 'php -v; php -m'

# verify the PHP2Shell fix (expect 1)
docker run --rm --platform linux/amd64 --entrypoint sh jetfueltw/nginx-php-fpm:7.4-php2shell -c 'grep -c zend_new_array_singleton /usr/local/sbin/php-fpm'
-->
