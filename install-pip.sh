#!/bin/bash

# check if .venv folder exists
if [ -d .venv ]; then
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

virtualenv .venv -p python3.10
source .venv/bin/activate

# carfully adding important libs first
pip install --no-cache-dir cffi
pip install --no-cache-dir xcffib
pip install --no-cache-dir cairocffi

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
pip install --no-cache-dir pywayland
./allpatch.sh ".venv/lib/python3.10/site-packages/pywayland.libs"

pip install --no-cache-dir pywlroots
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

pip install --no-cache-dir -r qtile/requirements.txt

pip install --no-cache-dir dbus-next

pushd qtile || exit 1
make run-ffibuild
python setup.py build --build-scripts=scripts install
pip install .
popd || exit 1

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

	pip install --no-cache-dir psutil
	pip install --no-cache-dir iwlib
	pushd qtile-extras || exit 1
	pip install .
	popd || exit 1
fi
