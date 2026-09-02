.PHONY: help verify build tests up down

help:
	@printf '%s\n' 'Targets: verify, build, tests, up, down'

verify:
	docker compose -f tools/docker/verify.yaml run --rm verify

build:
	docker compose -f tools/docker/build.yaml run --rm build

tests:
	docker compose -f tools/docker/tests.yaml run --rm tests

up:
	docker compose -f tools/docker/compose.yaml up -d workspace

down:
	docker compose -f tools/docker/compose.yaml down
