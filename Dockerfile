FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Christian Roessner <christian@roessner.email>

ARG version=4.0.8

WORKDIR /tmp/build

# Download SOPE sources
ADD https://github.com/inverse-inc/sope/archive/SOPE-${version}.tar.gz /tmp/src/SOPE/SOPE.tar.gz

# Download SOGo sources
ADD https://github.com/inverse-inc/sogo/archive/SOGo-${version}.tar.gz /tmp/src/SOGo/SOGo.tar.gz

RUN set -ex; \
  echo "Untar SOPE sources"; \
  tar -xf /tmp/src/SOPE/SOPE.tar.gz && mkdir /tmp/SOPE && mv sope-SOPE-${version}/* /tmp/SOPE/.; \
  echo "Untar SOGO sources"; \
  tar -xf /tmp/src/SOGo/SOGo.tar.gz && mkdir /tmp/SOGo && mv sogo-SOGo-${version}/* /tmp/SOGo/.; \
  echo "Install required packages"; \
  apt-get update; \
  apt-get install -qy --no-install-recommends \
      gnustep-make \
      gnustep-base-common \
      libgnustep-base-dev \
      make \
      gobjc \
      libxml2-dev \
      libssl-dev \
      libldap2-dev \
      postgresql-server-dev-10 \
      libmemcached-dev \
      libcurl4-openssl-dev \
      supervisor \
      nginx \
      tzdata; \
  echo "Compiling SOPE and SOGo"; \
  cd /tmp/SOPE;  \
  ./configure --with-gnustep --enable-debug --disable-strip; \
  make; \
  make install; \
  cd /tmp/SOGo; \
  ./configure --enable-debug --disable-strip; \
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
      libgnustep-base1.25 \
      libldap-2.4-2 \
      libmemcached11 \
      libobjc4 \
      libpq5 \
      libssl1.1 \
      libxml2 \
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
      make \
      postgresql-server-dev-10; \
  rm -rf /var/lib/apt/lists/*; \
  rm -rf /tmp/build /tmp/SOPE /tmp/SOGo /tmp/src

COPY ./supervisor/supervisord-docker.conf /etc/supervisor/supervisord-docker.conf
COPY ./supervisor/sogod.conf /etc/supervisor/conf.d/sogod.conf

COPY ./nginx/nginx-docker.conf /etc/nginx/nginx-docker.conf
COPY ./supervisor/nginx.conf /etc/supervisor/conf.d/nginx.conf

VOLUME /usr/local/lib/GNUstep/SOGo/WebServerResources

EXPOSE 80 20000

# load env
RUN . /usr/share/GNUstep/Makefiles/GNUstep.sh

CMD [ "/usr/bin/supervisord", "--configuration", "/etc/supervisor/supervisord-docker.conf" ]

