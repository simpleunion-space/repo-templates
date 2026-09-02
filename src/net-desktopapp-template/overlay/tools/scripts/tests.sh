#!/usr/bin/env sh
set -eu

dotnet format "src/{{PROJECT_NAME}}.slnx" --verify-no-changes
dotnet test "src/{{PROJECT_NAME}}.slnx" --no-restore
