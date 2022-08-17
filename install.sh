#!/bin/bash

# check if pyproject.toml exists
if [ -f pyproject.toml ]; then
    echo "not clean"
	echo "please run clean.sh"
	exit 1
fi

EXTRA=false
# check for the --extra flag
if [ "$1" == "--extra" ]; then
    echo "will install qtile-extra"
	EXTRA=true
fi


cp pyproject.toml.template pyproject.toml
pdm venv create /usr/bin/python3.10
pdm use .venv
pdm config --local install.cache false

eval "$(pdm venv activate)"

# carfully adding important libs first
pdm add xcffib
pdm add cairocffi
pdm add cffi

#############
# pywlroots #
#############

# clone if the folder does not exist, else pull
#if [ ! -d pywlroots ]; then
#	git clone https://github.com/flacjacket/pywlroots
#else
#    pushd pywlroots
#    git pull
#    popd
#fi
#pdm import pywlroots/requirements.txt
#pdm add setuptools
#pdm update
#pushd pywlroots
#python wlroots/ffi_build.py
#python setup.py build --build-platlib --build-scripts
#python setup.py install --install-platlib build/temp.linux-x86_64-cpython-310
#popd
# pdm add 'pywlroots @ file:///${PROJECT_ROOT}/pywlroots'
pdm add pywayland
./allpatch.sh ".venv/lib/python3.10/site-packages/pywayland.libs"

pdm add pywlroots
./allpatch.sh ".venv/lib/python3.10/site-packages/pywlroots.libs"

#########
# qtile #
#########

# clone if the folder does not exist, else pull
if [ ! -d qtile ]; then
    git clone https://github.com/qtile/qtile.git
else
    pushd qtile || exit 1
    git pull
    popd || exit 1
fi

pdm import qtile/requirements.txt
pdm update

pdm add dbus-next

pushd qtile || exit 1
make run-ffibuild
popd || exit 1
pdm add 'qtile @ file:///${PROJECT_ROOT}/qtile'

################
# qtile-extras #
################

if [ "$EXTRA" = true ]; then
	# clone if the folder does not exist, else pull
	if [ ! -d qtile-extras ]; then
		git clone https://github.com/elParaguayo/qtile-extras
	else
		pushd qtile-extras || exit 1
		git pull
		popd || exit 1
	fi

	pdm add psutil
	pdm add iwlib

	pdm add 'qtile-extras @ file:///${PROJECT_ROOT}/qtile-extras'
fi
