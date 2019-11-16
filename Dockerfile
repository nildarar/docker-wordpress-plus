FROM wordpress:latest

LABEL maintainer="SOHRAB NILDARAR <sohrab@nildarar.com>" \
      version="1.0"
   
RUN apt-get update && DEBIAN_FRONTEND=noninteractive
RUN apt-get install --no-install-recommends -y tidy csstidy nano netcat zlib1g-dev 
RUN apt-get install -y libxml2 libxml2-dev wget 
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/php/ext

# https://forum.mysterydata.com/topic/4/cwp-help-to-install-memcached/4
# First install libmemcached
RUN cd /usr/local/src
RUN wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz && tar -zxvf libmemcached-1.0.18.tar.gz
RUN cd libmemcached-1.0.18 && ./configure
RUN make && make install

# then install memcached from pecl
RUN cd /usr/local/src && rm -rf memcached*
RUN curl https://pecl.php.net/get/memcached -o memcached.tgz && tar -xf memcached.tgz
RUN cd memcached-* && /opt/alt/php-fpm73/usr/bin/phpize
RUN ./configure --with-php-config=/opt/alt/php-fpm73/usr/bin/php-config
RUN make && make install

RUN grep "memcached.so" /opt/alt/php-fpm73/usr/php/php.d/memcached.ini 2> /dev/null 1> /dev/null|| echo "extension=memcached.so" > /opt/alt/php-fpm73/usr/php/php.d/memcached.ini

# Install needed php extensions: memcached
#
# RUN apt-get install -y libpq-dev libmemcached-dev && \
#     curl -o memcached.tgz -SL http://pecl.php.net/get/memcached-3.0.3.tgz && \
#         tar -xf memcached.tgz -C /usr/src/php/ext/ && \
#         echo extension=memcached.so >> /usr/local/etc/php/conf.d/memcached.ini && \
#         rm memcached.tgz && \
#         mv /usr/src/php/ext/memcached-3.0.3 /usr/src/php/ext/memcached

# Install needed php extensions: memcache
#
RUN apt-get install --no-install-recommends -y unzip libssl-dev libpcre3 libpcre3-dev && \
    cd /usr/src/php/ext/ && \
    curl -sSL -o php7.zip https://github.com/websupport-sk/pecl-memcache/archive/NON_BLOCKING_IO_php7.zip && \
    unzip php7.zip && \
    mv pecl-memcache-NON_BLOCKING_IO_php7 memcache && \
    docker-php-ext-configure memcache --with-php-config=/usr/local/bin/php-config && \
    docker-php-ext-install memcache && \
    echo "extension=memcache.so" > /usr/local/etc/php/conf.d/ext-memcache.ini && \
    rm -rf /tmp/pecl-memcache-php7 php7.zip

# Install needed php extensions: zip
#
RUN apt-get install -y libz-dev && \
    curl -o zip.tgz -SL http://pecl.php.net/get/zip-1.15.1.tgz && \
        tar -xf zip.tgz -C /usr/src/php/ext/ && \
        rm zip.tgz && \
        mv /usr/src/php/ext/zip-1.15.1 /usr/src/php/ext/zip

RUN docker-php-ext-install memcached
RUN docker-php-ext-install memcache
RUN docker-php-ext-install zip
RUN docker-php-ext-install soap

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Install needed wordpress extensions: WP-FFPC
#
RUN cd /usr/src/wordpress/wp-content/plugins && \
    curl -o wp-ffpc.zip -L https://downloads.wordpress.org/plugin/wp-ffpc.zip && \
    unzip -o wp-ffpc.zip && \
    chown -R www-data:www-data wp-ffpc && \
    rm -f wp-ffpc.zip

# Cleanup
RUN rm -rf /var/lib/apt/lists/*

# ENTRYPOINT resets CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
