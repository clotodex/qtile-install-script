#!/bin/bash

# site_dir can optionally be given as argument $!
site_dir="$HOME/.local/lib/python3.10/site-packages/pywlroots.libs/"
if [ -n "$1" ]; then
  site_dir=$1
fi

echo "patching site dir: $site_dir"

echo "patching .."
cd "$site_dir" && echo "found dir to patch" || echo "error"

for f in ./*; do
	libname="$(basename "$f")"
	version="$(echo "$libname" | grep -oP "\-[^-]*$")"
	# remove version suffix from libname
	general_libname="${libname%"$version"}"
	# find full name of general_libname in /usr/lib64
	general_libname_full="/usr/lib64/$general_libname.so"
	if [ -f "$general_libname_full" ]; then
		echo "patching $libname .."
		rm "$libname" && ln -s "$general_libname_full" "$libname" && echo "patched $general_libname" || echo "error patching $general_libname"
	else
		echo "error: could not find $general_libname_full"
	fi
done

echo "patch ok"
