This ticket is the result of https://github.com/tiny-pilot/ustreamer-debian/issues/1

# Overview

We want to reimplement `ansible-role-ustreamer` functionality as a Debian package.

We'll do so by incrementally migrating Ansible functionality over to the Debian package, in the following phases:

1. Install uStreamer via a Debian package instead of compiling from source
2. All other functionality

This ticket only outlines the tasks and milestones required achieve phase 1 above.

# Tasks

- Archive the `ustreamer-debian` repo

  - For now, we'll create the uStreamer Debian package within the `ansible-role-ustreamer` repo
  - Later, we might merge the `ansible-role-ustreamer` repo with the `tinypilot` repo

- Drop support for Debian Buster

  - Stripping the code that supports Debian Buster will simplify the Ansible tasks

- Create a Dockerfile that builds multi-arch (i.e., AMD64, ARMv7) uStreamer binaries in CI

  - Use Docker's `--platform` parameter
  - Store binaries as CI artifacts (for review)
  - Always build uStreamer using the `WITH_JANUS` flag

- In Ansible, install the uStreamer binary instead of building from source

  - Maintain building from source if the binary is not specified

- Create a Dockerfile that builds a uStreamer Debian package

  - The Debian package should only install the uStreamer binary
  - Use `debhelper`

- In Ansible, install the uStreamer Debian package instead of installing the uStreamer binary

  - Maintain building from source if the Debian package is not specified

    - This might be complicated to maintain because tasks might be duplicated between Ansible and the Debian package
    - If this seems to be too complicated then drop this requirement

- Remove the `load-tc358743-edid` service and let uStreamer set the custom EDID

  - uStreamer can now load a custom EDID before it starts. See https://github.com/pikvm/ustreamer#edid

- Migrate uStreamer launcher script to the Debian package

# Discussion

> There's an [official [uStreamer] Debian package](https://salsa.debian.org/reedy/ustreamer/-/tree/master/debian)
>
> I don't think we can use it because we need the `WITH_JANUS` compilation option

Agreed. The uStreamer binary gets built with no extra make flags, which we need. Besides, uStreamer Debian packages aren't up to date, even the [`unstable` suite only has version `4.9-1`](https://packages.debian.org/search?suite=all&section=all&arch=any&searchon=sourcenames&keywords=ustreamer).

> @jdeanwallace will be project architect and advise the project based on his experience converting the TinyPilot Ansible role to Debian.

Seeing as we haven't completed the migration from TinyPilot Ansible to TinyPilot Debian, should this design also be for a partial migration? My preference is to design for a partial migration up until installing the uStreamer binary via a Debian package because there would be less unknowns.

# Resources

- uStreamer launcher requires `yq`. To avoid conflicts with system software, our debian package can eventually install `yq` under `/home/ustreamer/.local/bin`

  - https://unix.stackexchange.com/a/264495
