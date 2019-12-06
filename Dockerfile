FROM php:7.4

ENV DEBIAN_FRONTEND noninteractive
ENV TERM            xterm-256color
ENV XDEBUG_VERSION  2.8.0beta2

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

#############################################################################
### This command fixes a couple of the annoyances that appear when you're ###
### using a Debian-based system as your base image - which the PHP images ###
### do. It instructs debconf to store an answer for what frontend to use, ###
### replying 'Noninteractive' to each question. This is going to remove a ###
### whole lot of warnings and potential error messages that you would see ###
### when building your Docker images. Why this is not automaticaly picked ###
### up on by Debian when it sees that it's being deployed in a container, ###
### I will never know...                                                  ###
#############################################################################

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#############################################################################
### Step the first, installing all the core tools and things we need from ###
### APT. There are a number of things in here that are included because I ###
### enjoy having them around, even if I rarely use them. Several of these ###
### will most likely be removed from this listing down the line, as I get ###
### more clever about them and move the dependency to the required Docker ###
### container that needs it rather than having it here in the base image. ###
#############################################################################


WORKDIR /tmp

RUN apt update && apt install -y \
      apt-utils \
      automake \
      build-essential \
      curl \
      dialog \
      gcc \
      gifsicle \
      git \
      imagemagick \
      jpegoptim \
      libbz2-dev \
      libc-client-dev \
      libcurl4-openssl-dev \
      libedit-dev \
      libfreetype6-dev \
      libgmp-dev \
      libicu-dev \
      libjpeg-dev \
      libjpeg62-turbo-dev \
      libkrb5-dev \
      libldap2-dev \
      libmagickwand-dev \
      libncurses5-dev \
      libpng-dev \
      libpq-dev \
      libpspell-dev \
      libsqlite3-dev \
      libssl-dev \
      libtidy-dev \
      libtiff-dev \
      libwebp-dev \
      libxml2-dev \
      libxslt-dev \
      libz-dev \
      libzip-dev \
      locales \
      make \
      nano \
      netcat \
      optipng \
      pkgconf \
      pngquant \
      procps \
      python3 \
      sqlite \
      sqlite3 \
      supervisor \
      unzip \
      vim \
      wget \
      zlib1g-dev \
 && apt autoremove -y -q \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Instead of docker-php-ext-install, we're using a new and improved #
# piece of software called install-php-extensions - very nice! It's #
# pretty much the same as docker-php-ext-install but it's got a few #
# extra bells and whistles that we can enjoy.                       #

RUN chmod uga+x /usr/local/bin/install-php-extensions \
 && sync \
 && install-php-extensions \
      pdo_mysql  \
      pdo_pgsql  \
      gmp        \
      bcmath     \
      pcntl      \
      ldap       \
      sysvmsg    \
      exif       \
      xdebug     \
      imagick    \
      igbinary   \
      redis      \
      zip        \
      bz2        \
      dba        \
      intl       \
      mysqli     \
      pgsql      \
      soap       \
      sockets    \
      xmlrpc

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd

# PHP Code Sniffer isn't something you need in all your installations, but #
# I find it better to have it available when you need it rather than being #
# forced to find it and install it when the time comes that you decide you #
# want to have it around. And it's not a massive extra size requirement to #
# strain the container with - at least not when we have all of these other #
# things installed already.                                                #

RUN curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod 755 phpcs.phar \
    && mv phpcs.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/phpcs.phar /usr/local/bin/phpcs \
    && curl -OL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod 755 phpcbf.phar \
    && mv phpcbf.phar /usr/local/bin/ \
    && ln -s /usr/local/bin/phpcbf.phar /usr/local/bin/phpcbf

#############################################################################
### Debian packages an ancient version of Node, so let's make things more ###
### modern by downloading and installing Node v12 instead. That should be ###
### a bit more useful to us, don't you think?                             ###
#############################################################################

RUN curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh \
  && bash nodesource_setup.sh \
  && apt install nodejs

#############################################################################
### We're also going to need to install Composer so that we can get those ###
### third party PHP packages installed - instead of copying them all into ###
### a container, we want to just copy the composer.json file and have the ###
### docker container install the packages for us.                         ###
#############################################################################

RUN curl -sS http://getcomposer.org/installer | php \
 && echo "export PATH=${PATH}:~/.composer/vendor/bin" >> ~/.bashrc \
 && echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc \
 && mv composer.phar /usr/local/bin/composer \
 && composer self-update

# Composer and XDebug don't play very nice with each other, so we want to #
# disable XDebug from interfering with whatever it is Composer decides to #
# do. Down the line, we might add more exceptions to this list as well.   #

RUN sed -i "s/zend_extension=/#zend_extension=/g" /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

#############################################################################
### Last, but not least, we install a few of global packages from NPM and ###
### Composer that will be of use to us in whatever development work it is ###
### we're about to get done.                                              ###
#############################################################################

RUN composer global require hirak/prestissimo --no-plugins --no-scripts --prefer-dist

# And once Prestissimo is in, let's get the other ones!

RUN composer global require \
      friendsofphp/php-cs-fixer \
      matt-allan/laravel-code-style \
      friendsofphp/php-cs-fixer \
      phpunit/phpunit \
      localheinz/composer-normalize \
      --no-plugins --no-scripts --prefer-dist

# No global packages from NPM as of yet. Watch this space! #

#############################################################################
### We're coming up on the end here so there's really only one more thing ###
### left for us to do - and that is to clean up the mess we've made as we ###
### got verything installed. Docker is generally pretty good at this, and ###
### we really don't have much to remove or clean out.                     ###
#############################################################################

RUN rm -rf /var/lib/apt/lists/* /usr/share/doc/* \
  && rm /var/log/lastlog /var/log/faillog \
  && apt-get autoremove -y \
  && rm -rf /tmp/* /var/tmp/* \
  && apt-get clean \
  && chmod -R 777 /tmp
