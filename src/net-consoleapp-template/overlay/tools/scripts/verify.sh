#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

for path in \
    "src/{{PROJECT_NAME}}.ConsoleApp/{{PROJECT_NAME}}.ConsoleApp.csproj" \
    "src/{{PROJECT_NAME}}.ConsoleApp/Program.cs" \
    "tests/{{PROJECT_NAME}}.ConsoleApp/{{PROJECT_NAME}}.ConsoleApp.Tests.csproj" \
    "build/{{PROJECT_NAME}}.ConsoleApp/.gitkeep"; do
    [ -f "$path" ] || {
        printf 'Required console application path is missing: %s\n' "$path" >&2
        exit 1
    }
done
