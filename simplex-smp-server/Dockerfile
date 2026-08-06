# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
FROM simplexchat/smp-server:v7.0.0

LABEL \
    org.opencontainers.image.title="Home Assistant Add-on: SimpleX SMP Server" \
    org.opencontainers.image.description="Host a SimpleX SMP server on Home Assistant." \
    org.opencontainers.image.source="https://github.com/ed-asriyan/hassio-simplex" \
    org.opencontainers.image.licenses="Apache License 2.0"

RUN apt-get update && apt-get install -y --no-install-recommends jq gettext-base && rm -rf /var/lib/apt/lists/*

COPY smp-server.ini.tpl /smp-server.ini.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
