# qtile-install-script (for wayland)
A suite to install qtile with all dependencies correctly (used for personal debugging and issue reporting).

## Goal

- Have a reproducible setup of a qtile installation
- Fix all libraries automatically to prevent pywlroots bugs
- A repository to reference how qtile was installed

## What it does

- Sets up a new [PDM](https://pdm.fming.dev/) project for local and sane dependency management.
- installs all necessary dependencies one by one
- patches libraries not being linked to system libraries
- clones and installs qtile
- runs ffi build scripts
- optionally installs qtile-extra if called with the `--extra` flag

## How to launch qtile

`dbus-run-session <path-to-this-folder>/.venv/bin/qtile start -b wayland`
