#!/usr/bin/env bash
# Bash 3.2+
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: New-RepositoryFromTemplate.sh --profile PROFILE --name NAME --destination DIRECTORY [options]'
}

profile=''
project_name=''
destination=''
dotnet_sdk_version='10.0.302'
target_framework='net10.0'
python_version='3.12'
unity_version='6000.3.17f1'

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) profile=${2:?missing profile}; shift 2 ;;
    --name) project_name=${2:?missing name}; shift 2 ;;
    --destination) destination=${2:?missing destination}; shift 2 ;;
    --dotnet-sdk-version) dotnet_sdk_version=${2:?missing version}; shift 2 ;;
    --target-framework) target_framework=${2:?missing framework}; shift 2 ;;
    --python-version) python_version=${2:?missing version}; shift 2 ;;
    --unity-version) unity_version=${2:?missing version}; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$profile" in base|net|net-consoleapp|net-webapp|net-desktopapp|python|unity|iac-base|ansible|salt) ;; *) printf 'Unsupported profile: %s\n' "$profile" >&2; exit 2 ;; esac
case "$project_name" in ''|[!A-Za-z]*|*[!A-Za-z0-9._-]*) printf 'Invalid project name: %s\n' "$project_name" >&2; exit 2 ;; esac
command -v python3 >/dev/null 2>&1 || { printf '%s\n' 'python3 is required to read template manifests.' >&2; exit 127; }

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
catalog_root=$(CDPATH='' cd -- "$script_dir/.." && pwd -P)
source_root="$catalog_root/src"

directory_has_entries() {
  directory=$1
  for entry in "$directory"/* "$directory"/.[!.]* "$directory"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    return 0
  done
  return 1
}

assert_empty_destination() {
  candidate=$1
  [ ! -e "$candidate" ] && return 0
  [ -d "$candidate" ] || { printf 'Destination must be a directory: %s\n' "$candidate" >&2; return 1; }
  directory_has_entries "$candidate" && { printf 'Destination must be empty: %s\n' "$candidate" >&2; return 1; }
}

public_destination=$destination
assert_empty_destination "$public_destination" || exit 2
scratch_destination=$(mktemp -d "${TMPDIR:-/tmp}/repo-template.XXXXXX")
trap 'rm -rf "$scratch_destination"' EXIT
destination=$(CDPATH='' cd -- "$scratch_destination" && pwd -P)

safe_relative_path() {
  path=$1
  normalized=${path//\\//}
  case "$normalized" in ''|/*|[A-Za-z]:/*|*'?'*|*'['*|*']'*|*'*'*|*'<'*|*'>'*|*'|'*|*':'*) return 1 ;; esac
  case "/$normalized/" in */../*) return 1 ;; esac
  return 0
}

project_slug=$(printf '%s' "$project_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9][^a-z0-9]*/-/g; s/^-//; s/-$//')
[ -n "$project_slug" ] || { printf '%s\n' 'The project name does not produce a usable slug.' >&2; exit 2; }
python_package=$(printf '%s' "$project_slug" | tr '-' '_')

base_manifest="$source_root/base-template/.template/template.json"
[ -f "$base_manifest" ] || { printf 'Base template manifest is missing: %s\n' "$base_manifest" >&2; exit 2; }

profile_chain=$(python3 - "$source_root" "$profile" "$base_manifest" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
requested = sys.argv[2]
base = json.loads(pathlib.Path(sys.argv[3]).read_text(encoding='utf-8'))
if base.get('schemaVersion') != 2:
    raise SystemExit('Base template manifest must use schema version 2.')
if requested == 'base':
    raise SystemExit(0)
seen = set()
chain = []
current = requested
while current != 'base':
    if current in seen:
        raise SystemExit(f'Profile inheritance cycle detected at: {current}')
    seen.add(current)
    manifest_path = root / f'{current}-template' / '.template' / 'profile.json'
    if not manifest_path.is_file():
        raise SystemExit(f'Profile manifest is missing: {manifest_path}')
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if manifest.get('id') != current:
        raise SystemExit(f'Profile manifest id does not match directory: {current}')
    if manifest.get('schemaVersion') != 2:
        raise SystemExit(f'Profile manifest {current} must use schema version 2.')
    if manifest.get('requiredBaseSchemaVersion') != base.get('schemaVersion'):
        raise SystemExit(f'Profile {current} requires an unsupported base schema.')
    parent = manifest.get('parentProfile')
    if not parent:
        raise SystemExit(f'Profile {current} must declare parentProfile.')
    if parent == 'base' and manifest.get('requiredParentSchemaVersion') != base.get('schemaVersion'):
        raise SystemExit(f'Profile {current} requires an unsupported parent schema.')
    chain.append((current, manifest))
    current = parent
chain.reverse()
for index, (profile_id, manifest) in enumerate(chain):
    if index:
        parent_id, parent = chain[index - 1]
        if manifest.get('parentProfile') != parent_id or manifest.get('requiredParentSchemaVersion') != parent.get('schemaVersion'):
            raise SystemExit(f'Profile inheritance is incompatible for: {profile_id}')
    print(profile_id)
PY
)

requirements_file=$(mktemp "${TMPDIR:-/tmp}/repo-template-requirements.XXXXXX")
expanded_requirements_file=$(mktemp "${TMPDIR:-/tmp}/repo-template-expanded-requirements.XXXXXX")
trap 'rm -f "$requirements_file" "$expanded_requirements_file"; rm -rf "$scratch_destination"' EXIT

# shellcheck disable=SC2086
python3 - "$source_root" "$base_manifest" $profile_chain > "$requirements_file" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
base = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding='utf-8'))
manifests = [base]
for profile_id in sys.argv[3:]:
    manifest_path = root / f'{profile_id}-template' / '.template' / 'profile.json'
    manifests.append(json.loads(manifest_path.read_text(encoding='utf-8')))

effective = {}
for manifest in manifests:
    requirements = manifest.get('pathRequirements')
    if not isinstance(requirements, list):
        raise SystemExit(f"Manifest {manifest.get('id')} must define pathRequirements as a list.")
    for requirement in requirements:
        if not isinstance(requirement, dict):
            raise SystemExit(f"Manifest {manifest.get('id')} contains an invalid path requirement.")
        path = requirement.get('path')
        kind = requirement.get('kind')
        status = requirement.get('status')
        if not isinstance(path, str) or kind not in {'file', 'directory'} or status not in {'required', 'optional'}:
            raise SystemExit(f"Manifest {manifest.get('id')} contains an invalid path requirement.")
        effective[(kind, path)] = status

for (kind, path), status in sorted(effective.items()):
    print(f'{kind}\t{status}\t{path}')
PY

copy_template_content() {
  source=$1
  target=$2
  shopt -s dotglob nullglob
  for item in "$source"/*; do
    name=${item##*/}
    [ "$name" = '.git' ] || [ "$name" = '.template' ] || cp -R "$item" "$target/"
  done
  shopt -u dotglob nullglob
}

copy_template_content "$source_root/base-template" "$destination"

for profile_id in $profile_chain; do
  profile_dir="$source_root/$profile_id-template"
  manifest="$profile_dir/.template/profile.json"
  [ ! -d "$profile_dir/overlay" ] || copy_template_content "$profile_dir/overlay" "$destination"
  while IFS=$'\t' read -r fragment_source fragment_target; do
    [ -n "$fragment_source" ] || continue
    if ! safe_relative_path "$fragment_source" || ! safe_relative_path "$fragment_target"; then
      printf '%s\n' 'Unsafe profile fragment path.' >&2
      exit 2
    fi
    if [ ! -f "$profile_dir/$fragment_source" ] || [ ! -f "$destination/$fragment_target" ]; then
      printf '%s\n' 'Profile fragment is missing or has no target.' >&2
      exit 2
    fi
    printf '\n# Profile overlay: %s\n' "$profile_id" >> "$destination/$fragment_target"
    fragment_content=$(sed 's/\r$//' "$profile_dir/$fragment_source"; printf x)
    fragment_content=${fragment_content%x}
    while [ "${fragment_content%$'\n'}" != "$fragment_content" ]; do fragment_content=${fragment_content%$'\n'}; done
    printf '%s\n' "$fragment_content" >> "$destination/$fragment_target"
  done <<EOF
$(python3 - "$manifest" <<'PY'
import json, sys
for item in json.load(open(sys.argv[1], encoding='utf-8')).get('fragments', []):
    print(f"{item['source']}\t{item['target']}")
PY
)
EOF
  while IFS= read -r remove_path; do
    [ -n "$remove_path" ] || continue
    safe_relative_path "$remove_path" || { printf 'Unsafe profile path: %s\n' "$remove_path" >&2; exit 2; }
    rm -rf "${destination:?}/${remove_path:?}"
  done <<EOF
$(python3 - "$manifest" <<'PY'
import json, sys
for item in json.load(open(sys.argv[1], encoding='utf-8')).get('removePaths', []):
    print(item)
PY
)
EOF
done

replace_path_token() {
  token=$1
  value=$2
  find "$destination" -depth -print | while IFS= read -r path; do
    name=${path##*/}
    replacement=${name//"{{${token}}}"/$value}
    [ "$name" = "$replacement" ] || mv "$path" "${path%/*}/$replacement"
  done
}
replace_path_token PROJECT_NAME "$project_name"
replace_path_token PROJECT_SLUG "$project_slug"
replace_path_token PYTHON_PACKAGE "$python_package"
replace_path_token DOTNET_SDK_VERSION "$dotnet_sdk_version"
replace_path_token TARGET_FRAMEWORK "$target_framework"
replace_path_token PYTHON_VERSION "$python_version"
replace_path_token UNITY_VERSION "$unity_version"

replace_file_tokens() {
  file=$1
  content=$(cat "$file"; printf x)
  content=${content%x}
  content=${content//"{{PROJECT_NAME}}"/$project_name}
  content=${content//"{{PROJECT_SLUG}}"/$project_slug}
  content=${content//"{{PYTHON_PACKAGE}}"/$python_package}
  content=${content//"{{DOTNET_SDK_VERSION}}"/$dotnet_sdk_version}
  content=${content//"{{TARGET_FRAMEWORK}}"/$target_framework}
  content=${content//"{{PYTHON_VERSION}}"/$python_version}
  content=${content//"{{UNITY_VERSION}}"/$unity_version}
  printf '%s' "$content" | tr -d '\r' > "$file"
}

expand_requirement_path() {
  value=$1
  value=${value//"{{PROJECT_NAME}}"/$project_name}
  value=${value//"{{PROJECT_SLUG}}"/$project_slug}
  value=${value//"{{PYTHON_PACKAGE}}"/$python_package}
  value=${value//"{{DOTNET_SDK_VERSION}}"/$dotnet_sdk_version}
  value=${value//"{{TARGET_FRAMEWORK}}"/$target_framework}
  value=${value//"{{PYTHON_VERSION}}"/$python_version}
  value=${value//"{{UNITY_VERSION}}"/$unity_version}
  case "$value" in *'{{'*'}}'*) printf 'Unresolved template token in path requirement: %s\n' "$value" >&2; exit 2 ;; esac
  printf '%s' "$value"
}

tab=$(printf '\t')
while IFS="$tab" read -r kind status path; do
  safe_relative_path "$path" || { printf 'Unsafe path requirement: %s\n' "$path" >&2; exit 2; }
  path=$(expand_requirement_path "$path")
  safe_relative_path "$path" || { printf 'Unsafe resolved path requirement: %s\n' "$path" >&2; exit 2; }
  case "$kind:$status" in
    file:required|file:optional|directory:required|directory:optional) ;;
    *) printf 'Invalid path requirement.\n' >&2; exit 2 ;;
  esac
  printf '%s\t%s\t%s\n' "$kind" "$status" "$path" >> "$expanded_requirements_file"
done < "$requirements_file"

has_required_descendant() {
  directory=$1
  while IFS="$tab" read -r _ other_status other_path; do
    [ "$other_status" = 'required' ] || continue
    [ "$other_path" = "$directory" ] && continue
    case "$other_path" in "$directory"/*) return 0 ;; esac
  done < "$expanded_requirements_file"
  return 1
}

directory_has_real_content() {
  directory=$1
  real_files=$(find "$directory" -type f ! -name '.gitkeep' -print)
  [ -n "$real_files" ]
}

publish_template_content() {
  source=$1
  target=$2

  assert_empty_destination "$target" || return 1
  if [ ! -e "$target" ]; then
    target_parent=$(dirname "$target")
    mkdir -p "$target_parent" || return 1
    mkdir "$target" || {
      printf 'Destination appeared during publication: %s\n' "$target" >&2
      return 1
    }
  fi

  while IFS= read -r source_path; do
    relative_path=${source_path#./}
    [ "$relative_path" = '.' ] && continue
    target_path="$target/$relative_path"
    [ ! -e "$target_path" ] || { printf 'Destination path appeared during publication: %s\n' "$target_path" >&2; return 1; }
    mkdir "$target_path" || return 1
  done < <(cd "$source" && find . -type d -print)

  while IFS= read -r source_path; do
    relative_path=${source_path#./}
    target_path="$target/$relative_path"
    [ ! -e "$target_path" ] || { printf 'Destination path appeared during publication: %s\n' "$target_path" >&2; return 1; }
    (set -C; cat "$source/$relative_path" > "$target_path") || {
      printf 'Could not publish destination file without overwriting: %s\n' "$target_path" >&2
      return 1
    }
  done < <(cd "$source" && find . -type f -print)
}

while IFS="$tab" read -r kind status path; do
  if [ "$kind" != 'directory' ] || [ "$status" != 'optional' ]; then
    continue
  fi
  [ -d "$destination/$path" ] || continue
  has_required_descendant "$path" && continue
  directory_has_real_content "$destination/$path" || rm -rf "${destination:?}/${path:?}"
done < "$expanded_requirements_file"

while IFS="$tab" read -r kind status path; do
  [ "$status" = 'required' ] || continue
  case "$kind" in
    file) [ -f "$destination/$path" ] || { printf 'Required file path is missing: %s\n' "$path" >&2; exit 2; } ;;
    directory) [ -d "$destination/$path" ] || { printf 'Required directory path is missing: %s\n' "$path" >&2; exit 2; } ;;
  esac
done < "$expanded_requirements_file"

while IFS= read -r file; do
  case "$file" in *.asmdef|*.axaml|*.cs|*.cshtml|*.csproj|*.editorconfig|*.env|*.gitattributes|*.gitignore|*.json|*.md|*.meta|*.props|*.ps1|*.py|*.sh|*.slnx|*.toml|*.txt|*.unity|*.xml|*.yaml|*.yml|*/Dockerfile) replace_file_tokens "$file" ;; esac
done <<EOF
$(find "$destination" -type f -print)
EOF

if grep -R -E '{{[A-Z0-9_]+}}' "$destination" >/dev/null 2>&1; then
  printf '%s\n' 'Unresolved template tokens found.' >&2
  exit 2
fi

publish_template_content "$destination" "$public_destination"
printf 'Created %s template at %s\n' "$profile" "$public_destination"
