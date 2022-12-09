FROM ubuntu:22.04

ENV NETATALK_VERSION=3.1.13
ENV DEBIAN_FRONTEND=noninteractive

COPY ./patches /patches

RUN apt-get update &&\
        apt-get upgrade --yes &&\
        apt-get install --no-install-recommends --fix-missing --assume-yes \
        avahi-daemon \
        build-essential \
        curl \
        file \
        libacl1-dev \
        libavahi-client-dev \
        libcrack2-dev \
        libdb-dev \
        libdbus-1-dev \
        libdbus-glib-1-dev \
        libevent-dev \
        libgcrypt20 \
        libgcrypt20-dev \
        libglib2.0-dev \
        libkrb5-dev \
        libldap2-dev \
        libmysqlclient-dev \
        libpam0g-dev \
        libssl-dev \
        libtdb-dev \
        libtracker-sparql-3.0-dev \
        libwrap0-dev \
        systemtap-sdt-dev \
        tracker

RUN curl -sSL "http://ufpr.dl.sourceforge.net/project/netatalk/netatalk/${NETATALK_VERSION}/netatalk-${NETATALK_VERSION}.tar.gz" | tar xvz

WORKDIR netatalk-${NETATALK_VERSION}

RUN patch -p1 < /patches/cnid_mysql.patch
RUN ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-init-style=debian-systemd \
        --without-libevent \
        --without-tdb \
        --with-cracklib \
        --enable-krbV-uam \
        --with-pam-confdir=/etc/pam.d \
        --with-dbus-sysconf-dir=/etc/dbus-1/system.d \
        --with-tracker-pkgconfig-version=1.0 &&\
        make &&\
        make install

RUN apt-get purge --quiet --yes --auto-remove \
        # Remove build time deps
        libevent-dev \
        libssl-dev \
        libgcrypt20-dev \
        libkrb5-dev \
        libpam0g-dev \
        libwrap0-dev \
        libdb-dev \
        libtdb-dev \
        libmysqlclient-dev \
        libavahi-client-dev \
        libacl1-dev \
        libldap2-dev \
        libcrack2-dev \
        systemtap-sdt-dev \
        libdbus-1-dev \
        libdbus-glib-1-dev \
        libglib2.0-dev \
        libtracker-sparql-3.0-dev &&\
        # Install some run-time deps
        apt-get install --yes \
        libevent-2.1-7 \
        libavahi-client3 \
        libevent-core-2.1-7 \
        libwrap0 \
        libtdb1 \
        libmysqlclient21 \
        libcrack2 \
        libdbus-glib-1-2

# Remove anything that isn't needed in runtime
RUN apt-get autoclean --quiet --yes &&\
        apt-get autoremove --quiet --yes &&\
        apt-get clean --quiet --yes  &&\
        rm -rf /netatalk* &&\
        rm -rf /usr/share/man &&\
        rm -rf /usr/share/doc &&\
        rm -rf /usr/share/icons &&\
        rm -rf /usr/share/poppler &&\
        rm -rf /usr/share/mime &&\
        rm -rf /usr/share/GeoIP &&\
        rm -rf /var/lib/apt/lists* &&\
        rm -rf /patches /netatalk/* &&\
        mkdir /media/share

# Restore DEBIAN_FRONTEND
ENV DEBIAN_FRONTEND=

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY afp.conf /etc/afp.conf
CMD ["/docker-entrypoint.sh"]
