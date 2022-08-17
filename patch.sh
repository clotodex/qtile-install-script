#!/bin/bash

# site_dir can optionally be given as argument $!
site_dir="~/.local/lib/python3.10/site-packages/pywlroots.libs/"
if [ -n "$1" ]; then
  site_dir=$1
fi

echo "patching site dir: $site_dir"

echo "patching .."
cd "$site_dir" && echo "found dir to patch" || echo "error"

rm libxkbcommon-de59cad2.so.0.0.0 && echo "patching libxkbcommon .." || echo "error"
ln -s /usr/lib64/libxkbcommon.so.0.0.0 libxkbcommon-de59cad2.so.0.0.0  && echo "done" || echo "error"

rm libinput-a3c39512.so.10.13.0 && echo "patching libinput .." || echo "error"
ln -s /usr/lib64/libinput.so.10.13.0 libinput-a3c39512.so.10.13.0  && echo "done" || echo "error"

rm libevdev-bed09dca.so.2.3.0 && echo "patching libevdev .." || echo "error"
ln -s /usr/lib64/libevdev.so.2.3.0 libevdev-bed09dca.so.2.3.0  && echo "done" || echo "error"

rm libxcb-xinput-5c69f591.so.0.1.0 && echo "patching libxcb-xinput" || echo "error"
ln -s /usr/lib64/libxcb-xinput.so.0.1.0 libxcb-xinput-5c69f591.so.0.1.0 && echo "done" || echo "error"

echo "patch ok"
