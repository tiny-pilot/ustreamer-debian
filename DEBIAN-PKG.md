This ticket is the result of https://github.com/tiny-pilot/ustreamer-debian/issues/1

# Overview

We want to reimplement `ansible-role-ustreamer` functionality as a Debian package.

We'll do so by incrementally migrating Ansible functionality over to the Debian package, in the following phases:

1. Install uStreamer via a Debian package instead of compiling from source
2. All other functionality

This ticket only outlines the tasks and milestones required achieve phase 1 above.

# Tasks

- Create a Dockerfile that builds multi-arch (i.e., AMD64, ARMv7) uStreamer binaries in CI

  - Use Docker's `--platform` parameter
  - Store binaries as CI artifacts (for review)
  - Always build uStreamer using the `WITH_JANUS` flag

- In Ansible, install the uStreamer binary instead of building from source

  - Fallback to building from source if the binary is not specified

- Create a Dockerfile that builds a uStreamer Debian package

  - The Debian package should only install the uStreamer binary
  - Use `debhelper`

- In Ansible, install the uStreamer Debian package instead of installing the uStreamer binary

  - Fallback to building from source if the Debian package is not specified
