#!/usr/bin/env python3
"""
A tool to package and install qtile and extensions.
Features:
    - install
    - update (check)
    - checkhealth / doctor
    - relink

Settings and extensions are configured in a toml config file
"""

from typing import *
import argparse
import toml
import os
from os.path import join, basename
from subprocess import call

wayland_dependencies = ["pywlroots", "pywayland"]
general_dependencies = ["cffi", "xcffib", "cairocffi", "dbus-next"]


def clean(config):
    install_dir = config["install-dir"]
    # if install_dir does not exist, do nothing
    if not os.path.exists(install_dir):
        print("nothing to clean up")
        return
    venv_dir = join(install_dir, config["venv"]["dir"])
    # check if the link-target points to the install-dir/venv and remove it if so, skip if not
    link_target = os.path.abspath(os.path.expanduser(config["link-target"]))
    link_source = join(venv_dir, "bin", "qtile")
    if os.path.exists(link_target):
        if os.path.islink(link_target):
            if os.path.realpath(link_target) == link_source:
                os.unlink(link_target)
                print(f"symlink removed")
            else:
                print(f"symlink skipped (does not point to this install)")
        else:
            print(f"symlink skipped (does not seem to be a link)")
    else:
        print(f"symlink skipped (does not exist)")

    # removes virtualenv
    if os.path.exists(venv_dir):
        print("removing venv directory")
        os.system(f"rm -rf {venv_dir}")
    # removes qtile and all extension folders in config.install_dir
    qtile_dir = join(install_dir, "qtile")
    if os.path.exists(qtile_dir):
        print("removing qtile directory")
        os.system(f"rm -rf {qtile_dir}")
    for name, extension in config["extensions"].items():
        extension_dir = join(install_dir, basename(extension["repo"]))
        if os.path.exists(extension_dir):
            print("removing extension directory")
            os.system(f"rm -rf {extension_dir}")
    print("cleaning up done")


def install(config, update=False):
    # create install dir if it does not exist
    install_dir = os.path.abspath(os.path.expanduser(config["install-dir"]))
    qtile_repo = config.get("repo_location", "https://github.com/qtile/qtile.git")
    # if the repo is a local path, resolve it based on this path
    if os.path.exists(qtile_repo):
        qtile_repo = os.path.abspath(qtile_repo)
    qtile_branch = config.get("repo_branch", "master")
    # create install dir if it does not exist
    if not os.path.exists(install_dir):
        print("creating install directory")
        os.makedirs(install_dir)

    # creates a virtual environment in the install_dir
    venv_dir = join(install_dir, config["venv"]["dir"])
    if update:
        if not os.path.exists(venv_dir):
            raise RuntimeError("virtualenv does not exist, but in update mode")
        print(">> venv found")
    else:
        if os.path.exists(venv_dir):
            raise RuntimeError(
                "virtualenv already exists, should have been cleaned, please file an issue"
            )
        print("creating virtual environment")
        call(
            f"virtualenv {config['venv']['dir']} {config['venv']['args']}",
            cwd=install_dir,
            shell=True,
        )

    def call_in_venv(command, *args, **kwargs):
        kwargs["shell"] = True
        call(f"source {venv_dir}/bin/activate && {command}", *args, **kwargs)

    # get lib dir (first folder in venv/lib/...)
    lib_dir = join(venv_dir, "lib", os.listdir(join(venv_dir, "lib"))[0])

    # activate venv
    exec(open(f"{venv_dir}/bin/activate_this.py").read())

    # carfully adding important libs first
    for dep in general_dependencies:
        print(f">> installing {dep}")
        call_in_venv(f"pip install -U --no-cache-dir {dep}", cwd=install_dir)

    if config["backend"] == "wayland":
        for dep in wayland_dependencies:
            print(f">> installing {dep}")
            call_in_venv(f"pip install -U --no-cache-dir {dep}", cwd=install_dir)
            print(f">> patching {dep}")
            call_in_venv(
                f"/bin/bash allpatch.sh {lib_dir}/site-packages/{dep}.libs",
                cwd=install_dir,
            )

    else:
        raise RuntimeError(
            f"backend {config['backend']} not supported, please create an issue to ask for support."
        )

    # install qtile
    qtile_dir = join(install_dir, "qtile")
    if update:
        if not os.path.exists(qtile_dir):
            raise RuntimeError("qtile does not exist, but in update mode")
        print(">> pulling qtile updates")
        call("git pull", cwd=qtile_dir, shell=True)
    else:
        print(">> cloning qtile")
        call(
            f"git clone {qtile_repo} -b {qtile_branch} qtile",
            cwd=install_dir,
            shell=True,
        )

    print(">> installing qtile dependencies")
    call_in_venv(
        "pip install -U --no-cache-dir -r qtile/requirements.txt", cwd=install_dir
    )
    call_in_venv("pip install -U --no-cache-dir dbus-next", cwd=install_dir)

    print(">> setup ffi")
    call_in_venv("make run-ffibuild", cwd=qtile_dir)
    call_in_venv("python setup.py build --build-scripts=scripts install", cwd=qtile_dir)

    print(">> installing qtile")
    call_in_venv("pip install -U .", cwd=qtile_dir)

    if config.get("faulthandler", False):
        print(">> setting up faulthandler")
        entrypoint = join(qtile_dir, "bin", "qtile")
        with open(entrypoint, "r") as f:
            contents = f.readlines()

        index = 0
        for i, line in enumerate(contents):
            if line.strip().startswith("#"):
                continue
            index = i
            break
        contents.insert(index, "\nimport faulthandler")
        contents.insert(index + 1, "\nfaulthandler.enable()\n")

        with open(entrypoint, "w") as f:
            f.writelines(contents)

    # extensions
    for name, extension in config["extensions"].items():
        print(">> installing extension", name)
        extension_dir = join(install_dir, basename(extension["repo"]))
        if update:
            if not os.path.exists(extension_dir):
                raise RuntimeError("extension does not exist, but in update mode")
            print(">> pulling extension updates")
            call("git pull", cwd=extension_dir, shell=True)
        else:
            print(">> cloning extension")
            call(f"git clone {extension['repo']}", cwd=install_dir, shell=True)
        print(">> installing extension dependencies")
        for dep in extension["dependencies"]:
            call_in_venv(f"pip install -U --no-cache-dir {dep}", cwd=extension_dir)
        print(">> installing extension")
        call_in_venv("pip install .", cwd=extension_dir)

    # check and setup symlink to config["link-target"]
    print(">> symlinking qtile")
    link_target = os.path.abspath(os.path.expanduser(config["link-target"]))
    link_source = join(venv_dir, "bin", "qtile")
    create_symlink = False
    if os.path.exists(link_target):
        if os.path.islink(link_target):
            # check if destination is correct already
            if os.path.realpath(link_target) == link_source:
                print(f"link {link_target} is already set up correctly")
            else:
                print(
                    f"link {link_target} exists, and points to the wrong destination {os.path.realpath(link_target)}, replace?"
                )
                # TODO: interactive
                exit(1)
                os.unlink(link_target)
                create_symlink = True
        else:
            print(f"link target {link_target} exists and is not a symlink, replace?")
            # TODO: interactive
            exit(1)
            create_symlink = True
    else:
        create_symlink = True
    if create_symlink:
        os.symlink(link_source, link_target)
        print(f"link {link_target} created")

    print("done")


def main():
    """
    Sets up parser, config and executes commands
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-c", "--config", default="config.toml", help="config file")
    # TODO: logger
    # parser.add_argument("-v", "--verbose", action="store_true", help="show what's happening")
    subparser = parser.add_subparsers()
    pclean = subparser.add_parser(
        "clean",
        help="removes all directories and virtual environments, automatically called by install",
    )
    pclean.set_defaults(command="clean")
    pinstall = subparser.add_parser("install", help="installs everything")
    pinstall.set_defaults(command="install")
    pupdate = subparser.add_parser(
        "update",
        help="updates everything, no cleaning: pull instead of clone, pip install -U",
    )
    pupdate.set_defaults(command="update")

    args = parser.parse_args()

    with open(args.config, "r") as f:
        config = toml.load(f)

    print(config)

    if args.command == "clean" or args.command == "install":
        clean(config)

    if args.command == "install" or args.command == "update":
        install(config, update=args.command == "update")


if __name__ == "__main__":
    main()
