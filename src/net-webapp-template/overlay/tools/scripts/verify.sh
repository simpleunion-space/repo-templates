#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

for path in \
    "src/{{PROJECT_NAME}}.WebApp/{{PROJECT_NAME}}.WebApp.csproj" \
    "src/{{PROJECT_NAME}}.WebApp/Program.cs" \
    "src/{{PROJECT_NAME}}.WebApp/Pages/Index.cshtml" \
    "tests/{{PROJECT_NAME}}.WebApp/{{PROJECT_NAME}}.WebApp.Tests.csproj" \
    "build/{{PROJECT_NAME}}.WebApp/.gitkeep"; do
    [ -f "$path" ] || {
        printf 'Required web application path is missing: %s\n' "$path" >&2
        exit 1
    }
done
