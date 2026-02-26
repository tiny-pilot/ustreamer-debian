# syntax=docker/dockerfile:1.4
# Enable here-documents:
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/syntax.md#here-documents

FROM debian:trixie-20260202-slim AS build

ARG DEBIAN_FRONTEND='noninteractive'

RUN apt-get update && \
    apt-get install --yes \
      debhelper \
      dpkg-dev \
      devscripts \
      git \
      build-essential \
      wget

# Install Janus dependency.
RUN wget --output-document /tmp/janus.deb \
      https://output.circle-artifacts.com/output/job/d0e25b1e-326b-4223-b8c8-19b2ea7d130d/artifacts/0/build/janus_1.3.2-20260226175720_armhf.deb && \
    apt-get install --yes /tmp/janus.deb

# Docker populates this value from the --platform argument. See
# https://docs.docker.com/build/building/multi-platform/
ARG TARGETPLATFORM

ARG PKG_NAME='ustreamer'
ARG PKG_VERSION='6.36'

# This should be a timestamp, formatted `YYYYMMDDhhmmss`. That way the package
# manager always installs the most recently built package.
ARG PKG_BUILD_NUMBER

# Docker's platform names don't match Debian's platform names, so we translate
# the platform name from the Docker version to the Debian version and save the
# result to a file so we can re-use it in later stages.
RUN cat | bash <<'EOF'
set -exu
case "${TARGETPLATFORM}" in
  'linux/amd64')
    PKG_ARCH='amd64'
    ;;
  'linux/arm/v7')
    PKG_ARCH='armhf'
    ;;
  *)
    echo "Unrecognized target platform: ${TARGETPLATFORM}" >&2
    exit 1
esac
echo "${PKG_ARCH}" > /tmp/pkg-arch
echo "${PKG_NAME}_${PKG_VERSION}-${PKG_BUILD_NUMBER}_${PKG_ARCH}" > /tmp/pkg-id
EOF

# We ultimately need the directory name to be the package ID, but there's no
# way to specify a dynamic value in Docker's WORKDIR command, so we use a
# placeholder directory name to assemble the Debian package and then rename the
# directory to its package ID name in the final stages of packaging.
WORKDIR /build/placeholder-pkg-id

RUN git \
      clone \
      --branch "v${PKG_VERSION}" \
      --depth 1 \
      https://github.com/tiny-pilot/ustreamer.git \
      .

COPY debian debian

WORKDIR debian

RUN set -x && \
    PKG_ARCH="$(cat /tmp/pkg-arch)" && \
    set -u && \
    cat >control <<EOF
Source: ${PKG_NAME}
Section: video
Priority: optional
Maintainer: TinyPilot Support <support@tinypilotkvm.com>
Build-Depends: debhelper (>= 13),
  dh-exec,
  pkg-config,
  libevent-dev,
  libjpeg-dev,
  uuid-dev,
  libbsd-dev,
  libasound2-dev,
  libspeex-dev,
  libspeexdsp-dev,
  libopus-dev,
  libglib2.0-dev,
  libjansson-dev

Package: ${PKG_NAME}
Architecture: ${PKG_ARCH}
Depends: \${shlibs:Depends}, \${misc:Depends}, adduser
Homepage: https://github.com/tiny-pilot/ustreamer
Description: Lightweight and fast MJPEG-HTTP streamer
 µStreamer is a lightweight and very quick server to stream MJPEG video
 from any V4L2 device to the net. All new browsers have native
 support of this video format, as well as most video players such as
 mplayer, VLC etc. µStreamer is a part of the PiKVM project designed to
 stream VGA and HDMI screencast hardware data with the highest resolution
 and FPS possible.
EOF

RUN cat >changelog <<EOF
${PKG_NAME} (${PKG_VERSION}-${PKG_BUILD_NUMBER}) trixie; urgency=medium

  * µStreamer ${PKG_VERSION} release.

 -- TinyPilot Support <support@tinypilotkvm.com>  $(date '+%a, %d %b %Y %H:%M:%S %z')
EOF

# Install build dependencies based on Debian control file.
RUN mk-build-deps \
      --tool 'apt-get --option Debug::pkgProblemResolver=yes --no-install-recommends -qqy' \
      --install \
      --remove \
      control

# Rename the placeholder build directory to the final package ID.
WORKDIR /build
RUN set -x && \
    PKG_ID="$(cat /tmp/pkg-id)" && \
    mv placeholder-pkg-id "${PKG_ID}" && \
    cd "${PKG_ID}" && \
    DH_VERBOSE=1 dpkg-buildpackage --build=binary

FROM scratch as artifact

COPY --from=build "/build/*.deb" ./
