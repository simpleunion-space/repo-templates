#!/usr/bin/env sh
set -eu

mkdir -p "build/{{PROJECT_NAME}}.Core" "build/{{PROJECT_NAME}}.ConsoleApp"
dotnet restore "src/{{PROJECT_NAME}}.slnx"
dotnet build "src/{{PROJECT_NAME}}.Core/{{PROJECT_NAME}}.Core.csproj" --configuration Release --no-restore --output "build/{{PROJECT_NAME}}.Core"
dotnet build "src/{{PROJECT_NAME}}.ConsoleApp/{{PROJECT_NAME}}.ConsoleApp.csproj" --configuration Release --no-restore --output "build/{{PROJECT_NAME}}.ConsoleApp"
