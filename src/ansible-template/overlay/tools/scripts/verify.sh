#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

for directory in src/playbooks src/roles src/inventories; do
    [ -d "$directory" ] || {
        printf 'Required Ansible directory is missing: %s\n' "$directory" >&2
        exit 1
    }
done

[ -f tests/.gitkeep ]
[ -f .ansible-lint ]
