FROM php:7.4-fpm-alpine

LABEL maintainer="Hamed dhib <hamed.dhib@leadwire.io>"

# entrypoint.sh and installto.sh dependencies
RUN set -ex; \
	\
	apk add --no-cache \
		bash \
		coreutils \
		rsync \
		tzdata

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-dev \
		imagemagick-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
		libtool \
		openldap-dev \
		postgresql-dev \
		sqlite-dev \
	; \
	\
	docker-php-ext-configure gd; \
	docker-php-ext-configure ldap; \
	docker-php-ext-install \
		exif \
		gd \
		intl \
		ldap \
		pdo_mysql \
		pdo_pgsql \
		pdo_sqlite \
		zip \
	; \
	pecl install imagick redis; \
	docker-php-ext-enable imagick opcache redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
		| tr ',' '\n' \
		| sort -u \
		| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
		)"; \
	apk add --virtual .roundcubemail-phpext-rundeps imagemagick $runDeps; \
	apk del .build-deps
 

# memcached - tested with php 7.4

# Install dependencies
RUN apk --no-cache add libmemcached-dev zlib-dev libmemcached && \
    apk --no-cache add --virtual .phpize-deps $PHPIZE_DEPS && \
    pecl install memcached && \
    docker-php-ext-enable memcached && \
    apk del .phpize-deps
    
# Install dependencies
RUN apk add --no-cache libc6-compat libstdc++

# Update the package index and install MongoDB tools
RUN apk update && \
    apk add --no-cache mongodb-tools

# Install necessary dependencies
RUN apk add --no-cache \
        autoconf \
        g++ \
        make \
        openssl-dev \
        cyrus-sasl-dev \
        libsasl \
        zlib-dev

# Install the MongoDB PHP extension
RUN pecl install mongodb && \
    docker-php-ext-enable mongodb

RUN apk update \
    && apk add --no-cache \
        php-pear \
	ca-certificates
 
RUN pear install Net_SMTP
# add composer.phar
ADD https://getcomposer.org/installer /tmp/composer-installer.php

RUN php /tmp/composer-installer.php --install-dir=/usr/local/bin/; \
	rm /tmp/composer-installer.php
