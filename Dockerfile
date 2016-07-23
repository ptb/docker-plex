FROM debian:jessie
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN \
  BUILD_PACKAGES="wget" \

  && USERID_ON_HOST=1026 \

  && useradd \
    --comment "Plex Media Server" \
    --create-home \
    --user-group \
    --shell /usr/sbin/nologin \
    --uid $USERID_ON_HOST \
    plex \

 && echo "debconf debconf/frontend select noninteractive" \
    | debconf-set-selections \

  && sed \
    -e "s/httpredir.debian.org/debian.mirror.constant.com/" \
    -i /etc/apt/sources.list \

  && apt-get update -qq \
  && apt-get install -qqy \
    $BUILD_PACKAGES \

  && wget \
    https://downloads.plex.tv/plex-media-server/1.0.2.2413-7caf41d/plexmediaserver_1.0.2.2413-7caf41d_amd64.deb \
      --output-document /tmp/plexmediaserver.deb \
      --quiet \

  && dpkg --install /tmp/plexmediaserver.deb \

  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar -xz -C / \

  && mkdir -p /etc/services.d/plex/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "export LD_LIBRARY_PATH='/usr/lib/plexmediaserver'" \
    "export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR='/home/plex'" \
    "export PLEX_MEDIA_SERVER_HOME='/usr/lib/plexmediaserver'" \
    "export PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS='6'" \
    "export PLEX_MEDIA_SERVER_MAX_STACK_SIZE='3000'" \
    "export TMPDIR='/tmp'" \
    "ulimit -s \$PLEX_MEDIA_SERVER_MAX_STACK_SIZE" \
    "exec s6-applyuidgid -g 100 -u $USERID_ON_HOST \\" \
    "  /usr/lib/plexmediaserver/Plex\\ Media\\ Server" \
    > /etc/services.d/plex/run \
  && chmod +x /etc/services.d/plex/run \

  && apt-get purge -qqy --auto-remove \
    $BUILD_PACKAGES \
  && apt-get clean -qqy \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 32400

# docker build --rm --tag ptb2/plex .
# docker run --detach --name plex --net host \
#   --publish 32400:32400/tcp \
#   --volume /volume1/Config/Plex:/home/plex \
#   --volume /volume1/Media:/home/media:ro \
#   ptb2/plex
