#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

for path in \
    "src/{{PROJECT_NAME}}.DesktopApp/{{PROJECT_NAME}}.DesktopApp.csproj" \
    "src/{{PROJECT_NAME}}.DesktopApp/App.axaml" \
    "src/{{PROJECT_NAME}}.DesktopApp/MainWindow.axaml" \
    "tests/{{PROJECT_NAME}}.DesktopApp/{{PROJECT_NAME}}.DesktopApp.Tests.csproj" \
    "build/{{PROJECT_NAME}}.DesktopApp/.gitkeep"; do
    [ -f "$path" ] || {
        printf 'Required desktop application path is missing: %s\n' "$path" >&2
        exit 1
    }
done
