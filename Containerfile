FROM alpine:latest
ARG VERSION=2.11

COPY buildconfig /
COPY noscan.patch /

RUN set -x \
  \
  && apk add --no-cache --virtual .build-deps \
    libnl3-dev \
    openssl-dev \
    linux-headers \
    make \
    g++ \
    patch \
  \
  && wget -O hostapd.tar.gz "https://w1.fi/releases/hostapd-$VERSION.tar.gz" \
  && mkdir -p /usr/src/hostapd \
  && tar xf hostapd.tar.gz --strip-components=1 -C /usr/src/hostapd \
  && patch -Np1 -i /noscan.patch -d /usr/src/hostapd \
  && rm \
    hostapd.tar.gz \
    /noscan.patch \
  && cd /usr/src/hostapd/hostapd \
  \
  && mv /buildconfig .config \
  && cat defconfig >> .config \
  && make -j "$(getconf _NPROCESSORS_ONLN)" install \
  \
## cleanup
  && cd / \
  && rm -rf /usr/src \
  \
  && runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && apk add --no-cache --virtual .hostapd-rundeps $runDeps \
  && apk del .build-deps

ENTRYPOINT ["hostapd"]
