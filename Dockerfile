ARG PHP_VER=7.3
FROM wordpress:php${PHP_VER}-apache
MAINTAINER nildarar
      
ARG PHP_VER

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
      libzip-dev \
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

RUN pecl install memcached-3.1.3 && \
    docker-php-ext-enable memcached
    
RUN pecl install redis && \
    pecl install xdebug && \
    pecl install igbinary && \
    pecl install APCu &&\
    # pecl install geoip && \
    docker-php-ext-enable redis xdebug apcu igbinary
    
# Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/
RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ && \
	php_ext_dir="$(php -i | grep extension_dir | head -n1 | awk '{print $3}')" && \
	mv /tmp/ioncube/ioncube_loader_lin_${PHP_VER}.so "${php_ext_dir}/" && \
    echo "zend_extension = $php_ext_dir/ioncube_loader_lin_${PHP_VER}.so" \
        > /usr/local/etc/php/conf.d/00-ioncube.ini && \
	rm /tmp/ioncube_loaders_lin_x86-64.tar.gz && \
	rm -rf /tmp/ioncube

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

# Increase Upload and Memory Limit
RUN { \
        echo 'file_uploads=On'; \
        echo 'memory_limit=256M'; \
        echo 'upload_max_filesize=24M'; \
        echo 'post_max_size=24M'; \
        echo 'max_execution_time=600'; \
    } > /usr/local/etc/php/conf.d/custom-limits.ini
  
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
