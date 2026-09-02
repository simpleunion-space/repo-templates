#!/usr/bin/env sh
set -eu

python -m ruff check --ignore EXE002 src tests
PYTHONPATH=src${PYTHONPATH:+:$PYTHONPATH} python -m pytest "tests/{{PYTHON_PACKAGE}}"
