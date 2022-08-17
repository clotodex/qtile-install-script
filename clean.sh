#!/bin/bash

rm -rf pywlroots
rm -rf qtile
rm -rf qtile-extras

pdm venv remove in-project
rm pdm.lock pyproject.toml .pdm.toml
