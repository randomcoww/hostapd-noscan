FROM alpine:latest

ARG PKGNAME=hostapd-noscan
COPY buildconfig /
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
  && VERSION=$(wget -O - https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$PKGNAME | grep ^pkgver | tr -d "pkgver=") \
  && wget -O hostapd.tar.gz "https://w1.fi/releases/hostapd-$VERSION.tar.gz" \
  && mkdir -p /usr/src/hostapd \
  && tar xf hostapd.tar.gz --strip-components=1 -C /usr/src/hostapd \
  && wget -O - https://aur.archlinux.org/cgit/aur.git/plain/noscan.patch?h=$PKGNAME | patch -Np0 -d /usr/src/hostapd \
  && rm -f \
    hostapd.tar.gz \
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
