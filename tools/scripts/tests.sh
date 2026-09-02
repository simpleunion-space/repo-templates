#!/usr/bin/env sh
set -eu

shell_files=$(find make tools src -type f -name '*.sh' -print)
[ -n "$shell_files" ] && printf '%s\n' "$shell_files" | xargs shellcheck -x

yaml_files=$(find tools src -type f \( -name '*.yaml' -o -name '*.yml' \) -print)
[ -n "$yaml_files" ] && printf '%s\n' "$yaml_files" | xargs yamllint -c .yamllint

export RUFF_CACHE_DIR=/tmp/ruff-cache
ruff check --ignore EXE002 tests
ruff format --check tests
pwsh -NoProfile -Command "Invoke-ScriptAnalyzer -Path make/New-RepositoryFromTemplate.ps1 -ExcludeRule PSAvoidAssignmentToAutomaticVariable,PSUseShouldProcessForStateChangingFunctions,PSUseApprovedVerbs,PSUseSingularNouns -EnableExit"
