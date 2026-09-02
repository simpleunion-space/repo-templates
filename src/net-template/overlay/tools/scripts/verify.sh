#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

[ -d "build/{{PROJECT_NAME}}.Core" ] || {
    printf '%s\n' 'Required build component is missing: build/{{PROJECT_NAME}}.Core' >&2
    exit 1
}

[ -f "src/{{PROJECT_NAME}}.Core/{{PROJECT_NAME}}.Core.csproj" ]
[ -f "tests/{{PROJECT_NAME}}.Core/{{PROJECT_NAME}}.Core.Tests.csproj" ]
