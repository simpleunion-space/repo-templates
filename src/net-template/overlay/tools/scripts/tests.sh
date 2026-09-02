#!/usr/bin/env sh
set -eu

dotnet format "src/{{PROJECT_NAME}}.slnx" --verify-no-changes
dotnet test "tests/{{PROJECT_NAME}}.Core/{{PROJECT_NAME}}.Core.Tests.csproj" --no-restore
