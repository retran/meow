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

# Theme database cache
declare -A MEOW_THEME_CACHE

# Clear theme cache
theme_cache_clear() {
  MEOW_THEME_CACHE=()
}

# Get cache key
theme_cache_key() {
  echo "${MEOW_THEME_DB}:$1"
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
  
  # Check cache first
  if [[ -n "${MEOW_THEME_CACHE[$cache_key]:-}" ]]; then
    echo "${MEOW_THEME_CACHE[$cache_key]}"
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
  
  # Cache the result
  MEOW_THEME_CACHE[$cache_key]="$value"
  
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

theme_get_palette_color() {
  local preset="$1"
  local variant="$2"
  local key="$3"
  local value

  value=$(theme_db_get "themes.${preset}.variants.${variant}.palette.${key}")
  if [[ -n "$value" ]] && [[ "$value" != "null" ]]; then
    theme_strip_quotes "$value"
    return 0
  fi

  local base
  base=$(theme_db_get "themes.${preset}.variants.${variant}.palette.base")
  if [[ -z "$base" ]] || [[ "$base" == "null" ]]; then
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
