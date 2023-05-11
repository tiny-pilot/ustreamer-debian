# syntax=docker/dockerfile:1.4
# Enable here-documents:
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#here-documents

FROM debian:bullseye-20220328-slim AS build

RUN set -x && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      debhelper \
      dpkg-dev \
      git

# The `PKG_VERSION` is the version of the Debian package. This should be a
# timestamp, formatted `YYYYMMDDhhmmss`. That way the package manager always
# installs the most recently built package.
ARG PKG_VERSION
ARG PKG_NAME="ustreamer"
ARG PKG_BUILD_NUMBER="1"
ARG PKG_ARCH="all"
ARG PKG_ID="${PKG_NAME}-${PKG_VERSION}-${PKG_BUILD_NUMBER}-${PKG_ARCH}"

RUN mkdir -p "/build/${PKG_ID}"
WORKDIR "/build/${PKG_ID}"

RUN git clone https://github.com/tiny-pilot/ustreamer.git .

COPY ./debian ./

WORKDIR "/build/${PKG_ID}/debian"

RUN cat >control <<EOF
Source: ${PKG_NAME}
Section: video
Priority: optional
Maintainer: TinyPilot Support <support@tinypilotkvm.com>
Build-Depends: debhelper (>= 11)

Package: ${PKG_NAME}
Architecture: ${PKG_ARCH}
Depends: ${shlibs:Depends}, ${misc:Depends}
Homepage: https://pikvm.org/
Description: Lightweight and fast MJPEG-HTTP streamer
 µStreamer is a lightweight and very quick server to stream MJPEG video
 from any V4L2 device to the net. All new browsers have native
 support of this video format, as well as most video players such as
 mplayer, VLC etc. µStreamer is a part of the PiKVM project designed to
 stream VGA and HDMI screencast hardware data with the highest resolution
 and FPS possible.
EOF

RUN cat >changelog <<EOF
${PKG_NAME} (${PKG_VERSION}) bullseye; urgency=medium

  * Latest µStreamer release.

 -- TinyPilot Support <support@tinypilotkvm.com>  $(date '+%a, %d %b %Y %H:%M:%S %z')
EOF

WORKDIR "/build/${PKG_ID}"

RUN DH_VERBOSE=1 dpkg-buildpackage --build=binary

FROM scratch as artifact

COPY --from=build "/build/*.deb" ./
