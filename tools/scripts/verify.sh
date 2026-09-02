#!/usr/bin/env sh
set -eu

git diff --check
git diff --cached --check
python3 -m unittest discover -s tests -p 'test_*.py'
