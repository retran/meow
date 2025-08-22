#!/usr/bin/env bash

if [[ -n "${_LIB_YAML_SOURCED:-}" ]]; then
  return 0
fi
_LIB_YAML_SOURCED=1

# Read a single YAML value from a file
read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  yq eval "$yaml_path" "$yaml_file" 2>/dev/null
}

# Read a YAML array and return items line by line
read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local result
  result=$(yq eval "$yaml_path" "$yaml_file" 2>/dev/null) || return 1
  [[ -n "$result" && "$result" != "null" ]] || return 1
  printf '%s\n' "$result"
}

# Process each item in a YAML array with a callback function
process_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"
  local callback="$3"
  shift 3

  local array_content
  array_content=$(read_yaml_array "$yaml_file" "$yaml_path") || return 0

  while IFS= read -r item; do
    [[ -n "$item" && "$item" != "null" ]] || continue
    "$callback" "$item" "$@"
  done < <(printf '%s\n' "$array_content")
}

# Check if a YAML path exists and has a non-null value
yaml_path_exists() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local value
  value=$(read_yaml_value "$yaml_file" "$yaml_path")
  [[ -n "$value" && "$value" != "null" ]]
}
