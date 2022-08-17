#!/bin/bash

rm -rf pywlroots
rm -rf qtile
rm -rf qtile-extras

if [ -f .pdm.toml ]; then
	pdm venv remove in-project
else
	rm -rf .venv
fi

rm pdm.lock pyproject.toml .pdm.toml
