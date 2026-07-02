FROM debian:trixie-slim AS koreos-builder

ARG BUILD_UID=1000
ARG BUILD_GID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        apt-utils \
        locales \
        ca-certificates \
        curl \
        && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/koreos

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN groupadd -g ${BUILD_GID} korebuild && \
    useradd -m -u ${BUILD_UID} -g korebuild -s /bin/bash korebuild

RUN mkdir -p /etc/sudoers.d && \
    echo "korebuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/korebuild && \
    chmod 440 /etc/sudoers.d/korebuild

RUN mkdir -p /opt/koreos/{assets,configs,scripts,overlay,output} && \
    chown -R korebuild:korebuild /opt/koreos

USER korebuild

ENTRYPOINT ["/entrypoint.sh"]
CMD ["iso-x86_64"]
