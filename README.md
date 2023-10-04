# ustreamer-debian

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/tiny-pilot/ustreamer-debian/tree/master.svg?style=svg)](https://app.circleci.com/pipelines/github/tiny-pilot/ustreamer-debian)

TinyPilot-specific build of a uStreamer Debian package

## Updating to new uStreamer versions

When there are uStreamer releases that would benefit TinyPilot users, we need to update the TinyPilot uStreamer repos to pull in the changes and create a new Debian package. Note that we don't create Debian packages for every uStreamer change, as some uStreamer releases don't serve TinyPilot scenarios.

First, sync tags of [TinyPilot's fork of uStreamer](https://github.com/tiny-pilot/ustreamer) with [the upstream version](https://github.com/pikvm/ustreamer)

```bash
git clone git@github.com:tiny-pilot/ustreamer.git && \
  cd ustreamer && \
  git remote add upstream https://github.com/pikvm/ustreamer.git && \
  git fetch --tags upstream && \
  git push --tags origin
```

Then, update the `ARG PKG_VERSION=` line in `Dockerfile` to the desired [uStreamer release tag](https://github.com/pikvm/ustreamer/tags).

## Publishing releases

We publish releases manually on Github. When we're ready to publish a new release, follow these steps:

### Download Debian package files

1. Go to the CircleCI build for the most recent `master` branch.
1. Click the `build_debian_package` CircleCI step.
1. Go the the "Artifacts" tab.
1. Download all `.deb*` files.

### Create a Github release

1. Create a new Github release for ustreamer-debian.
1. Make the release tag and title the version number and timestamp suffix from the `.deb`` files.
    * e.g., `ustreamer_5.38-20230802141939_amd64.deb` would have the tag `5.38-20230802141939`.
1. Click "Generate release notes."
1. Upload the Debian package files you downloaded above.
1. Click "Publish release."
