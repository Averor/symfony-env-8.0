FROM php:8.0-apache

RUN echo "Europe/Warsaw" > /etc/timezone && cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN a2enmod rewrite

RUN apt-get update && apt-get install -y --fix-missing

RUN apt-get install -y \
    locales \
    nano \
    git \
    libxml2 libxml2-dev \
    sqlite3 \
    zip unzip \
    zlib1g-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    libzip-dev \
    libpq-dev \
    ssl-cert \
    sudo \
    moreutils

RUN    sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=pl_PL.UTF-8

ENV LANG pl_PL.UTF-8
ENV LANGUAGE pl_PL:en
ENV LC_ALL pl_PL.UTF-8

RUN a2enmod ssl \
 && a2ensite default-ssl

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# XDebug
RUN    curl -fsSL "http://xdebug.org/files/xdebug-3.1.1.tgz" -o xdebug.tar.gz \
    && mkdir -p /tmp/xdebug \
    && tar -xf xdebug.tar.gz -C /tmp/xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && docker-php-ext-configure /tmp/xdebug --enable-xdebug \
    && docker-php-ext-install /tmp/xdebug \
    && rm -r /tmp/xdebug

RUN echo 'zend_extension=xdebug.so \n\
         xdebug.remote_enable=1 \n\
         xdebug.mode=debug \n\
         xdebug.remote=debug \n\
         xdebug.client_port="9003" \n\
         xdebug.client_host=host.docker.internal' > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN docker-php-ext-install bcmath
RUN docker-php-ext-install curl
RUN docker-php-ext-install iconv
RUN docker-php-ext-install intl
RUN docker-php-ext-install opcache
RUN docker-php-ext-install pcntl
RUN docker-php-ext-install pdo
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install session
RUN docker-php-ext-install soap
RUN docker-php-ext-install xml
RUN docker-php-ext-install zip

RUN docker-php-ext-enable xdebug

RUN usermod -u 1000 www-data
RUN usermod -G www-data www-data

RUN mkdir /var/www/html/var && chmod -R 770 /var/www/html/var
RUN mkdir /var/www/html/var/cache && chmod -R 770 /var/www/html/var/cache

WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443

CMD ["apache2-foreground"]
