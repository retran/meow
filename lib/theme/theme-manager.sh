#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/theme/theme-manager.sh
# @brief: Theme management library for meowctl
# @author: Andrew Vasilyev
# @license: MIT
#
# This library provides theme management functions for meowctl.
# It should be sourced, not executed directly.

# Initialize theme directories
theme_init() {
  MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
  MEOW_THEME_DIR="${MEOW:-$HOME/.meow}"
  MEOW_STARSHIP_CONFIG="$MEOW_CONFIG_DIR/starship.toml"
  
  mkdir -p "$MEOW_THEME_DIR"
  mkdir -p "$MEOW_CONFIG_DIR"
  
  # Config library should already be sourced by meowctl
  # but check just in case this is called standalone
  if ! command -v meow_config_get >/dev/null 2>&1; then
    CONFIG_LIB="${MEOW:-$HOME/.meow}/lib/config/config.sh"
    if [[ -f "$CONFIG_LIB" ]]; then
      source "$CONFIG_LIB"
    else
      echo "Error: Config library not found at $CONFIG_LIB" >&2
      return 1
    fi
  fi
}

ensure_theme_defaults() {
  local mode
  mode=$(meow_config_get "theme.mode" "auto")
  if [[ -z "$mode" ]]; then
    meow_config_set "theme.mode" "auto"
  fi
  if [[ -z "$(meow_config_get "theme.current" "")" ]]; then
    meow_config_set "theme.current" "dark"
  fi
  if [[ -z "$(meow_config_get "theme.light.preset" "")" ]]; then
    meow_config_set "theme.light.preset" "catppuccin"
  fi
  if [[ -z "$(meow_config_get "theme.light.variant" "")" ]]; then
    meow_config_set "theme.light.variant" "latte"
  fi
  if [[ -z "$(meow_config_get "theme.dark.preset" "")" ]]; then
    meow_config_set "theme.dark.preset" "catppuccin"
  fi
  if [[ -z "$(meow_config_get "theme.dark.variant" "")" ]]; then
    meow_config_set "theme.dark.variant" "mocha"
  fi
}

slugify() {
  local value="$1"
  value=$(echo "$value" | tr '[:upper:]' '[:lower:]')
  value=$(echo "$value" | sed 's/[^a-z0-9]/_/g; s/_\+/_/g; s/^_//; s/_$//')
  echo "$value"
}

detect_system_theme() {
  # Detect system appearance (light/dark) across different platforms
  local appearance=""
  
  # macOS detection
  if [[ "$OSTYPE" == "darwin"* ]]; then
    appearance=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
    if [[ "$appearance" == "Dark" ]]; then
      echo "dark"
      return
    else
      echo "light"
      return
    fi
  fi
  
  # Linux detection - try multiple methods
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # GNOME/GTK (most common)
    if command -v gsettings >/dev/null 2>&1; then
      appearance=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
      if [[ "$appearance" == *"dark"* ]]; then
        echo "dark"
        return
      elif [[ "$appearance" == *"light"* ]]; then
        echo "light"
        return
      fi
      
      # Fallback: check GTK theme name
      appearance=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
      if [[ "$appearance" == *"dark"* ]] || [[ "$appearance" == *"Dark"* ]]; then
        echo "dark"
        return
      fi
    fi
    
    # KDE Plasma
    if command -v kreadconfig5 >/dev/null 2>&1; then
      appearance=$(kreadconfig5 --group General --key ColorScheme 2>/dev/null)
      if [[ "$appearance" == *"Dark"* ]] || [[ "$appearance" == *"dark"* ]]; then
        echo "dark"
        return
      fi
    fi
    
    # Check environment variable (some DEs set this)
    if [[ -n "${GTK_THEME:-}" ]]; then
      if [[ "$GTK_THEME" == *"dark"* ]] || [[ "$GTK_THEME" == *"Dark"* ]]; then
        echo "dark"
        return
      fi
    fi
  fi
  
  # Default fallback
  echo "dark"
}

ensure_real_file() {
  local file="$1"
  if [[ -L "$file" ]]; then
    local temp
    temp=$(mktemp)
    cp -L "$file" "$temp"
    rm "$file"
    mv "$temp" "$file"
  fi
}

apply_ghostty() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/terminal-apps/config/ghostty/themes/${preset_slug}-${variant_slug}.conf"
  if [[ ! -f "$theme_file" ]]; then
    echo "Ghostty theme not found: $theme_file" >&2
    return 0
  fi

  local ghostty_config="${GHOSTTY_CONFIG_DIR:-$HOME/.config/ghostty}/config"
  if [[ ! -f "$ghostty_config" ]]; then
    return 0
  fi

  ensure_real_file "$ghostty_config"

  local temp_file
  temp_file=$(mktemp)
  awk '
      BEGIN { skip=0 }
      /^# theme: meow/ { skip=1; next }
      /^# endtheme: meow/ { skip=0; next }
      { if (!skip) print }
  ' "$ghostty_config" > "$temp_file"

  {
    echo "# theme: meow"
    cat "$theme_file"
    echo "# endtheme: meow"
  } >> "$temp_file"

  mv "$temp_file" "$ghostty_config"

  if command -v pkill >/dev/null 2>&1; then
    pkill -SIGUSR2 ghostty >/dev/null 2>&1 || true
  fi
}

apply_starship() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/starship/themes/${preset_slug}-${variant_slug}.toml"
  if [[ ! -f "$theme_file" ]]; then
    echo "Starship theme not found: $theme_file" >&2
    return 0
  fi

  cp "$theme_file" "$MEOW_STARSHIP_CONFIG"
}

apply_tmux() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/tmux/config/themes/${preset_slug}-${variant_slug}.conf"
  local active_file="$MEOW_CONFIG_DIR/tmux/theme.conf"
  mkdir -p "$(dirname "$active_file")"

  if [[ ! -f "$theme_file" ]]; then
    echo "tmux theme not found: $theme_file" >&2
    return 0
  fi

  cp "$theme_file" "$active_file"

  if command -v tmux >/dev/null 2>&1; then
    if [[ -n "${TMUX:-}" ]]; then
      tmux source-file ~/.tmux.conf 2>/dev/null || true
    elif tmux info &>/dev/null; then
      tmux source-file ~/.tmux.conf 2>/dev/null || true
    fi
  fi
}

apply_bat() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/bat/themes/${preset_slug}-${variant_slug}.conf"
  local bat_config="${XDG_CONFIG_HOME:-$HOME/.config}/bat/config"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "bat theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$bat_config")"
  cp "$theme_file" "$bat_config"
}

apply_lazygit() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/dev-tools/config/lazygit/themes/${preset_slug}-${variant_slug}.yml"
  local lazygit_config="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "lazygit theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$lazygit_config")"
  cp "$theme_file" "$lazygit_config"
}

apply_delta() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/delta/themes/${preset_slug}-${variant_slug}.conf"
  local gitconfig="$HOME/.gitconfig"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "delta theme not found: $theme_file" >&2
    return 0
  fi
  
  if [[ ! -f "$gitconfig" ]]; then
    return 0
  fi

  # Remove existing [delta] section and append new one
  local temp_file
  temp_file=$(mktemp)
  
  awk '
    BEGIN { in_delta=0 }
    /^\[delta\]/ { in_delta=1; next }
    in_delta && /^\[/ { in_delta=0 }
    !in_delta { print }
  ' "$gitconfig" > "$temp_file"
  
  cat "$theme_file" >> "$temp_file"
  mv "$temp_file" "$gitconfig"
}

apply_fzf() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/fzf/themes/${preset_slug}-${variant_slug}.sh"
  local fzf_config="$MEOW_CONFIG_DIR/fzf/colors.sh"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "fzf theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$fzf_config")"
  cp "$theme_file" "$fzf_config"
}

apply_glow() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/glow/themes/${preset_slug}-${variant_slug}.yml"
  local glow_config="${XDG_CONFIG_HOME:-$HOME/.config}/glow/glow.yml"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "glow theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$glow_config")"
  cp "$theme_file" "$glow_config"
}

apply_eza() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/eza/themes/${preset_slug}-${variant_slug}.sh"
  local eza_config="$MEOW_CONFIG_DIR/eza/colors.sh"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "eza theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$eza_config")"
  cp "$theme_file" "$eza_config"
}

apply_zsh() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/zsh/themes/${preset_slug}-${variant_slug}.sh"
  local zsh_config="$MEOW_CONFIG_DIR/zsh/colors.sh"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "zsh theme not found: $theme_file" >&2
    return 0
  fi

  mkdir -p "$(dirname "$zsh_config")"
  cp "$theme_file" "$zsh_config"
}

apply_ripgrep() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/ripgrep/themes/${preset_slug}-${variant_slug}.rc"
  local base_config="$MEOW_THEME_DIR/components/shell-essential/config/ripgrep/.ripgreprc"
  local rg_config="$HOME/.ripgreprc"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "ripgrep theme not found: $theme_file" >&2
    return 0
  fi

  if [[ ! -f "$base_config" ]]; then
    echo "ripgrep base config not found: $base_config" >&2
    return 0
  fi

  # Start with base config (without colors)
  local temp_file
  temp_file=$(mktemp)
  
  # Copy base config, removing any color settings
  grep -v "^--colors=" "$base_config" > "$temp_file" || true
  
  # Append theme colors
  cat "$theme_file" >> "$temp_file"
  mv "$temp_file" "$rg_config"
}

apply_tealdeer() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/tealdeer/themes/${preset_slug}-${variant_slug}.toml"
  local tealdeer_config="${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer/config.toml"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "tealdeer theme not found: $theme_file" >&2
    return 0
  fi

  # Read existing config if it exists and merge with theme
  local temp_file
  temp_file=$(mktemp)
  
  if [[ -f "$tealdeer_config" ]]; then
    # Remove existing [style.*] sections
    awk '
      BEGIN { skip=0 }
      /^\[style\./ { skip=1; next }
      skip && /^\[/ && !/^\[style\./ { skip=0 }
      !skip { print }
    ' "$tealdeer_config" > "$temp_file"
  fi
  
  # Append theme config
  cat "$theme_file" >> "$temp_file"
  mkdir -p "$(dirname "$tealdeer_config")"
  mv "$temp_file" "$tealdeer_config"
}

apply_htop() {
  local preset="$1"
  local variant="$2"

  local preset_slug
  local variant_slug
  preset_slug=$(slugify "$preset")
  variant_slug=$(slugify "$variant")

  local theme_file="$MEOW_THEME_DIR/components/shell-essential/config/htop/themes/${preset_slug}-${variant_slug}.theme"
  local htop_config="${XDG_CONFIG_HOME:-$HOME/.config}/htop/htoprc"
  
  if [[ ! -f "$theme_file" ]]; then
    echo "htop theme not found: $theme_file" >&2
    return 0
  fi

  # Read existing htoprc if it exists
  local temp_file
  temp_file=$(mktemp)
  
  if [[ -f "$htop_config" ]]; then
    # Remove existing color_scheme line
    grep -v "^color_scheme=" "$htop_config" > "$temp_file" || true
  fi
  
  # Append theme color scheme
  cat "$theme_file" >> "$temp_file"
  mkdir -p "$(dirname "$htop_config")"
  mv "$temp_file" "$htop_config"
}

theme_discover_appliers() {
  # Discover all apply-theme-* scripts in installed components
  local installed_dir="${MEOW}/.installed/components"
  
  if [[ ! -d "$installed_dir" ]]; then
    echo "No installed components found" >&2
    return 1
  fi
  
  find -L "$installed_dir" -type f -name "apply-theme-*" 2>/dev/null | sort
}

apply_theme() {
  local preset="$1"
  local variant="$2"
  local mode_label="$3"

  echo "Discovering theme appliers..."
  local appliers
  appliers=$(theme_discover_appliers)
  
  if [[ -z "$appliers" ]]; then
    echo "No theme appliers found in installed components."
    return 0
  fi
  
  local applier_count
  applier_count=$(echo "$appliers" | wc -l | tr -d ' ')
  echo "Found $applier_count theme applier(s)"
  echo ""
  
  # Set up environment for appliers
  export MEOW
  export MEOW_CONFIG_DIR
  export MEOW_THEME_DIR
  
  local total_applied=0
  local total_failed=0
  
  # Call each applier
  while IFS= read -r applier; do
    [[ -z "$applier" ]] && continue
    
    local tool_name
    tool_name=$(basename "$applier" | sed 's/apply-theme-//')
    
    printf "  %-15s ... " "$tool_name"
    
    if [[ ! -x "$applier" ]]; then
      echo "SKIP (not executable)"
      continue
    fi
    
    # Run applier
    if "$applier" "$preset" "$variant" 2>/dev/null; then
      echo "OK"
      ((total_applied++))
    else
      echo "FAILED"
      ((total_failed++))
    fi
  done <<< "$appliers"
  
  echo ""
  echo "Theme application summary:"
  echo "  Applied: $total_applied"
  if [[ $total_failed -gt 0 ]]; then
    echo "  Failed: $total_failed"
  fi
  
  # Note: Environment variables are sourced by meowctl or meow-theme wrapper functions
  # Sourcing here only affects this subshell, not the parent shell

  if command -v gum >/dev/null 2>&1; then
    gum style \
      --foreground 212 --border-foreground 212 --border double \
      --align center --width 50 --margin "1 2" --padding "1 2" \
      "Theme Applied!" \
      "" \
      "Preset: $preset" \
      "Variant: $variant" \
      "Mode: $mode_label"
    
    echo ""
    echo "  To see changes:"
    echo "  • Ghostty: Updated immediately"
    echo "  • tmux: Reloaded automatically"
    echo "  • Shell tools (fzf/eza): Updated in current shell"
    echo "  • TUI apps (lazygit/htop): Restart app"
  else
    echo ""
    echo "Theme applied: ${preset} (${variant}, ${mode_label})"
    echo ""
    echo "To see changes:"
    echo "  • Ghostty: Updated immediately"
    echo "  • tmux: Reloaded automatically"
    echo "  • Shell tools (fzf/eza): Updated in current shell"
    echo "  • TUI apps (lazygit/htop): Restart app"
  fi
}

toggle_mode() {
  local current
  current=$(meow_config_get "theme.current" "dark")

  local new_mode
  if [[ "$current" == "light" ]]; then
    new_mode="dark"
  else
    new_mode="light"
  fi

  meow_config_set "theme.mode" "manual"
  meow_config_set "theme.current" "$new_mode"

  local preset
  local variant
  preset=$(meow_config_get "theme.${new_mode}.preset" "catppuccin")
  variant=$(meow_config_get "theme.${new_mode}.variant" "mocha")
  apply_theme "$preset" "$variant" "$new_mode"
}

apply_preset() {
  local preset="$1"
  local variant="$2"
  local mode="${3:-}"

  if [[ -z "$mode" ]]; then
    mode=$(meow_config_get "theme.current" "dark")
  fi

  if [[ "$mode" != "light" && "$mode" != "dark" ]]; then
    echo "Invalid mode: $mode (use light or dark)" >&2
    exit 1
  fi

  meow_config_set "theme.mode" "manual"
  meow_config_set "theme.${mode}.preset" "$preset"
  meow_config_set "theme.${mode}.variant" "$variant"
  meow_config_set "theme.current" "$mode"

  apply_theme "$preset" "$variant" "$mode"
}

apply_current() {
  local mode
  mode=$(meow_config_get "theme.mode" "auto")
  
  local current
  if [[ "$mode" == "auto" ]]; then
    # Auto mode: detect system theme
    current=$(detect_system_theme)
    meow_config_set "theme.current" "$current"
  else
    # Manual mode: use saved preference
    current=$(meow_config_get "theme.current" "dark")
  fi
  
  local preset
  local variant
  preset=$(meow_config_get "theme.${current}.preset" "catppuccin")
  variant=$(meow_config_get "theme.${current}.variant" "mocha")
  apply_theme "$preset" "$variant" "$current"
}

show_status() {
  local mode
  local current
  local detected
  local preset
  local variant
  
  mode=$(meow_config_get "theme.mode" "auto")
  current=$(meow_config_get "theme.current" "dark")
  detected=$(detect_system_theme)
  preset=$(meow_config_get "theme.${current}.preset" "catppuccin")
  variant=$(meow_config_get "theme.${current}.variant" "mocha")
  
  echo "Theme Status:"
  echo "  Mode: $mode"
  echo "  Current: $current ($preset/$variant)"
  echo "  System: $detected"
  
  if [[ "$mode" == "auto" ]]; then
    echo ""
    echo "Auto mode is enabled. Theme will automatically"
    echo "switch when system appearance changes."
  else
    echo ""
    echo "Manual mode is enabled. Use 'meow-theme toggle'"
    echo "to switch or 'meow-theme auto' to enable auto mode."
  fi
}

enable_auto_mode() {
  meow_config_set "theme.mode" "auto"
  echo "Auto mode enabled. Theme will follow system appearance."
  echo "Applying current system theme..."
  apply_current
}

enable_manual_mode() {
  meow_config_set "theme.mode" "manual"
  local current
  current=$(meow_config_get "theme.current" "dark")
  echo "Manual mode enabled. Current theme locked to: $current"
}

# Theme Build Functions
# =====================

theme_build_discover_generators() {
  # Discover all generate-theme-* scripts in installed components
  local installed_dir="${MEOW}/.installed/components"
  
  if [[ ! -d "$installed_dir" ]]; then
    echo "No installed components found" >&2
    return 1
  fi
  
  find -L "$installed_dir" -type f -name "generate-theme-*" 2>/dev/null | sort
}

theme_build_get_theme_list() {
  # Get list of all themes from themes.yaml
  local theme_db="${MEOW}/themes.yaml"
  
  if [[ ! -f "$theme_db" ]]; then
    echo "Theme database not found: $theme_db" >&2
    return 1
  fi
  
  # Use yq if available, otherwise use basic parsing
  if command -v yq >/dev/null 2>&1; then
    yq eval '.themes | keys | .[]' "$theme_db" 2>/dev/null | sed '/^\s*$/d'
  else
    # Fallback: basic grep parsing (less reliable)
    grep -A 1 "^themes:" "$theme_db" | grep -v "^themes:" | grep -E "^\s+[a-zA-Z]" | sed 's/://g' | sed 's/^\s*//' | sort -u
  fi
}

theme_build_get_variant_list() {
  local preset="$1"
  local theme_db="${MEOW}/themes.yaml"
  
  if [[ ! -f "$theme_db" ]]; then
    echo "Theme database not found: $theme_db" >&2
    return 1
  fi
  
  # Use yq if available
  if command -v yq >/dev/null 2>&1; then
    yq eval ".themes.${preset}.variants | keys | .[]" "$theme_db" 2>/dev/null | sed '/^\s*$/d'
  else
    # Fallback: basic parsing
    awk "/^  ${preset}:/,/^  [a-zA-Z]/ { if (/variants:/) flag=1; if (flag && /^\s+[a-zA-Z]/) print }" "$theme_db" | sed 's/://g' | sed 's/^\s*//' | grep -v "variants" | sort -u
  fi
}

theme_build_all() {
  # Build themes for all installed components
  # Usage: theme_build_all [--preset PRESET] [--variant VARIANT]
  
  local requested_preset=""
  local requested_variant=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --preset)
        requested_preset="$2"
        shift 2
        ;;
      --variant)
        requested_variant="$2"
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Usage: meowctl theme build [--preset PRESET] [--variant VARIANT]" >&2
        return 1
        ;;
    esac
  done
  
  echo "Discovering theme generators..."
  local generators
  generators=$(theme_build_discover_generators)
  
  if [[ -z "$generators" ]]; then
    echo "No theme generators found in installed components."
    return 0
  fi
  
  local generator_count
  generator_count=$(echo "$generators" | wc -l | tr -d ' ')
  echo "Found $generator_count theme generator(s)"
  
  # Set up environment for generators
  export MEOW
  export THEME_DB="${MEOW}/themes.yaml"
  export THEME_LIB="${MEOW}/lib/theme/theme.sh"
  
  if [[ ! -f "$THEME_DB" ]]; then
    echo "Error: Theme database not found at $THEME_DB" >&2
    return 1
  fi
  
  if [[ ! -f "$THEME_LIB" ]]; then
    echo "Warning: Theme library not found at $THEME_LIB (some generators may fail)" >&2
  fi
  
  # Get list of themes to generate
  local presets
  if [[ -n "$requested_preset" ]]; then
    presets="$requested_preset"
  else
    echo "Reading theme list from themes.yaml..."
    presets=$(theme_build_get_theme_list) || return 1
  fi
  
  local total_generated=0
  local total_failed=0
  
  # For each preset
  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue
    
    # Get variants for this preset
    local variants
    if [[ -n "$requested_variant" ]]; then
      variants="$requested_variant"
    else
      variants=$(theme_build_get_variant_list "$preset") || continue
    fi
    
    # For each variant
    while IFS= read -r variant; do
      [[ -z "$variant" ]] && continue
      
      echo ""
      echo "Building theme: $preset / $variant"
      echo "----------------------------------------"
      
      # Call each generator
      while IFS= read -r generator; do
        [[ -z "$generator" ]] && continue
        
        local tool_name
        tool_name=$(basename "$generator" | sed 's/generate-theme-//')
        
        printf "  %-15s ... " "$tool_name"
        
        if [[ ! -x "$generator" ]]; then
          echo "SKIP (not executable)"
          continue
        fi
        
        # Run generator
        if "$generator" "$preset" "$variant" >/dev/null 2>&1; then
          echo "OK"
          ((total_generated++))
        else
          echo "FAILED"
          ((total_failed++))
        fi
      done <<< "$generators"
      
    done <<< "$variants"
  done <<< "$presets"
  
  echo ""
  echo "========================================="
  echo "Theme generation complete"
  echo "  Generated: $total_generated"
  if [[ $total_failed -gt 0 ]]; then
    echo "  Failed: $total_failed"
    return 1
  fi
  
  return 0
}

# Note: This is a library file meant to be sourced by meowctl.
# The main() function and command dispatch logic is in meowctl itself.

