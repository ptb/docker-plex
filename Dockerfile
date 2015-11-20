FROM debian:jessie

RUN apt-get update -qq \
  && BUILD_PACKAGES='wget' \
  && REQUIRED_PACKAGES='ca-certificates' \
  && DEBIAN_FRONTEND=noninteractive \
  && apt-get install -qqy \
    $BUILD_PACKAGES \
    $REQUIRED_PACKAGES \
  && wget --no-check-certificate -qO- \
    https://github.com/just-containers/s6-overlay/releases/download/v1.16.0.0/s6-overlay-amd64.tar.gz \
    | tar zx -C / \
  && DOWNLOAD_URL=`wget -qO- https://plex.tv/downloads \
    | grep -o '[^"'"'"']*amd64.deb' \
    | grep -m 1 -v binaries` \
  && echo $DOWNLOAD_URL \
  && while true; \
    do \
      wget $DOWNLOAD_URL -qO plexmediaserver.deb; \
      if [ $? = 0 ]; \
        then break; \
      fi; \
      sleep 1s; \
    done \
  && touch /bin/start \
  && chmod +x /bin/start \
  && dpkg -i plexmediaserver.deb \
  && apt-get purge -qqy --auto-remove \
    $BUILD_PACKAGES \
  && apt-get clean -qqy \
  && rm -rf plexmediaserver.deb /bin/start /var/lib/apt/lists/* /tmp/* \
  && mkdir -p /etc/services.d/plex/

COPY ["run", "/etc/services.d/plex/"]
ENTRYPOINT ["/init"]
EXPOSE 32400
VOLUME ["/config", "/media"]

# docker build --rm=true --tag="ptb2/plex" .
# docker run --detach --name=plex --net=host --publish=32400:32400 \
#   --volume=/volume1/@appstore/Plex:/config \
#   --volume=/volume1/Media:/media:ro \
#   ptb2/plex
