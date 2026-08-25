FROM ubuntu:22.04 AS sdk

ARG CANGJIE_VERSION=1.1.3
ARG SDK_ARCHIVE=cangjie-sdk-linux-x64-${CANGJIE_VERSION}.tar.gz

COPY docker/sdk/${SDK_ARCHIVE} /tmp/cangjie-sdk.tar.gz
RUN mkdir -p /opt/cangjie-sdk \
    && tar -xzf /tmp/cangjie-sdk.tar.gz -C /opt/cangjie-sdk \
    && test -f /opt/cangjie-sdk/cangjie/envsetup.sh

FROM ubuntu:22.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        binutils \
        ca-certificates \
        gcc \
        g++ \
        libc6-dev \
        libc++-dev \
        libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=sdk /opt/cangjie-sdk/cangjie /opt/cangjie
COPY docker/entrypoint.sh /usr/local/bin/cangjie-entrypoint
RUN chmod +x /usr/local/bin/cangjie-entrypoint

ENV CANGJIE_HOME=/opt/cangjie
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/cangjie-entrypoint"]
CMD ["bash"]
