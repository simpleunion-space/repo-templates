#!/usr/bin/env sh
set -eu

sh tools/scripts/verify-template.sh

for directory in src/states src/pillar; do
    [ -d "$directory" ] || {
        printf 'Required Salt directory is missing: %s\n' "$directory" >&2
        exit 1
    }
done

[ -f tests/.gitkeep ]
[ -f .salt-lint ]
