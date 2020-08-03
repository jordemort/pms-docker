FROM nvidia/cuda:11.0-runtime

ARG S6_OVERLAY_VERSION=v2.0.0.1
ARG S6_OVERLAY_ARCH=amd64
ARG PLEX_BUILD=linux-x86_64
ARG PLEX_DISTRO=debian
ARG DEBIAN_FRONTEND="noninteractive"
ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

RUN \
# Update and get dependencies
    apt-get update && \
    apt-get install -y \
      tzdata \
      curl \
      xmlstarlet \
      uuid-runtime \
      unrar \
    && \

# Fetch and extract S6 overlay
    curl -J -L -o /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz && \
    tar -xhvz --exclude ./usr/bin/execlineb -f /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz -C / && \

# Add user
    useradd -U -d /config -s /bin/false plex && \
    usermod -G users plex && \

# Setup directories
    mkdir -p \
      /config \
      /transcode \
      /data \
    && \

# Cleanup
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

EXPOSE 32400/tcp 3005/tcp 8324/tcp 32469/tcp 1900/udp 32410/udp 32412/udp 32413/udp 32414/udp
VOLUME /config /transcode

ENV CHANGE_CONFIG_DIR_OWNERSHIP="true" \
    HOME="/config"

ARG TAG=beta
ARG URL=

COPY root/ /

RUN \
# Save version and install
    /installBinary.sh

ADD https://raw.githubusercontent.com/keylase/nvidia-patch/master/patch.sh /usr/local/bin/patch.sh
ADD https://raw.githubusercontent.com/keylase/nvidia-patch/master/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
#COPY nvdec-transcoder.sh /usr/local/bin/nvdec-transcoder.sh

RUN chmod +x /usr/local/bin/*.sh && \
    dpkg-divert --add --rename --divert "/usr/lib/plexmediaserver/Plex Transcoder2" "/usr/lib/plexmediaserver/Plex Transcoder"

COPY ["nvdec-transcoder.sh", "/usr/lib/plexmediaserver/Plex Transcoder"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "/init"]

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1
