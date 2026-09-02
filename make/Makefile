.PHONY: help verify build tests up down generate-powershell generate-bash

PROFILE ?= base
NAME ?=
DESTINATION ?=
DOTNET_SDK_VERSION ?= 10.0.302
TARGET_FRAMEWORK ?= net10.0
PYTHON_VERSION ?= 3.12
UNITY_VERSION ?= 6000.3.17f1

help:
	@printf '%s\n' 'Targets: verify, build, tests, up, down, generate-powershell, generate-bash'

verify:
	docker compose -f tools/docker/verify.yaml run --rm template-verify

build:
	docker compose -f tools/docker/build.yaml run --rm template-build

tests:
	docker compose -f tools/docker/tests.yaml run --rm template-tests

up:
	docker compose -f tools/docker/compose.yaml up -d workspace

down:
	docker compose -f tools/docker/compose.yaml down

generate-powershell:
	@test -n "$(NAME)" && test -n "$(DESTINATION)" || (printf '%s\n' 'NAME and DESTINATION are required.' >&2; exit 2)
	pwsh -NoProfile -File make/New-RepositoryFromTemplate.ps1 -Profile "$(PROFILE)" -Name "$(NAME)" -Destination "$(DESTINATION)" -DotnetSdkVersion "$(DOTNET_SDK_VERSION)" -TargetFramework "$(TARGET_FRAMEWORK)" -PythonVersion "$(PYTHON_VERSION)" -UnityVersion "$(UNITY_VERSION)"

generate-bash:
	@test -n "$(NAME)" && test -n "$(DESTINATION)" || (printf '%s\n' 'NAME and DESTINATION are required.' >&2; exit 2)
	bash make/New-RepositoryFromTemplate.sh --profile "$(PROFILE)" --name "$(NAME)" --destination "$(DESTINATION)" --dotnet-sdk-version "$(DOTNET_SDK_VERSION)" --target-framework "$(TARGET_FRAMEWORK)" --python-version "$(PYTHON_VERSION)" --unity-version "$(UNITY_VERSION)"
