#!/usr/bin/env sh
set -eu

for directory in src tests make tools tools/scripts tools/docker; do
    if [ ! -d "$directory" ]; then
        printf 'Required directory is missing: %s\n' "$directory" >&2
        exit 1
    fi
done

for file in README.md README_EN.md AGENTS.md AGENTS_EN.md CODESTYLE.md CODESTYLE_EN.md \
    make/Makefile tools/scripts/verify.sh tools/scripts/verify-template.sh tools/scripts/build.sh tools/scripts/tests.sh tools/docker/Dockerfile \
    tools/docker/verify.yaml tools/docker/build.yaml tools/docker/tests.yaml tools/docker/compose.yaml; do
    if [ ! -f "$file" ]; then
        printf 'Required file is missing: %s\n' "$file" >&2
        exit 1
    fi
done

token_start='{'
token_start="${token_start}${token_start}"
if grep -R -F "$token_start" . --exclude-dir=.git >/dev/null 2>&1; then
    printf '%s\n' 'Unresolved template tokens found.' >&2
    exit 1
fi

if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git diff --check
fi
