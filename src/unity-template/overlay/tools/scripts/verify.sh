#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

[ -d "build/{{PROJECT_NAME}}" ] || {
    printf '%s\n' 'Required build component is missing: build/{{PROJECT_NAME}}' >&2
    exit 1
}

[ -d "src/{{PROJECT_NAME}}/Assets" ]
[ -d "src/{{PROJECT_NAME}}/Packages" ]
[ -d "src/{{PROJECT_NAME}}/ProjectSettings" ]
