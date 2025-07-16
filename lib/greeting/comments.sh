#!/usr/bin/env bash

# lib/greeting/comments.sh - Functions for managing greeting comments

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_COMMENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_COMMENTS_SOURCED=1

declare -A COMMENT_COLLECTIONS

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

init_comment_collections() {
  # Map old collection names to new YAML structure
  local -A comment_mapping=(
    ["uptime_base"]="uptime base"
    ["uptime_days_many"]="uptime days_many"
    ["uptime_days_week"]="uptime days_week"
    ["uptime_days_few"]="uptime days_few"
    ["uptime_hours"]="uptime hours"
    ["uptime_fallback"]="uptime fallback"
    ["disk_base"]="disk base"
    ["disk_tb"]="disk tb"
    ["disk_gb_plenty"]="disk gb_plenty"
    ["disk_gb_low"]="disk gb_low"
    ["disk_mb"]="disk mb"
    ["disk_fallback"]="disk fallback"
    ["ram_base"]="ram base"
    ["ram_gb_plenty"]="ram gb_plenty"
    ["ram_mb_low"]="ram mb_low"
    ["ram_fallback"]="ram fallback"
    ["package_base"]="package base"
    ["package_many"]="package many"
    ["package_some"]="package some"
    ["package_few"]="package few"
    ["package_fallback"]="package fallback"
    ["greeting_morning_early"]="greeting morning_early"
    ["greeting_morning"]="greeting morning"
    ["greeting_morning_late"]="greeting morning_late"
    ["greeting_afternoon"]="greeting afternoon"
    ["greeting_afternoon_mid"]="greeting afternoon_mid"
    ["greeting_afternoon_late"]="greeting afternoon_late"
    ["greeting_evening"]="greeting evening"
    ["greeting_evening_late"]="greeting evening_late"
    ["greeting_night"]="greeting night"
    ["greeting_night_late"]="greeting night_late"
    ["greeting_night_predawn"]="greeting night_predawn"
  )

  for collection_key in "${!comment_mapping[@]}"; do
    local mapping="${comment_mapping[$collection_key]}"
    local category="${mapping%% *}"
    local section="${mapping#* }"

    local comments
    comments=$(load_yaml_comments "$category" "$section")
    if [[ $? -eq 0 && -n "$comments" ]]; then
      COMMENT_COLLECTIONS["$collection_key"]="$comments"
    fi
  done
}

get_random_comment() {
  local collection_name="$1"
  local collection_content="${COMMENT_COLLECTIONS[$collection_name]}"

  if [[ -z "$collection_content" ]]; then
    echo "No comments available for $collection_name"
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
    echo "No usable comments in $collection_name"
    return 1
  fi

  echo "${lines[$((RANDOM % ${#lines[@]}))]}"
}

get_comment_collection() {
  local result=()
  local line

  for collection_name in "$@"; do
    if [[ -n "${COMMENT_COLLECTIONS[$collection_name]}" ]]; then
      local old_ifs="$IFS"
      IFS=$'\n'
      while IFS= read -r line || [[ -n "$line" ]]; do
          line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ -n "$line" ]]; then
            result+=("$line")
          fi
      done <<< "${COMMENT_COLLECTIONS[$collection_name]}"
      IFS="$old_ifs"
    fi
  done

  if [[ ${#result[@]} -eq 0 ]]; then
    echo "A fancy digital cat comment should be here"
    return 0
  fi

  echo "${result[$((RANDOM % ${#result[@]}))]}"
}