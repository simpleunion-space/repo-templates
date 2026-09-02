#!/usr/bin/env sh
set -eu

dotnet format "src/{{PROJECT_NAME}}.slnx" --verify-no-changes
dotnet test "src/{{PROJECT_NAME}}.slnx" --no-restore
dotnet run --project "src/{{PROJECT_NAME}}.ConsoleApp/{{PROJECT_NAME}}.ConsoleApp.csproj" --no-restore | grep -Fx "{{PROJECT_NAME}}"
