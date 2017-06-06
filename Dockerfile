FROM centos:7

MAINTAINER mebar

#LABEL maintainer=info@webdevops.io \
#      vendor=WebDevOps.io \
#      io.webdevops.layout=8 \
#      io.webdevops.version=1.5.0

ENV TERM="xterm" \
    LANG="en_US.utf8" \
    LC_ALL="en_US.utf8"

ADD baselayout.tar /

# Init bootstrap
RUN set -x \
    # System update
    && /usr/local/bin/yum-upgrade \
    && /usr/local/bin/yum-install \
        epel-release \
    && /usr/local/bin/generate-dockerimage-info \
    # Install gosu
    && GOSU_VERSION=1.10 \
    && /usr/local/bin/yum-install gpg wget \
    && dpkgArch="amd64" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    ## Install go-replace
    && GOREPLACE_VERSION=1.1.2 \
    && wget -O /usr/local/bin/go-replace https://github.com/webdevops/goreplace/releases/download/$GOREPLACE_VERSION/gr-64-linux \
    && chmod +x /usr/local/bin/go-replace \
    && yum erase -y wget \
    && docker-image-cleanup

##base

ENV DOCKER_CONF_HOME=/opt/docker/ \
    LOG_STDOUT="" \
    LOG_STDERR=""

COPY conf/ /opt/docker/

# Install services
RUN chmod +x /opt/docker/bin/* \
    && /usr/local/bin/yum-install \
        supervisor \
        wget \
        curl \
        net-tools \
    && chmod +s /usr/local/bin/gosu \
    && /opt/docker/bin/bootstrap.sh \
    && docker-image-cleanup

##base-app

ENV APPLICATION_USER=application \
    APPLICATION_GROUP=application \
    APPLICATION_PATH=/app \
    APPLICATION_UID=1000 \
    APPLICATION_GID=1000

##COPY conf/ /opt/docker/

# Install services
RUN /usr/local/bin/yum-install \
        # Install tools
        zip \
        unzip \
        bzip2 \
        moreutils \
        dnsutils \
        bind-utils \
        rsync \
        git \
    && /usr/local/bin/generate-locales \
    && /opt/docker/bin/bootstrap.sh \
    && docker-image-cleanup


##php

ENV WEB_DOCUMENT_ROOT=/app \
    WEB_DOCUMENT_INDEX=index.php \
    WEB_ALIAS_DOMAIN=*.vm

#COPY conf/ /opt/docker/

# Install php environment
RUN /usr/local/bin/yum-install \
        # Install tools
        ImageMagick \
        GraphicsMagick \
        ghostscript \
        # Install php (cli/fpm)
        php-cli \
        php-fpm \
        php-json \
        php-intl \
        php-curl \
        php-mysqlnd \
        php-memcached \
        php-mcrypt \
        php-gd \
        php-mbstring \
        php-bcmath \
        php-soap \
        sqlite \
        php-xmlrpc \
        php-xsl \
        geoip \
        php-ldap \
        php-memcache \
        php-pecl-redis \
        ImageMagick \
        ImageMagick-devel \
        ImageMagick-perl \
        php-pear \
        php-pecl-apcu \
        php-devel \
        gcc \
        php-pear \
    && pear channel-update pear.php.net \
    && pear upgrade-all \
    && pear config-set auto_discover 1 \
    && pecl install imagick \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer \
    # Cleanup
    && yum erase -y php-devel gcc \
    # Enable php services
    && docker-service-enable syslog cron \
    && /opt/docker/bin/bootstrap.sh \
    && docker-image-cleanup

#EXPOSE 9000

##nginx

ENV WEB_DOCUMENT_ROOT=/app \
    WEB_DOCUMENT_INDEX=index.php \
    WEB_ALIAS_DOMAIN=*.vm
ENV WEB_PHP_SOCKET=127.0.0.1:9000

COPY conf/ /opt/docker/

# Install tools
RUN /usr/local/bin/yum-install \
        nginx \
    && /opt/docker/bin/bootstrap.sh \
    && docker-image-cleanup


ENTRYPOINT ["/entrypoint"]

CMD ["supervisord"]

EXPOSE 80 443


