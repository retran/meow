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

theme_tmux_file_path() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
  echo "$config_dir/tmux/theme.conf"
}

theme_write_tmux_file() {
  local preset="$1"
  local variant="$2"

  local theme_file
  theme_file=$(theme_tmux_file_path)
  mkdir -p "$(dirname "$theme_file")"

  local bg
  local fg
  local accent
  local border
  local alert
  local ok
  local status_bg
  local status_fg
  local message_bg
  bg=$(theme_get_palette_color "$preset" "$variant" "bg" || theme_get_palette_color "$preset" "$variant" "bg1" || true)
  fg=$(theme_get_palette_color "$preset" "$variant" "fg" || theme_get_palette_color "$preset" "$variant" "fg1" || true)
  accent=$(theme_get_palette_color "$preset" "$variant" "blue" || theme_get_palette_color "$preset" "$variant" "blue1" || theme_get_palette_color "$preset" "$variant" "blue0" || theme_get_palette_color "$preset" "$variant" "water" || theme_get_terminal_color "$preset" "$variant" "4" || theme_get_terminal_named_color "$preset" "$variant" "blue" || true)
  border=$(theme_get_palette_color "$preset" "$variant" "border" || theme_get_palette_color "$preset" "$variant" "gray" || theme_get_palette_color "$preset" "$variant" "fg1" || true)
  alert=$(theme_get_palette_color "$preset" "$variant" "red" || theme_get_palette_color "$preset" "$variant" "rose" || theme_get_terminal_color "$preset" "$variant" "1" || theme_get_terminal_named_color "$preset" "$variant" "red" || true)
  ok=$(theme_get_palette_color "$preset" "$variant" "green" || theme_get_palette_color "$preset" "$variant" "leaf" || theme_get_terminal_color "$preset" "$variant" "2" || theme_get_terminal_named_color "$preset" "$variant" "green" || true)
  status_bg=$(theme_get_palette_color "$preset" "$variant" "bg_statusline" || theme_get_palette_color "$preset" "$variant" "bg_dark" || theme_get_palette_color "$preset" "$variant" "bg" || true)
  status_fg=$(theme_get_palette_color "$preset" "$variant" "fg" || theme_get_palette_color "$preset" "$variant" "fg_sidebar" || theme_get_palette_color "$preset" "$variant" "fg1" || true)
  message_bg=$(theme_get_palette_color "$preset" "$variant" "bg_highlight" || theme_get_palette_color "$preset" "$variant" "bg_visual" || true)

  if [[ -z "$accent" ]]; then
    accent="$fg"
  fi
  if [[ -z "$border" ]]; then
    border="$fg"
  fi
  if [[ -z "$alert" ]]; then
    alert="$fg"
  fi
  if [[ -z "$ok" ]]; then
    ok="$fg"
  fi
  if [[ -z "$status_bg" ]]; then
    status_bg="$bg"
  fi
  if [[ -z "$status_fg" ]]; then
    status_fg="$fg"
  fi
  if [[ -z "$message_bg" ]]; then
    message_bg="$accent"
  fi

  if [[ -z "$bg" ]] || [[ -z "$fg" ]]; then
    return 1
  fi

  cat >"$theme_file" <<EOF
set -g status-style "bg=${status_bg},fg=${status_fg}"
set -g status-left-style NONE
set -g status-right-style NONE
set -g message-style "bg=${message_bg},fg=${status_fg}"
set -g message-command-style "bg=${status_bg},fg=${status_fg}"
set -g pane-border-style "fg=${border}"
set -g pane-active-border-style "fg=${accent}"
set -g window-status-activity-style "fg=${status_fg},bg=${status_bg}"
set -g window-status-style "fg=${status_fg},bg=${status_bg}"
set -g window-status-current-format "#[fg=${status_bg},bg=${accent},bold] #I #[fg=${status_fg},bg=${status_bg}] #W #F "
set -g window-status-format "#[fg=${status_fg},bg=${status_bg}] #I #[fg=${status_fg},bg=${status_bg}] #W #F "
set -g status-left "#[fg=${status_bg},bg=${accent},bold] #S #[fg=${accent},bg=${status_bg}]"
set -g status-right "#[fg=${ok},bg=${status_bg}] %Y-%m-%d #[fg=${accent},bg=${status_bg}]  #[fg=${status_bg},bg=${accent},bold] %H:%M "
set -g mode-style "fg=${ok},bg=${status_bg}"
set -g window-status-bell-style "fg=${alert},bg=${status_bg},bold"
EOF
}
