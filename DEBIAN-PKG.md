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

  - This includes dropping support for OMX
  - Stripping the code that supports Debian Buster and OMX will simplify the Ansible tasks

- Create a Dockerfile that builds a uStreamer Debian package from source

  - Use Docker's `--platform` parameter to target both AMD64 and ARMv7 architectures
  - Use `debhelper` to automatically build the uStreamer binary via its `Makefile`, similar to the [(official?) Debian package](https://salsa.debian.org/reedy/ustreamer/-/tree/master/)
  - Always build uStreamer using the `WITH_JANUS` make flag
    - This requires adding `janus` as a Debian package dependency
    - This requires adding `janus-dev` as a build dependency and patching Janus C header files to allow uStreamer to be built successfully
    - Remember to install the resulting uStreamer Janus plugin shared library file (i.e., `libjanus_ustreamer.so`)

- In Ansible, install the appropriate uStreamer Debian package instead of building from source

  - Maintain building from source if the Debian package is not specified

    - Skip Ansible tasks that would otherwise be handled by the Debian package

- In Ansible, drop support for building uStreamer from source

  - This is to avoid duplicating efforts/code between Ansible tasks and the Debian package

- Migrate creation of uStreamer user and group to Debian package

- Migrate uStreamer launcher script to Debian package

  - Deprecate `/home/ustreamer/config.yml` file in favor of `/opt/ustreamer-launcher/configs.d/001-config.yml`

    - Our uStreamer launcher script gives us a convenient way of overriding default uStreamer config via it's `configs.d` directory. There seems to be no reason why `config.yml` needs to be in a separate location.

# Discussion

> There's an [official [uStreamer] Debian package](https://salsa.debian.org/reedy/ustreamer/-/tree/master/debian)
>
> I don't think we can use it because we need the `WITH_JANUS` compilation option

Agreed. The uStreamer binary gets built with no extra make flags, which we need. Besides, uStreamer Debian packages aren't up to date, even the [`unstable` suite only has version `4.9-1`](https://packages.debian.org/search?suite=all&section=all&arch=any&searchon=sourcenames&keywords=ustreamer).

> @jdeanwallace will be project architect and advise the project based on his experience converting the TinyPilot Ansible role to Debian.

Seeing as we haven't completed the migration from TinyPilot Ansible to TinyPilot Debian, should this design also be for a partial migration? My preference is to design for a partial migration up until installing the uStreamer binary via a Debian package because there would be less unknowns.

> We need to decide whether it makes sense to manage the TC358743 EDID as part of the TinyPilot Debian package, the uStreamer Debian package, or somewhere else.

uStreamer can now load a custom EDID before it starts, so it might make sense to keep the EDID in the uStreamer Debian package. See https://github.com/pikvm/ustreamer#edid

# Resources

- uStreamer launcher requires `yq`. To avoid conflicts with system software, our debian package can eventually install `yq` under `/home/ustreamer/.local/bin`

  - https://unix.stackexchange.com/a/264495
