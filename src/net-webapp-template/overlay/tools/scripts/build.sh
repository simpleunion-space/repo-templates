#!/usr/bin/env sh
set -eu

mkdir -p "build/{{PROJECT_NAME}}.Core" "build/{{PROJECT_NAME}}.WebApp"
dotnet restore "src/{{PROJECT_NAME}}.slnx"
dotnet build "src/{{PROJECT_NAME}}.Core/{{PROJECT_NAME}}.Core.csproj" --configuration Release --no-restore --output "build/{{PROJECT_NAME}}.Core"
dotnet build "src/{{PROJECT_NAME}}.WebApp/{{PROJECT_NAME}}.WebApp.csproj" --configuration Release --no-restore --output "build/{{PROJECT_NAME}}.WebApp"
