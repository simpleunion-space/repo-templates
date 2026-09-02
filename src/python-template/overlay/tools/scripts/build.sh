#!/usr/bin/env sh
set -eu

mkdir -p "build/{{PYTHON_PACKAGE}}"
python -m build --outdir "build/{{PYTHON_PACKAGE}}"
