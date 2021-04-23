FROM debian:10

ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Christian Roessner <christian@roessner.email>

ARG version=5.1.0
ARG wbxml_version=0.11.6

WORKDIR /tmp/build

# Download SOPE sources
ADD https://github.com/inverse-inc/sope/archive/SOPE-${version}.tar.gz /tmp/src/SOPE/SOPE.tar.gz

# Download SOGo sources
ADD https://github.com/inverse-inc/sogo/archive/SOGo-${version}.tar.gz /tmp/src/SOGo/SOGo.tar.gz

# For ActiveSync - libwbxml
ADD https://github.com/libwbxml/libwbxml/archive/libwbxml-${wbxml_version}.tar.gz /tmp/src/wbxml2.tar.gz

RUN set -ex; \
  echo "Untar SOPE sources"; \
  tar -xf /tmp/src/SOPE/SOPE.tar.gz && mkdir /tmp/SOPE && mv sope-SOPE-${version}/* /tmp/SOPE/.; \
  echo "Untar SOGO sources"; \
  tar -xf /tmp/src/SOGo/SOGo.tar.gz && mkdir /tmp/SOGo && mv sogo-SOGo-${version}/* /tmp/SOGo/.; \
  echo "Untar wbxml sources"; \
  tar -xf /tmp/src/wbxml2.tar.gz && mkdir /tmp/wbxml2 && mv libwbxml-libwbxml-${wbxml_version}/* /tmp/wbxml2/.; \
  echo "Install required packages"; \
  apt-get update; \
  apt-get install -qy --no-install-recommends \
      gnustep-make \
      gnustep-base-common \
      libgnustep-base-dev \
      make \
      cmake \
      gobjc \
      libxml2-dev \
      libexpat1-dev \
      libssl-dev \
      libldap2-dev \
      zlib1g-dev \
      postgresql-server-dev-11 \
      libmemcached-dev \
      libsodium-dev \
      libzip-dev \
      liboath-dev \
      libcurl4-openssl-dev \
      supervisor \
      nginx \
      tzdata \
      ca-certificates \
      netcat-traditional \
      postfix; \
  echo "Compiling SOPE and SOGo"; \
  cd /tmp/SOPE;  \
  ./configure --with-gnustep --enable-debug --disable-strip; \
  make; \
  make install; \
  cd /tmp/SOGo; \
  ./configure --enable-debug --enable-mfa --disable-strip; \
  make; \
  make install; \
  echo "Building wbxml"; \
  cd /tmp/wbxml2; \
  cmake . -B/tmp/build/libwbxml; \
  cd /tmp/build/libwbxml; \
  make; \
  make install; \
  echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf; \
  ldconfig; \
  ln -s /usr/local/include/libwbxml-1.0/wbxml /usr/include; \
  echo "Building ActiveSync"; \
  cd /tmp/SOGo/ActiveSync; \
  make; \
  make install; \
  echo "Register SOGo library"; \
  echo "/usr/local/lib/sogo" > /etc/ld.so.conf.d/sogo.conf; \
  ldconfig; \
  echo "Create user sogo"; \
  groupadd --system --gid 999 sogo && useradd --system --uid 999 --gid sogo sogo; \
  echo "Create directories and enforce permissions"; \
  install -o sogo -g sogo -m 755 -d /run/sogo; \
  install -o sogo -g sogo -m 750 -d /var/spool/sogo; \
  echo "Removing unused files and directories"; \
  apt-mark manual \
      gnustep-make \
      libcurl4 \
      libgcc1 \
      libglib2.0-0 \
      libgnustep-base1.26 \
      libldap-2.4-2 \
      libmemcached11 \
      libsodium23 \
      libzip4 \
      liboath0 \
      libobjc4 \
      libpq5 \
      libssl1.1 \
      libxml2 \
      zlib1g \
      postgresql-client-common \
      postgresql-common > /dev/null; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
      gobjc \
      libcurl4-openssl-dev \
      libgnustep-base-dev \
      libldap2-dev \
      libmemcached-dev \
      libssl-dev \
      libxml2-dev \
      libexpat1-dev \
      zlib1g-dev \
      make \
      cmake \
      postgresql-server-dev-11; \
  rm -rf /var/lib/apt/lists/*; \
  rm -rf /tmp/build /tmp/SOPE /tmp/SOGo /tmp/wbxml2 /tmp/src

COPY ./supervisor/supervisord-docker.conf /etc/supervisor/supervisord-docker.conf
COPY ./supervisor/sogod.conf /etc/supervisor/conf.d/sogod.conf

COPY ./nginx/nginx-docker.conf /etc/nginx/nginx-docker.conf
COPY ./supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY ./supervisor/postfix.conf /etc/supervisor/conf.d/postfix.conf

COPY ./run.sh /

VOLUME [ "/usr/local/lib/GNUstep/SOGo/WebServerResources", "/var/spool/postfix" ]

EXPOSE 80 20000

# load env
RUN . /usr/share/GNUstep/Makefiles/GNUstep.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD printf "EHLO healthcheck\n" | nc 127.0.0.1 587 | grep -qE "^220.*ESMTP"

CMD [ "/bin/sh", "-c", "/run.sh" ]

