#!/usr/bin/env bash

if [[ -n "${_LIB_YAML_SOURCED:-}" ]]; then
  return 0
fi
_LIB_YAML_SOURCED=1

read_yaml_value() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  yq eval "$yaml_path" "$yaml_file" 2>/dev/null
}

read_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local result
  result=$(yq eval "$yaml_path" "$yaml_file" 2>/dev/null) || return 1

  if [[ -z "$result" || "$result" = "null" ]]; then
    return 1
  fi
  printf '%s\n' "$result"
}

process_yaml_array() {
  local yaml_file="$1"
  local yaml_path="$2"
  local callback="$3"
  shift 3

  local array_content
  array_content=$(read_yaml_array "$yaml_file" "$yaml_path") || return 0

  while IFS= read -r item; do
    if [[ -n "$item" && "$item" != "null" ]]; then
      "$callback" "$item" "$@"
    fi
  done < <(printf '%s\n' "$array_content")
}

yaml_path_exists() {
  local yaml_file="$1"
  local yaml_path="$2"

  [[ -f "$yaml_file" ]] || return 1
  local value
  value=$(read_yaml_value "$yaml_file" "$yaml_path")

  [[ -n "$value" && "$value" != "null" ]]
}
