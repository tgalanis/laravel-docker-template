FROM php:8.3-fpm

# Match www-data UID/GID to host user so volume permissions work seamlessly
ARG UID=1000
ARG GID=1000
RUN groupmod -g $GID www-data && usermod -u $UID www-data

# System dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip bash \
    libpng-dev libonig-dev libxml2-dev libzip-dev libpq-dev && \
    docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl bcmath gd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Redis + Xdebug extensions
RUN pecl install redis xdebug && docker-php-ext-enable redis

# Xdebug config (only active when XDEBUG_MODE != off)
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Laravel installer into /usr/local so all users can access it
ENV COMPOSER_HOME=/usr/local/composer
RUN composer global require laravel/installer && \
    ln -s /usr/local/composer/vendor/bin/laravel /usr/local/bin/laravel

# NVM + Node LTS (installed system-wide under /usr/local/nvm)
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | NVM_DIR=$NVM_DIR bash && \
    bash -c "source $NVM_DIR/nvm.sh && nvm install --lts && nvm alias default node"

# Symlink node/npm/npx into /usr/local/bin so they're available without sourcing nvm
RUN NODE_BIN=$(ls -d $NVM_DIR/versions/node/*/bin | tail -1) && \
    ln -s $NODE_BIN/node /usr/local/bin/node && \
    ln -s $NODE_BIN/npm  /usr/local/bin/npm  && \
    ln -s $NODE_BIN/npx  /usr/local/bin/npx

# NVM available in interactive shells
RUN echo "export NVM_DIR=$NVM_DIR" >> /etc/bash.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/bash.bashrc

WORKDIR /var/www

USER www-data

EXPOSE 9000
CMD ["php-fpm"]
