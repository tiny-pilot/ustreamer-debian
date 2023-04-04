This ticket is the result of https://github.com/tiny-pilot/ustreamer-debian/issues/1

# Overview

We want to reimplement `ansible-role-ustreamer` functionality as a Debian package.

We'll do so by incrementally migrating Ansible functionality over to the Debian package, in the following milestones:

1. Install uStreamer via a Debian package instead of compiling from source
2. Migrate uStreamer launcher to Debian package
3. All other uStreamer functionality
4. Consolidate `ansible-role-ustreamer` repo with TinyPilot repo

# Milestone tasks

## Milestone 1

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

## Milestone 2

- In Ansible, drop support for building uStreamer from source

  - This is to avoid duplicating efforts/code between Ansible tasks and the Debian package

- Migrate creation of uStreamer user and group to Debian package

- In Ansible, let uStreamer set the custom EDID

  - uStreamer can now load a custom EDID before it starts, so it might make sense to keep the EDID in the uStreamer Debian package. See https://github.com/pikvm/ustreamer#edid
  - This would replace our `load-tc358743-edid` service

- Install `yq` as part of the uStreamer Debian package

  - This is in preparation for migrating the uStreamer launcher script, which depends on `yq`
  - This will help us to parse the `/home/ustreamer/config.yml` file and determine the value of `ustreamer_capture_device` which is needed to [provision the TC358743 chip](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/main.yml#L83-L85) and determine [uStreamer launcher runtime config](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/provision_tc358743.yml#L74-L81)

- Migrate the provisioning of the TC358743 chip to Debian package

  - Move [default uStreamer config for TC358743 chips](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/provision_tc358743.yml#L74-L81) to the Debian package's `postinstall` script
    - This is required so that the Debian package can later generate the [default uStreamer launcher runtime config](https://github.com/tiny-pilot/ansible-role-ustreamer/blob/master/tasks/install_launcher.yml#L37-L59)
  - Move [default uStreamer config for non-TC358743 chips](https://github.com/tiny-pilot/tinypilot/blob/master/bundler/bundle/install#L83-L93) to the Debian package's `postinstall` script
    - This isn't a requirement, but it would be nice to consolidate all the default uStreamer launcher config in one place

- Migrate uStreamer launcher script to Debian package

## Milestone 3

- Migrate Janus config to Debian package

- Migrate uStreamer systemd service to Debian package

## Milestone 4

- Consolidate `ansible-role-ustreamer` repo with TinyPilot repo

  - We should now be able to archive the `ansible-role-ustreamer` repo

# Resources

- uStreamer launcher requires `yq`. To avoid conflicts with system software, our debian package can eventually install `yq` under `/home/ustreamer/.local/bin`

  - https://unix.stackexchange.com/a/264495
