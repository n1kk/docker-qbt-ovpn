FROM ubuntu:20.04
MAINTAINER n1kk

VOLUME /downloads
VOLUME /config

ENV DEBIAN_FRONTEND noninteractive

RUN usermod -u 99 nobody

# Update packages and install software
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-utils openssl \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:qbittorrent-team/qbittorrent-stable \
    && apt-get update \
    && apt-get install -y qbittorrent-nox openvpn cron curl moreutils net-tools dos2unix kmod iptables ipcalc unrar \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add configuration and scripts
ADD openvpn/ /etc/openvpn/
ADD qbittorrent/ /etc/qbittorrent/

RUN chmod 0744 /etc/openvpn/ovpn-restart.sh
RUN chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh

# Copy cron file to the cron.d directory
COPY openvpn/ovpn-cron /etc/cron.d/ovpn-cron
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/ovpn-cron
# Apply cron job
RUN crontab /etc/cron.d/ovpn-cron

# Expose ports and run
EXPOSE 8080
EXPOSE 8999
EXPOSE 8999/udp

CMD cron && tail -f /var/log/cron.log

# -------------

ENV DANTE_VER 1.4.2
ENV DANTE_URL https://www.inet.no/dante/files/dante-$DANTE_VER.tar.gz
ENV DANTE_SHA 4c97cff23e5c9b00ca1ec8a95ab22972813921d7fbf60fc453e3e06382fc38a7
ENV DANTE_FILE dante.tar.gz
ENV DANTE_TEMP dante
ENV DANTE_DEPS build-essential curl

RUN set -xe \
    && apt-get update \
    && apt-get install -y $DANTE_DEPS dumb-init \
    && mkdir $DANTE_TEMP \
    && cd $DANTE_TEMP \
    && curl -sSL $DANTE_URL -o $DANTE_FILE \
    && echo "$DANTE_SHA *$DANTE_FILE" | sha256sum -c \
    && tar xzf $DANTE_FILE --strip 1 \
    && ./configure \
    && make install \
    && cd .. \
    && rm -rf $DANTE_TEMP \
    && apt-get purge -y --auto-remove $DANTE_DEPS \
    && useradd -u 912 -U -d /config -s /bin/false sockd \
    && rm -rf /var/lib/apt/lists/*

# Default configuration
COPY sockd/sockd.conf /etc/

EXPOSE 1080

#---------------------
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
