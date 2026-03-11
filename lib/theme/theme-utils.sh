#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/theme/theme-utils.sh
# @brief: Shared theme utility functions
# @author: Andrew Vasilyev
# @license: MIT
#
# This library provides shared utility functions for theme management.
# It should be sourced, not executed directly.

# Debug mode support
if [[ "${MEOW_DEBUG:-false}" == "true" ]]; then
  set -x
fi

# Logging support
theme_log() {
  local message="$1"
  local log_file="${MEOW_THEME_LOG:-$HOME/.meow/theme.log}"
  
  if [[ "${MEOW_THEME_LOGGING:-false}" == "true" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $message" >> "$log_file"
  fi
}

# Slugify function - convert string to lowercase with underscores
theme_slugify() {
  local value="$1"
  echo "$value" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g; s/_\+/_/g; s/^_//; s/_$//'
}

# Ensure a file is not a symlink (replace with real content)
theme_ensure_real_file() {
  local file="$1"
  if [[ -L "$file" ]]; then
    local temp
    temp=$(mktemp)
    cp -L "$file" "$temp"
    rm "$file"
    mv "$temp" "$file"
  fi
}

# Atomic configuration update
theme_apply_config_atomic() {
  local target="$1"
  local source="$2"
  
  if [[ ! -f "$source" ]]; then
    echo "Error: Source file not found: $source" >&2
    return 1
  fi
  
  local temp
  temp=$(mktemp)
  cp "$source" "$temp"
  
  mkdir -p "$(dirname "$target")"
  mv "$temp" "$target"
  
  return 0
}

# List available presets from themes.yaml
theme_list_presets() {
  local theme_db="${MEOW:-$HOME/.meow}/themes.yaml"
  
  if [[ ! -f "$theme_db" ]]; then
    echo "Theme database not found: $theme_db" >&2
    return 1
  fi
  
  if command -v yq >/dev/null 2>&1; then
    yq eval '.themes | keys | .[]' "$theme_db" 2>/dev/null | sed '/^\s*$/d'
  else
    # Fallback: basic parsing
    awk '/^themes:/,/^[a-zA-Z]/ { if (/^  [a-zA-Z]/) { gsub(/:/, ""); gsub(/^  /, ""); print } }' "$theme_db" | sort -u
  fi
}

# List available variants for a preset
theme_list_variants() {
  local preset="$1"
  local theme_db="${MEOW:-$HOME/.meow}/themes.yaml"
  
  if [[ ! -f "$theme_db" ]]; then
    echo "Theme database not found: $theme_db" >&2
    return 1
  fi
  
  if command -v yq >/dev/null 2>&1; then
    yq eval ".themes.${preset}.variants | keys | .[]" "$theme_db" 2>/dev/null | sed '/^\s*$/d'
  else
    # Fallback: basic parsing
    awk "/^  ${preset}:/,/^  [a-zA-Z]/ { if (/^    [a-zA-Z]/ && !/variants:/) { gsub(/:/, \"\"); gsub(/^    /, \"\"); print } }" "$theme_db" | sort -u
  fi
}

# Validate preset and variant exist
theme_validate() {
  local preset="$1"
  local variant="$2"
  local theme_db="${MEOW:-$HOME/.meow}/themes.yaml"
  
  if [[ ! -f "$theme_db" ]]; then
    echo "Error: Theme database not found: $theme_db" >&2
    return 1
  fi
  
  # Source theme.sh for theme_db_get if not already loaded
  if ! command -v theme_db_get >/dev/null 2>&1; then
    source "${MEOW:-$HOME/.meow}/lib/theme/theme.sh"
  fi
  
  # Check if preset exists
  if ! theme_db_get "themes.${preset}" >/dev/null 2>&1; then
    echo "Error: Unknown preset '$preset'" >&2
    echo "" >&2
    echo "Available presets:" >&2
    theme_list_presets | sed 's/^/  - /' >&2
    return 1
  fi
  
  # Check if variant exists
  if ! theme_db_get "themes.${preset}.variants.${variant}" >/dev/null 2>&1; then
    echo "Error: Unknown variant '$variant' for preset '$preset'" >&2
    echo "" >&2
    echo "Available variants for $preset:" >&2
    theme_list_variants "$preset" | sed 's/^/  - /' >&2
    return 1
  fi
  
  return 0
}

# Convert hex color to RGB values
theme_hex_to_rgb() {
  local hex="$1"
  hex="${hex#\#}"
  
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  
  echo "$r $g $b"
}

# Print colored block for terminal preview
theme_print_color_block() {
  local hex="$1"
  local name="${2:-}"
  
  hex="${hex#\#}"
  
  if [[ ${#hex} -ne 6 ]]; then
    echo "Invalid hex color: $hex" >&2
    return 1
  fi
  
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  
  # Print colored block with name
  if [[ -n "$name" ]]; then
    printf "  %-15s #%s " "$name" "$hex"
  else
    printf "  #%s " "$hex"
  fi
  
  # Print 4-character colored block
  printf "\033[48;2;%d;%d;%dm    \033[0m\n" "$r" "$g" "$b"
}

# Discover all theme generators in installed components
theme_discover_generators() {
  local installed_dir="${MEOW}/.installed/components"
  
  if [[ ! -d "$installed_dir" ]]; then
    return 1
  fi
  
  find -L "$installed_dir" -type f -name "generate-theme-*" 2>/dev/null | sort
}

# Discover all theme appliers in installed components
theme_discover_appliers() {
  local installed_dir="${MEOW}/.installed/components"
  
  if [[ ! -d "$installed_dir" ]]; then
    return 1
  fi
  
  find -L "$installed_dir" -type f -name "apply-theme-*" 2>/dev/null | sort
}

# Extract tool name from script path
theme_get_tool_name() {
  local script_path="$1"
  basename "$script_path" | sed 's/^generate-theme-//; s/^apply-theme-//'
}

# Send reload signal to Ghostty terminal
theme_reload_ghostty() {
  if command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR2 ghostty >/dev/null 2>&1 || true
  fi
}

# Format success message
theme_format_success() {
  local tool_name="$1"
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground 212 "✓ $tool_name"
  else
    echo "✓ $tool_name"
  fi
}

# Format error message
theme_format_error() {
  local tool_name="$1"
  local error="${2:-}"
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground 196 "✗ $tool_name${error:+: $error}"
  else
    echo "✗ $tool_name${error:+: $error}" >&2
  fi
}

# Format info message
theme_format_info() {
  local message="$1"
  if command -v gum >/dev/null 2>&1; then
    gum style --foreground 69 "$message"
  else
    echo "$message"
  fi
}

# Show theme application summary
theme_show_summary() {
  local preset="$1"
  local variant="$2"
  local mode_label="$3"
  local applied="$4"
  local failed="${5:-0}"
  
  if command -v gum >/dev/null 2>&1; then
    echo ""
    gum style \
      --foreground 212 --border-foreground 212 --border double \
      --align center --width 50 --margin "1 2" --padding "1 2" \
      "Theme Applied!" \
      "" \
      "Preset: $preset" \
      "Variant: $variant" \
      "Mode: $mode_label" \
      "" \
      "Applied: $applied" \
      $([ $failed -gt 0 ] && echo "Failed: $failed" || echo "")
    
    echo ""
    echo "  To see changes:"
    echo "  • Ghostty: Updated immediately"
    echo "  • Shell tools (fzf/eza): Source your shell or run: source ~/.zshrc"
    echo "  • TUI apps (lazygit/htop): Restart the app"
  else
    echo ""
    echo "Theme applied: ${preset} / ${variant} (${mode_label})"
    echo "  Applied: $applied"
    [ $failed -gt 0 ] && echo "  Failed: $failed"
    echo ""
    echo "To see changes:"
    echo "  • Ghostty: Updated immediately"
    echo "  • Shell tools (fzf/eza): Source your shell or run: source ~/.zshrc"
    echo "  • TUI apps (lazygit/htop): Restart the app"
  fi
}
