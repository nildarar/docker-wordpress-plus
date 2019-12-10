FROM wordpress:php7.2-apache

LABEL vendor="NILDARAR" \
      maintainer="SOHRAB NILDARAR <sohrab@nildarar.com>" \
      version="3.0"

# Install PHP extensions
RUN apt-get update && DEBIAN_FRONTEND=noninteractive && \
    apt-get upgrade -qy && \
    apt-get install --no-install-recommends -y \
      tidy \
      csstidy \
      cron \
      git \
      wget \
      libc-client-dev \
      libicu-dev \
      libkrb5-dev \
      libmcrypt-dev \
      libssl-dev \
      libz-dev \
      unzip \
      zip \
      nginx \
      nano \
      sudo \
      netcat \
      libxml2 \
      libgeoip-dev \
      libmemcached-dev \
      zlib1g-dev \
      systemd\
      libjpeg-dev \
  	libpng-dev \
      libtidy-dev \
      libbz2-dev \
      curl \
      libcurl4-openssl-dev \
      libedit-dev \
      libxml2-dev

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/cron.daily/*

RUN docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos && \
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr && \
    docker-php-ext-install imap intl mbstring mysqli pdo_mysql zip gd opcache tidy bcmath bz2 curl exif json phar simplexml soap xml xmlrpc && \
    docker-php-ext-enable imap intl mbstring mysqli pdo_mysql zip gd opcache tidy bcmath bz2 curl exif json phar simplexml soap xml xmlrpc

RUN pecl install memcached-3.0.3 && \
    docker-php-ext-enable memcached
    
RUN pecl install redis && \
    pecl install xdebug && \
    pecl install igbinary && \
    pecl install APCu &&\
    # pecl install geoip && \
    docker-php-ext-enable redis xdebug apcu igbinary

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
#
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'file_uploads=On'; \
        echo 'memory_limit=128M'; \
        echo 'upload_max_filesize=24M'; \
        echo 'post_max_size=24M'; \
        echo 'max_execution_time=600'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

# Install needed wordpress extensions: WP-FFPC
#
# RUN cd /usr/src/wordpress/wp-content/plugins && \
#     curl -o wp-ffpc.zip -L https://downloads.wordpress.org/plugin/wp-ffpc.zip && \
#     unzip -o wp-ffpc.zip && \
#     chown -R www-data:www-data wp-ffpc && \
#     rm -f wp-ffpc.zip

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
