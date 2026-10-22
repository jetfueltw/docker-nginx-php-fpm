#
# Stage "php": rebuild of docker-library/php 7.4/alpine3.16/fpm (b9f1715) with the PHP2Shell fix applied
# https://github.com/docker-library/php/blob/b9f17156020c3aef71df681b27684533529347a7/7.4/alpine3.16/fpm/Dockerfile
#
FROM alpine:3.16 AS php

# dependencies required for running "phpize"
# these get automatically installed and removed by "docker-php-ext-*" (unless they're already installed)
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c

# persistent / runtime deps
RUN apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
# https://github.com/docker-library/php/issues/494
		openssl

# ensure www-data user exists
RUN set -eux; \
	adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
	[ ! -d /var/www/html ]; \
	mkdir -p /var/www/html; \
	chown www-data:www-data /var/www/html; \
	chmod 777 /var/www/html

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

ENV GPG_KEYS 42670A7FE4D0441C8E4632349E4FDC074A4EF02D 5A52880781F755608BF815FC910DEB46F53EA312

ENV PHP_VERSION 7.4.33
ENV PHP_URL="https://www.php.net/distributions/php-7.4.33.tar.xz" PHP_ASC_URL="https://www.php.net/distributions/php-7.4.33.tar.xz.asc"
ENV PHP_SHA256="924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927"

# Download the PHP source tarball and verify its checksum and GPG signature
RUN set -eux; \
	\
	apk add --no-cache --virtual .fetch-deps gnupg; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	curl -fsSL -o php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apk del --no-network .fetch-deps

# PHP2Shell (CVE-2026-109618, CVE-2026-109619) fix from the official PHP-7.4-CVE-2026-109618-109619 branch
# https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
ENV PHP2SHELL_PATCH_SHA256="5fe57ca6ee96d59b36c6e0ca842843c50884f177bef1e85234cf669b577f5e48"
COPY php/php2shell.patch /usr/src/

COPY php/docker-php-source /usr/local/bin/

RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		argon2-dev \
		coreutils \
		curl-dev \
		gnu-libiconv-dev \
		libsodium-dev \
		libxml2-dev \
		linux-headers \
		oniguruma-dev \
		openssl-dev \
		patch \
		readline-dev \
		sqlite-dev \
	; \
	\
# make sure musl's iconv doesn't get used (https://www.php.net/manual/en/intro.iconv.php)
	rm -vf /usr/include/iconv.h; \
# PHP < 8 doesn't know to look deeper for GNU libiconv: https://github.com/php/php-src/commit/b480e6841ecd5317faa136647a2b8253a4c2d0df
	ln -sv /usr/include/gnu-libiconv/*.h /usr/include/; \
	\
	export \
		CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	; \
	docker-php-source extract; \
	cd /usr/src/php; \
# verify and apply the PHP2Shell fix before configuring
	echo "$PHP2SHELL_PATCH_SHA256 */usr/src/php2shell.patch" | sha256sum -c -; \
	patch -p1 < /usr/src/php2shell.patch; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		\
# make sure invalid --configure-flags are fatal errors instead of just warnings
		--enable-option-checking=fatal \
		\
# https://github.com/docker-library/php/issues/439
		--with-mhash \
		\
# https://github.com/docker-library/php/issues/822
		--with-pic \
		\
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
		--enable-ftp \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
		--enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
		--enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash
		--with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
		--with-sodium=shared \
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
		--with-pdo-sqlite=/usr \
		--with-sqlite3=/usr \
		\
		--with-curl \
		--with-iconv=/usr \
		--with-openssl \
		--with-readline \
		--with-zlib \
		\
# https://github.com/bwoebi/phpdbg-docs/issues/1#issuecomment-163872806 ("phpdbg is primarily a CLI debugger, and is not suitable for debugging an fpm stack.")
		--disable-phpdbg \
		\
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
		--with-pear \
		\
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/bullseye/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
		$(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
		\
		--disable-cgi \
		\
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
	; \
	make -j "$(nproc)"; \
	find -type f -name '*.a' -delete; \
	make install; \
	find \
		/usr/local \
		-type f \
		-perm '/0111' \
		-exec sh -euxc ' \
			strip --strip-all "$@" || : \
		' -- '{}' + \
	; \
	make clean; \
	\
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
	cp -v php.ini-* "$PHP_INI_DIR/"; \
	\
	cd /; \
	docker-php-source delete; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache $runDeps; \
	\
	apk del --no-network .build-deps; \
	\
# update pecl channel definitions https://github.com/docker-library/php/issues/443
	pecl update-channels; \
	rm -rf /tmp/pear ~/.pearrc; \
	\
# smoke test
	php --version

COPY php/docker-php-ext-* php/docker-php-entrypoint /usr/local/bin/

# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN docker-php-ext-enable sodium

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
	cd /usr/local/etc; \
	sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
	cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
	{ \
		echo '[global]'; \
		echo 'error_log = /proc/self/fd/2'; \
		echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
		echo; \
		echo '[www]'; \
		echo '; if we send this to /proc/self/fd/1, it never appears'; \
		echo 'access.log = /proc/self/fd/2'; \
		echo; \
		echo 'clear_env = no'; \
		echo; \
		echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
		echo 'catch_workers_output = yes'; \
		echo 'decorate_workers_output = no'; \
	} | tee php-fpm.d/docker.conf; \
	{ \
		echo '[global]'; \
		echo 'daemonize = no'; \
		echo; \
		echo '[www]'; \
		echo 'listen = 9000'; \
	} | tee php-fpm.d/zz-docker.conf

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

#
# Stage "app": nginx + php-fpm on top of the patched PHP
#
FROM php

LABEL org.opencontainers.image.description="PHP 7.4.33 with PHP2Shell fix (CVE-2026-109618, CVE-2026-109619)"

RUN set -ex \
 && apk update && apk upgrade \
 # install package
 && apk add --no-cache freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev libzip-dev \
    git nginx supervisor \
 # install php extension
 && docker-php-ext-configure gd \
    --with-freetype=/usr/include/ \
    --with-jpeg=/usr/include/ \
    --with-webp=/usr/include/ \
 && docker-php-ext-install opcache bcmath gd zip pdo_mysql \
 # install php extension via pecl install
 && apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
 && pecl install redis \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable redis \
 && apk del .phpize-deps

RUN set -ex \
 # install composer
 && EXPECTED_COMPOSER_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig) \
 && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === '${EXPECTED_COMPOSER_SIGNATURE}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php --install-dir=/usr/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"

RUN set -ex \
 # use the default production configuration
 && cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini  \
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

# https://github.com/moby/moby/issues/34819
COPY start.sh /start.sh
RUN chmod +x /start.sh;

# test phpinfo
#COPY --chown=www-data:www-data app /var/www/app

WORKDIR /var/www/app

EXPOSE 80
CMD ["/start.sh"]
