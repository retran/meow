#!/usr/bin/env bash

# lib/greeting/comments.sh - Functions for managing greeting comments

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_COMMENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_COMMENTS_SOURCED=1

# Load comments from YAML files
load_yaml_comments() {
  local category="$1"
  local section="$2"
  local yaml_file="${ASSETS_DIR}/comments/${category}.yaml"

  if [[ ! -f "$yaml_file" ]]; then
    return 1
  fi

  if command -v yq >/dev/null 2>&1; then
    yq ".${category}.${section}[]" "$yaml_file" 2>/dev/null | sed 's/^"//; s/"$//'
  else
    return 1
  fi
}

# Backward compatibility - now just a no-op
init_comment_collections() {
  return 0
}

get_random_comment() {
  local category="$1"
  local section="$2"

  # Load comments directly from YAML
  local collection_content
  collection_content=$(load_yaml_comments "$category" "$section")
  if [[ $? -ne 0 || -z "$collection_content" ]]; then
    echo "No comments available for ${category}.${section}"
    return 1
  fi

  local lines=()
  local line
  local old_ifs="$IFS"
  IFS=$'\n'
  while IFS= read -r line || [[ -n "$line" ]]; do
      line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ -n "$line" ]]; then
          lines+=("$line")
      fi
  done <<< "$collection_content"
  IFS="$old_ifs"

  if [[ ${#lines[@]} -eq 0 ]]; then
    echo "No usable comments in ${category}.${section}"
    return 1
  fi

  echo "${lines[$((RANDOM % ${#lines[@]}))]}"
}

get_comment_collection() {
  local result=()
  local line

  # Process arguments in pairs: category section category section ...
  while [[ $# -ge 2 ]]; do
    local category="$1"
    local section="$2"
    shift 2

    # Load comments directly from YAML
    local collection_content
    collection_content=$(load_yaml_comments "$category" "$section")
    if [[ $? -eq 0 && -n "$collection_content" ]]; then
      local old_ifs="$IFS"
      IFS=$'\n'
      while IFS= read -r line || [[ -n "$line" ]]; do
          line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ -n "$line" ]]; then
            result+=("$line")
          fi
      done <<< "$collection_content"
      IFS="$old_ifs"
    fi
  done

  if [[ ${#result[@]} -eq 0 ]]; then
    echo "A fancy digital cat comment should be here"
    return 0
  fi

  echo "${result[$((RANDOM % ${#result[@]}))]}"
}