FROM quay.io/krakaw/tari_base_node:latest

RUN apt update 1>&2 && \
    apt install -y gpg apt-transport-https ca-certificates && \
    printf "deb https://deb.torproject.org/torproject.org stretch main\ndeb-src https://deb.torproject.org/torproject.org stretch main" > /etc/apt/sources.list.d/tor.list && \
    curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import 1>&2 && \
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - 1>&2 &&\
    apt update 1>&2 && \
    apt install -y tor deb.torproject.org-keyring 1>&2 && \
    printf "SocksPort 127.0.0.1:9050\nControlPort 127.0.0.1:9051\nCokieAuthentication 0\nClientOnly 1\nClientUseIPv6 1" > /etc/tor/torrc

COPY ./scripts/start.sh /usr/bin/start.sh
CMD ["start.sh"]