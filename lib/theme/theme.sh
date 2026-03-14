#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/theme/theme.sh
# @brief: Theme helpers for unified theme management.
# @author: Andrew Vasilyev
# @license: MIT

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  set -euo pipefail
fi

MEOW_THEME_DB="${MEOW:-$HOME/.meow}/themes.yaml"

source "${MEOW:-$HOME/.meow}/lib/core/tools.sh"
source "${MEOW:-$HOME/.meow}/lib/core/yaml.sh"
source "${MEOW:-$HOME/.meow}/lib/config/config.sh"

# Theme database cache.
# Use a plain newline-delimited store for Bash 3.2 compatibility on macOS.
MEOW_THEME_CACHE=""

# Clear theme cache
theme_cache_clear() {
  MEOW_THEME_CACHE=""
}

# Get cache key
theme_cache_key() {
  echo "${MEOW_THEME_DB}:$1"
}

theme_cache_get() {
  local cache_key="$1"
  local entry_key
  local entry_value

  while IFS=$'\t' read -r entry_key entry_value; do
    if [[ "$entry_key" == "$cache_key" ]]; then
      echo "$entry_value"
      return 0
    fi
  done <<<"${MEOW_THEME_CACHE}"

  return 1
}

theme_cache_set() {
  local cache_key="$1"
  local value="$2"
  local new_cache=""
  local entry_key
  local entry_value

  while IFS=$'\t' read -r entry_key entry_value; do
    if [[ -z "$entry_key" ]]; then
      continue
    fi
    if [[ "$entry_key" == "$cache_key" ]]; then
      continue
    fi
    new_cache+="${entry_key}"$'\t'"${entry_value}"$'\n'
  done <<<"${MEOW_THEME_CACHE}"

  new_cache+="${cache_key}"$'\t'"${value}"
  MEOW_THEME_CACHE="$new_cache"
}

theme_yaml_path() {
  local key="$1"
  if [[ "$key" == .* ]]; then
    echo "$key"
  else
    echo ".${key}"
  fi
}

theme_db_get() {
  local path="$1"
  local cache_key
  cache_key=$(theme_cache_key "$path")
  
  # Check cache first.
  local cached_value=""
  if cached_value=$(theme_cache_get "$cache_key"); then
    echo "$cached_value"
    return 0
  fi
  
  if [[ ! -f "$MEOW_THEME_DB" ]]; then
    echo ""
    return 1
  fi

  local yaml_path
  yaml_path=$(theme_yaml_path "$path")
  local value
  value=$(read_yaml_value "$MEOW_THEME_DB" "$yaml_path")
  
  # Cache the result.
  theme_cache_set "$cache_key" "$value"
  
  echo "$value"
}

theme_strip_quotes() {
  local value="$1"
  value=${value%\"}
  value=${value#\"}
  echo "$value"
}

theme_db_get_required() {
  local path="$1"
  local value
  value=$(theme_db_get "$path")
  if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
    return 1
  fi
  theme_strip_quotes "$value"
}

theme_get_mode() {
  local mode
  mode=$(meow_config_get "theme.mode" "auto")
  if [[ "$mode" == "auto" ]]; then
    echo "auto"
  else
    echo "manual"
  fi
}

theme_get_current_mode() {
  local mode
  mode=$(meow_config_get "theme.mode" "auto")
  if [[ "$mode" == "auto" ]]; then
    meow_config_get "theme.current" "dark"
  else
    meow_config_get "theme.current" "dark"
  fi
}

theme_get_theme_for_mode() {
  local mode="$1"
  local preset
  local variant

  preset=$(meow_config_get "theme.${mode}.preset" "catppuccin")
  variant=$(meow_config_get "theme.${mode}.variant" "mocha")
  echo "$preset|$variant"
}

theme_get_active_theme() {
  local current
  current=$(theme_get_current_mode)
  theme_get_theme_for_mode "$current"
}

theme_get_terminal_color() {
  local preset="$1"
  local variant="$2"
  local index="$3"
  theme_db_get_required "themes.${preset}.variants.${variant}.terminal.${index}"
}

theme_get_terminal_named_color() {
  local preset="$1"
  local variant="$2"
  local name="$3"
  theme_db_get_required "themes.${preset}.variants.${variant}.terminal.${name}"
}

theme_is_hex_color() {
  local value="$1"
  # Must be a single-line string starting with # followed by exactly 6 hex chars
  [[ "$value" =~ ^#[0-9a-fA-F]{6}$ ]]
}

theme_get_palette_color() {
  local preset="$1"
  local variant="$2"
  local key="$3"
  local value

  value=$(theme_db_get "themes.${preset}.variants.${variant}.palette.${key}")
  if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
    local stripped
    stripped=$(theme_strip_quotes "$value")
    # If value is a plain hex color, return it directly
    if theme_is_hex_color "$stripped"; then
      echo "$stripped"
      return 0
    fi
    # Value is a nested object — try the .base sub-key (used by nightfox, github, etc.)
    local sub_value
    sub_value=$(theme_db_get "themes.${preset}.variants.${variant}.palette.${key}.base")
    if [[ -n "$sub_value" ]] && [[ "$sub_value" != "null" ]]; then
      local sub_stripped
      sub_stripped=$(theme_strip_quotes "$sub_value")
      if theme_is_hex_color "$sub_stripped"; then
        echo "$sub_stripped"
        return 0
      fi
    fi
    # Nested object with no usable .base — fall through to catppuccin fallback chain
  fi

  local base
  base=$(theme_db_get "themes.${preset}.variants.${variant}.palette.base")
  if [[ -z "$base" ]] || [[ "$base" == "null" ]]; then
    return 1
  fi
  # base key itself might be a nested object (gruvbox uses base as a color group)
  if ! theme_is_hex_color "$(theme_strip_quotes "$base")"; then
    return 1
  fi

  local fallback=""
  case "$key" in
    bg) fallback="base" ;;
    bg1) fallback="surface1" ;;
    bg_dark|bg_statusline) fallback="mantle" ;;
    bg_highlight|bg_visual) fallback="surface2" ;;
    fg) fallback="text" ;;
    fg1) fallback="subtext1" ;;
    fg_sidebar) fallback="subtext0" ;;
    border|gray) fallback="surface2" ;;
    blue|blue0|blue1) fallback="blue" ;;
    green|leaf) fallback="green" ;;
    red|rose) fallback="red" ;;
    yellow|wood) fallback="yellow" ;;
    cyan|water) fallback="teal" ;;
    purple|blossom|accent) fallback="mauve" ;;
    orange|highlight) fallback="peach" ;;
    rosewater) fallback="rosewater" ;;
  esac

  if [[ -z "$fallback" ]]; then
    return 1
  fi

  value=$(theme_db_get "themes.${preset}.variants.${variant}.palette.${fallback}")
  if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
    return 1
  fi
  theme_strip_quotes "$value"
}
