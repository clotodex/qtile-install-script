# qtile-install-script (for wayland)
A suite to install qtile with all dependencies and extensions correctly and in a reproducible way.

## Goal

- An easy way to install and update to the most recent version of qtile 
- Have a reproducible setup of a qtile installation, including dependencies and extensions (everything you need alongside dotfiles)
- Fix all libraries automatically to prevent pywlroots bugs (wayland)
- Corretly build cffi of qtile [not necessary anymore since qtile now handles it automatically]
- A repository to reference how qtile was installed

## What it does

- configure in `config.toml`
- installs all necessary dependencies one by one
- patches libraries not being linked to system libraries
- clones and installs qtile
- runs ffi build scripts
- optionally installs extensions
- links the install to your symlink of choice

## Usage

configure in `config.toml`: installation directory, symlink, extensions, ...

`./qtile-packager.py clean` to clean / uninstall everything
`./qtile-packager.py install` cleans and then installs everything
`./qtile-packager.py update` update the installation
