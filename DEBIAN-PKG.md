This ticket is the result of https://github.com/tiny-pilot/ustreamer-debian/issues/1

# Overview

We want to reimplement `ansible-role-ustreamer` functionality as a Debian package.

# Background

We've found that running Ansible is generally a slow process that might not be well suited for installing TinyPilot and TinyPilot related software, like uStreamer. We've already partially migrated our TinyPilot installation away from Ansible to a Debian package and we'd like to do the same with our uStreamer installation. Using a Debian package speeds up the installation process by using simple bash scripts, as opposed to Python in Ansible, and skipping a package installation when the version requirement has already been met.

# Milestones

## Milestone 1: Install uStreamer via a Debian package instead of compiling from source

### Goal

Avoid building uStreamer on the device, reducing the TinyPilot installation time by about 20s.

### Steps

- In `ansible-role-ustreamer`, drop support for Debian Buster

  - This includes dropping support for OMX
  - Stripping the code that supports Debian Buster and OMX will simplify the Ansible tasks

- In `ustreamer-debian`, create a Dockerfile that builds a uStreamer Debian package from source

  - Build the Debian package in CI

    - Use Docker's `--platform` parameter to target both AMD64 and ARMv7 architectures
    - Save the package file as an CI artifact which we can later manually attach as a GitHub release asset
      - This will only happen for a single release until we consolidate `ansible-role-ustreamer` with the TinyPilot repo, in milestone 2

  - Use `debhelper` to automatically build the uStreamer binary via its `Makefile`, similar to the [(official?) Debian package](https://salsa.debian.org/reedy/ustreamer/-/tree/master/)
  - Always build uStreamer using the `WITH_JANUS` make flag

    - This requires adding `janus` as a Debian package dependency
    - This requires adding `janus-dev` as a build dependency and patching Janus C header files to allow uStreamer to be built successfully
    - Remember to install the resulting uStreamer Janus plugin shared library file (i.e., `libjanus_ustreamer.so`)

- Create a `ustreamer-debian` release

  - Manually attach the latest Debian package CI artifact as a GitHub release asset

- In `ansible-role-ustreamer`, install the appropriate uStreamer Debian package instead of building from source

  - Grab the uStreamer Debian package path from a `ustreamer-debian` release
  - Maintain building from source if the Debian package is not specified

    - Skip Ansible tasks that would otherwise be handled by the Debian package

## Milestone 2: Consolidate uStreamer's Ansible role and Debian package with TinyPilot repo

### Goal

Avoid making parallel changes in both `ansible-role-ustreamer`, and `ustreamer-debian` repos; when we later incrementally migrate uStreamer's Ansible role functionality to the Debian package.

### Steps

- Archive `ansible-role-ustreamer` repo

  - This freezes the code while we consolidate

- Consolidate `ansible-role-ustreamer` with TinyPilot repo

  - This is just a temporary solution so we can move the contents of the `ansible-role-ustreamer` repo into a `ansible-role-ustreamer` directory in the root of the TinyPilot repo

- Bundle local version of `ansible-role-ustreamer`

- Archive `ustreamer-debian` repo

- Consolidate `ustreamer-debian` with TinyPilot repo

- Bundle local version of uStreamer's Debian package file

## Milestone 3: Partially migrate uStreamer Ansible role functionality to Debian package

### Goal

Migrate highest-impact and/or lowest-effort Ansible tasks to Debian package.

### Steps

- Drop support for building uStreamer from source

  - This is to avoid duplicating efforts/code between Ansible tasks and the Debian package

- Migrate creation of uStreamer user and group to uStreamer Debian package

  - We do [something similar](https://github.com/tiny-pilot/tinypilot/blob/master/debian-pkg/debian/tinypilot.postinst#L15-L29) in TinyPilot's Debian package

- Migrate [Janus static config files](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/install_janus.yml#L57-L58) to uStreamer Debian package

## Milestone 4: Migrate remaining uStreamer Ansible role functionality to Debian package

### Goal

Purge uStreamer's Ansible role.

### Steps

- Install `yq` as part of the uStreamer Debian package

  - This is in preparation for migrating the uStreamer launcher script, which depends on `yq`
  - This will help us to parse the `/home/ustreamer/config.yml` file and determine the value of `ustreamer_capture_device` which is needed to [provision the TC358743 chip](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/main.yml#L83-L85) and determine [uStreamer launcher runtime config](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/provision_tc358743.yml#L74-L81)
  - To avoid conflicts with system software, we could install `yq` to `/home/ustreamer/.local/bin`
    - https://unix.stackexchange.com/a/264495

- Migrate [default uStreamer config for TC358743 chips](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/provision_tc358743.yml#L74-L81) to uStreamer's Debian package `postinstall` script

  - This gives us enough info to create the `/opt/ustreamer-launcher/configs.d/000-defaults.yml` file on devices with TC358743 chips

- Migrate [default uStreamer config for non-TC358743 chips](https://github.com/tiny-pilot/tinypilot/blob/master/bundler/bundle/install#L83-L93) to uStreamer's Debian package `postinstall` script

  - This gives us enough info to create the `/opt/ustreamer-launcher/configs.d/000-defaults.yml` file on devices with non-TC358743 chips
  - This isn't strictly required, but it would be nice to consolidate all the default uStreamer launcher config in one place

- Migrate uStreamer launcher script to uStreamer Debian package

  - This requires all dynamically determined uStreamer config (i.e., [default config for TC358743 chips](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/provision_tc358743.yml#L74-L81)) to live within the uStreamer Debian package
  - After this task, all uStreamer's command-line arguments will be consolidated within uStreamer's Debian package

- Migrate the provisioning of the TC358743 chip, which consists of the following sub-tasks:

  - Migrate `/boot/config.txt` to uStreamer Debian package

  - Migrate `/boot/cmdline.txt` to uStreamer Debian package

  - Migrate TC358743 EDID file to uStreamer Debian package

  - Migrate TC358743 EDID loader systemd service to uStreamer Debian package

- Migrate uStreamer Janus plugin config to uStreamer Debian package

  - This depends on the [value of `ustreamer_capture_device`](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/templates/janus.plugin.ustreamer.jcfg.j2#L5)

- Migrate uStreamer systemd service to uStreamer Debian package

- Install uStreamer Debian package from TinyPilot's Ansible role

- Purge uStreamer's Ansible role from TinyPilot repo
