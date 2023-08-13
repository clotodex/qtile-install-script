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
		echo -n "patching $libname .."
		# test if already patched
		current_target="$(readlink -f "$f")"
		if [ "$current_target" = "$general_libname_full" ]; then
			echo "ALREADY GOOD"
			continue
		fi
		rm "$libname" && ln -s "$general_libname_full" "$libname" && echo -e "\e[32mpatched $general_libname\033[0m" || >&2 echo -e "\e[31m## error patching $general_libname\033[0m"
	else
		>&2 echo -e "\e[31merror: could not find $general_libname_full\033[0m"
	fi
done

echo "patch ok"
