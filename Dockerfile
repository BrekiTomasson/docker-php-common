FROM php:7.3

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

#############################################################################
### Step the first, installing all the core tools and things we need from ###
### APT. There are a number of things in here that are included because   ###
### they are good to have, but over time it's quite likely that I'll move ###
### them from here to whatever container needs them - especially if there ###
### are packages installed here that only get used in one other container ###
### or something like that. Again, something to decide in the future.     ###
#############################################################################

RUN apt update \
 && apt install -q -y \
      apt-utils \
      curl \
      dialog \
      gifsicle \
      git \
      imagemagick \
      jpegoptim \
      libcurl4-openssl-dev \
      libedit-dev \
      libfreetype6-dev \
      libicu-dev \
      libjpeg-dev \
      libmagickwand-dev \
      libmcrypt-dev \
      libmemcached-dev \
      libpng-dev \
      libpq-dev \
      libsqlite3-dev \
      libssl-dev \
      libxml2-dev \
      libz-dev \
      libzip-dev \
      nano \
      optipng \
      pngquant \
      procps \
      python3 \
      sqlite \
      sqlite3 \
      supervisor \
      unzip \
      vim \
      wget \
      zlib1g-dev

#############################################################################
### Debian packages an ancient version of Node, so let's make things more ###
### modern by downloading and installing Node v12 instead. That should be ###
### a bit more useful to us, don't you think?                             ###
#############################################################################

RUN curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh \
  && bash nodesource_setup.sh \
  && apt install nodejs

#############################################################################
### docker-php-ext-install is a great tool for when it comes to getting a ###
### PHP extension installed on a docker-container. It can be so much work ###
### just go get them installed - but this little tool takes the hard work ###
### out of your hands and just Gets. Things. Done.                        ###
#############################################################################

RUN docker-php-ext-install \
      bcmath \
      bz2 \
      dba \
      exif \
      gd \
      mysqli \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      phar \
      soap \
      sockets \
      xml \
      xmlrpc \
      zip \
 && pecl install redis \
 && docker-php-ext-enable redis

#############################################################################
### We're also going to need to install Composer so that we can get those ###
### third party PHP packages installed - instead of copying them all into ###
### a container, we want to just copy the composer.json file and have the ###
### docker container install the packages for us.                         ###
#############################################################################

RUN curl -s http://getcomposer.org/installer | php && \
  echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc && \
  mv composer.phar /usr/local/bin/composer

#############################################################################
### Last, but not least, we install a few of global packages from NPM and ###
### Composer that will be of use to us in whatever development work it is ###
### we're about to get done.                                              ###
#############################################################################

RUN composer global require friendsofphp/php-cs-fixer matt-allan/laravel-code-style friendsofphp/php-cs-fixer hirak/prestissimo --sort-packages --optimize-autoloader \
 && npm install --global eslint jest eslint-config-breki

#############################################################################
### We're coming up on the end here so there's really only one more thing ###
### left for us to do - and that is to clean up the mess we've made as we ###
### got verything installed. Docker is generally pretty good at this, and ###
### we really don't have much to remove or clean out.                     ###
#############################################################################

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
  && rm /var/log/lastlog /var/log/faillog \
  && apt-get clean \
  && chmod -R 777 /tmp
