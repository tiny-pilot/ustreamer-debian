# ustreamer-debian

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/tiny-pilot/ustreamer-debian/tree/master.svg?style=svg)](https://app.circleci.com/pipelines/github/tiny-pilot/ustreamer-debian)

TinyPilot-specific build of a uStreamer Debian package

## Updating to new uStreamer versions

When there are uStreamer releases that would benefit TinyPilot users, we need to update the TinyPilot uStreamer repos to pull in the changes and create a new Debian package. Note that we don't create Debian packages for every uStreamer change, as some uStreamer releases don't serve TinyPilot scenarios.

### Review uStreamer's commit history

Before updating the uStreamer package, review uStreamer's commit history for anything that may impact TinyPilot scenarios.

Check the [uStreamer README](https://github.com/pikvm/ustreamer?tab=readme-ov-file#%C2%B5streamer) for any compatibility changes.

If the new version of uStreamer is a new major version, try and find out why the major version number increased.

Review all commits made to uStreamer since we last cut a release for any breaking changes or feature improvements. You can do this using a GitHub comparison, e.g., [v5.43 to v6.11](https://github.com/pikvm/ustreamer/compare/v5.43...v6.11).

Check for any other obvious breaking changes by reviewing some of the major commit diffs.

### Create a branch

If the new version of uStreamer doesn't have any obvious breaking changes, create a new uStreamer debian package in a development branch as follows.

First, sync tags of [TinyPilot's fork of uStreamer](https://github.com/tiny-pilot/ustreamer) with [the upstream version](https://github.com/pikvm/ustreamer)

```bash
git clone git@github.com:tiny-pilot/ustreamer.git && \
  cd ustreamer && \
  git remote add upstream https://github.com/pikvm/ustreamer.git && \
  git fetch --tags upstream && \
  git push --tags origin
```

Then, create a new branch in this repository and update the `ARG PKG_VERSION=` line in `Dockerfile` to the desired [uStreamer release tag](https://github.com/pikvm/ustreamer/tags).

### Testing on device

Install the latest version of TinyPilot Pro on your test device and SSH into it.

Get the URL of the new debian package:

1. Go to the CircleCI build for your branch.
1. Click the "build_debian_package" CircleCI step.
1. Go the the "Artifacts" tab.
1. Copy the link to the `armhf.deb` file.

Download the new debian package on the test device:

```bash
# Replace the URL with the link to the `armhf.deb` package.
wget https://output.circle-artifacts.com/output/job/358d292c-6233-40c2-a31c-e6b3fcc1aced/artifacts/0/build/linux_arm_v7/ustreamer_armhf.deb
```

Then install the package with the following command:

```bash
sudo apt install -y ./ustreamer_*.deb
```

Capture a TinyPilot log to check the version of uStreamer that's running and make sure it's the version you expect.

Now perform a manual test of TinyPilot's video features (a subset of our manual release testing process) to make sure they still work as expected.

Note: these tests aren't OS dependent, but some steps assume the target machine is Ubuntu 22.04 for navigation and settings.

#### Reduce video frame rate (MJPEG)

1. Go to System > Video settings
1. Set FPS to 5
1. Click “Apply”
1. Verify that the video refreshes slower than it did previously

#### Reduce video quality (MJPEG)

1. Go to System > Video settings
1. Set JPEG quality to 10%
1. Click “Apply”
1. Verify that the image quality looks notably worse

#### Reset video settings

1. Go to System > Video settings
1. Click “Reset to Default” next to Frame Rate
1. Click “Reset to Default” next to Quality
1. Click “Apply”
1. Verify that video quality and latency goes back to normal

#### Use H.264 compression

1. Go to System > Video settings
1. Select Streaming Mode of H.264
1. Click “Apply”
1. Verify that H.264 icon appears on the bottom left corner and that video functions

#### Verify audio plays

1. In the target system, click the speaker icon in the upper right corner
1. Adjust the volume on the target machine
1. Verify that the confirmation beeps from changing the volume play through the local machine

#### Reduce video frame rate (H.264)

1. Go to System > Video settings
1. Set FPS to 5
1. Click “Apply”
1. Verify that the video refreshes slower than it did previously

#### Reduce video quality (H.264)

1. Go to System > Video settings
1. Set Bit Rate to 0.05 Mb/s
1. Click “Apply”
1. Verify that the image quality looks notably worse
   1. The difference is subtle. You might need to open a web browser in the target system to see the difference.

#### Reset video settings

1. Go to System > Video settings
1. Click “Reset to Default” next to Frame Rate
1. Click “Reset to Default” next to Quality
1. Click “Apply”
1. Verify that video quality and latency goes back to normal

#### Change display settings

1. On the target machine, navigate to its display settings
1. Select a different resolution (e.g., 1280x720 at 60Hz)
1. Click "Apply"
1. Verify that the video resolution changes

#### Reset display settings

1. On the target machine, navigate to its display settings
1. Select the original resolution (e.g., 1920x1080 at 30Hz)
1. Click "Apply"
1. Verify that the video resolution changes back to the original settings

### Measure latency

If the manual tests pass, measure the new latency:

1. Connect TinyPilot to a device that has a display
1. Mirror display between TinyPilot and the device's other monitor
1. On the target device, visit a website that has a stopwatch with millisecond precision
1. Take a photo that captures the TinyPilot client device's screen and the mirrored display in one photo
1. Subtract the times to get the latency
1. Repeat 3-4x to get an average

### Create tickets

If we encounter any regression during the testing process, including a significant increase in latency, raise this with the product owner. The next steps would probably be one or more of these steps:

1. See if we can fix the uStreamer regression and contribute it upstream
1. Report the bug to uStreamer
1. Accept the regression if it's minor

If the latency measurements indicate that latency has dropped by more than 5% compare to the previous uStreamer version, create some tickets.

- Create a ticket to update the TinyPilot website with the new latency figure.
- Create a ticket to include the latency improvements in the release announcement.

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
   - e.g., `ustreamer_5.38-20230802141939_amd64.deb` would have the tag `5.38-20230802141939`.
1. Click "Generate release notes."
1. Upload the Debian package files you downloaded above.
1. Click "Publish release."
