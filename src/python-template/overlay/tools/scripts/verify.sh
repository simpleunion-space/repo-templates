#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

[ -d "build/{{PYTHON_PACKAGE}}" ] || {
    printf '%s\n' 'Required build component is missing: build/{{PYTHON_PACKAGE}}' >&2
    exit 1
}

[ -f "src/{{PYTHON_PACKAGE}}/__init__.py" ]
[ -f "tests/{{PYTHON_PACKAGE}}/test_package.py" ]
