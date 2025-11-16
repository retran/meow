#!/usr/bin/env bash
# MIT License
#
# (header omitted for brevity)
#
if [ -n "${_LIB_PACKAGE_CONFIG_SOURCED:-}" ]; then
  return 0
fi
_LIB_PACKAGE_CONFIG_SOURCED=1

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/yaml.sh"

: "${MEOW_ACTIVE_PRESET_FILE:=}"

MEOW_DEFAULT_PRESET_FILE="${MEOW}/presets/base/preset.yaml"

_meow_pkg_resolve_file() {
  local file="$1"
  [ -f "$file" ] || return 0
  yq -o=json '.packages // []' "$file" 2>/dev/null
}

_meow_pkg_match_entry() {
  local json="$1"
  local platform="$2"
  local distro="$3"
  local likes="$4"
  python3 - "$platform" "$distro" "$likes" <<'PY' <<<"$json"
import json
import sys
platform, distro, likes = sys.argv[1], sys.argv[2], sys.argv[3].split(',') if sys.argv[3] else []
data = json.load(sys.stdin)
result = []
def to_list(v):
    if not v:
        return []
    if isinstance(v, list):
        return v
    return [v]
for entry in data:
    match = entry.get('match') or {}
    platforms = to_list(match.get('platform'))
    if platforms and platform not in platforms:
        continue
    distros = to_list(match.get('distro'))
    if distros and distro not in distros:
        continue
    distro_like = to_list(match.get('distro_like'))
    if distro_like and not any(item in likes for item in distro_like):
        continue
    result.append(entry)
print(json.dumps(result))
PY
}

_meow_pkg_merge_managers() {
  local current="$1"
  local json="$2"
  python3 - "$current" <<'PY' <<<"$json"
import json
import sys
current = sys.argv[1].split() if sys.argv[1] else []
data = json.load(sys.stdin)
for entry in data:
    managers = entry.get('managers') or {}
    include = managers.get('include') or []
    for item in include:
        if item not in current:
            current.append(item)
    exclude = managers.get('exclude') or []
    current = [item for item in current if item not in exclude]
print(' '.join(current))
PY
}

_meow_pkg_collect_sources() {
  local file="$1"
  local manager="$2"
  local json="$3"
  python3 - "$manager" <<'PY' <<<"$json"
import json
import sys
manager = sys.argv[1]
data = json.load(sys.stdin)
for entry in data:
    for source in entry.get('sources') or []:
        if source.get('manager') == manager:
            fields = [source.get('name',''), source.get('repo',''), source.get('repo_file',''), source.get('key_url',''), source.get('gpg_key','')]
            print("\t".join(field.replace("\t"," ") for field in fields))
PY
}

_meow_pkg_read_stack() {
  local platform="$1"
  local distro="$2"
  local likes="$3"
  local component="$4"
  local result="[]"

  local preset_file=""
  if [ -n "$MEOW_ACTIVE_PRESET_FILE" ]; then
    preset_file="$MEOW_ACTIVE_PRESET_FILE"
  elif [ -f "$MEOW_DEFAULT_PRESET_FILE" ]; then
    preset_file="$MEOW_DEFAULT_PRESET_FILE"
  fi

  if [ -n "$preset_file" ]; then
    local preset_entries
    preset_entries=$(_meow_pkg_collect_from_preset "$preset_file")
    result=$(python3 - "$result" "$preset_entries" <<'PY'
import json, sys
base = json.loads(sys.argv[1])
entries = json.loads(sys.argv[2])
base.extend(entries)
print(json.dumps(base))
PY)
  fi

  local component_file="${MEOW_COMPONENTS_DIR}/${component}/component.yaml"
  local json
  json=$(_meow_pkg_resolve_file "$component_file") || echo "[]"
  local matches
  matches=$(_meow_pkg_match_entry "$json" "$platform" "$distro" "$likes")
  result=$(python3 - "$result" "$matches" <<'PY'
import json, sys
base = json.loads(sys.argv[1])
entries = json.loads(sys.argv[2])
base.extend(entries)
print(json.dumps(base))
PY)

  echo "$result"
}

meow_pm_resolve_for_component() {
  local component="$1"
  local platform
  platform=$(get_platform)
  local distro="${MEOW_OS_ID:-}"
  local likes="${MEOW_OS_ID_LIKE// /,}"
  local entries
  entries=$(_meow_pkg_read_stack "$platform" "$distro" "$likes" "$component")
  local managers=""
  managers=$(_meow_pkg_merge_managers "$managers" "$entries")
  if [ -z "$managers" ]; then
    if [ "$IS_MACOS" = "true" ]; then
      managers="homebrew mas pipx npm go cargo vscode"
    else
      managers="pipx npm go cargo vscode apt dnf apk pacman snap"
    fi
  fi
  echo "$managers"
}

meow_pm_collect_sources_for_manager() {
  local component="$1"
  local manager="$2"
  local platform
  platform=$(get_platform)
  local distro="${MEOW_OS_ID:-}"
  local likes="${MEOW_OS_ID_LIKE// /,}"
  local entries
  entries=$(_meow_pkg_read_stack "$platform" "$distro" "$likes" "$component")
  _meow_pkg_collect_sources "$component" "$manager" "$entries"
}

_meow_pkg_collect_from_preset() {
  local preset_file="$1"
  [ -f "$preset_file" ] || { echo "[]"; return; }
  python3 - "$preset_file" "$MEOW_PRESETS_DIR" <<'PY'
import json, sys, yaml, os
preset_file = sys.argv[1]
base_dir = sys.argv[2]
visited = set()

def gather(file):
    if not os.path.isfile(file) or file in visited:
        return []
    visited.add(file)
    with open(file) as fh:
        data = yaml.safe_load(fh) or {}
    result = []
    for parent in data.get('extends') or []:
        parent_file = os.path.join(base_dir, parent, 'preset.yaml')
        result.extend(gather(parent_file))
    result.extend(data.get('packages') or [])
    return result

print(json.dumps(gather(preset_file)))
PY
}
