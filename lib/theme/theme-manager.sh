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

# Source required libraries
MEOW="${MEOW:-$HOME/.meow}"
source "$MEOW/lib/theme/theme.sh"
source "$MEOW/lib/theme/theme-utils.sh"

# Initialize theme directories
theme_init() {
  export MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
  export MEOW_THEME_DIR="${MEOW:-$HOME/.meow}"
  export MEOW_STARSHIP_CONFIG="$MEOW_CONFIG_DIR/starship.toml"
  
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

# Ensure theme defaults are set in config
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

# Detect system appearance (light/dark) across different platforms
detect_system_theme() {
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

# Apply theme using discovery-based approach with parallel execution
apply_theme() {
  local preset="$1"
  local variant="$2"
  local mode_label="$3"
  local parallel="${4:-true}"
  
  # Validate theme
  theme_validate "$preset" "$variant" || return 1
  
  theme_log "Applying theme: $preset/$variant ($mode_label)"
  
  echo "Discovering theme appliers..." >&2
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
  local pids=()
  
  # Apply themes (parallel or sequential based on parameter)
  if [[ "$parallel" == "true" ]]; then
    # Parallel execution
    while IFS= read -r applier; do
      [[ -z "$applier" ]] && continue
      
      (
        local tool_name
        tool_name=$(theme_get_tool_name "$applier")
        
        if [[ ! -x "$applier" ]]; then
          theme_format_info "  ⊘ $tool_name (not executable)"
          exit 2
        fi
        
        # Run applier
        if output=$("$applier" "$preset" "$variant" 2>&1); then
          theme_format_success "  $tool_name"
          exit 0
        else
          theme_format_error "  $tool_name"
          exit 1
        fi
      ) &
      pids+=($!)
    done <<< "$appliers"
    
    # Wait for all to complete and count results
    for pid in "${pids[@]}"; do
      if wait "$pid"; then
        ((total_applied++))
      else
        local exit_code=$?
        if [[ $exit_code -ne 2 ]]; then
          ((total_failed++))
        fi
      fi
    done
  else
    # Sequential execution
    while IFS= read -r applier; do
      [[ -z "$applier" ]] && continue
      
      local tool_name
      tool_name=$(theme_get_tool_name "$applier")
      
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
  fi
  
  # Show summary
  theme_show_summary "$preset" "$variant" "$mode_label" "$total_applied" "$total_failed"
  
  theme_log "Theme applied: $preset/$variant - Success: $total_applied, Failed: $total_failed"
  
  return $([ $total_failed -gt 0 ] && echo 1 || echo 0)
}

# Toggle between light and dark mode
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

# Apply a specific preset/variant
apply_preset() {
  local preset="$1"
  local variant="$2"
  local mode="${3:-}"

  if [[ -z "$mode" ]]; then
    mode=$(meow_config_get "theme.current" "dark")
  fi

  if [[ "$mode" != "light" && "$mode" != "dark" ]]; then
    echo "Invalid mode: $mode (use light or dark)" >&2
    return 1
  fi

  meow_config_set "theme.mode" "manual"
  meow_config_set "theme.${mode}.preset" "$preset"
  meow_config_set "theme.${mode}.variant" "$variant"
  meow_config_set "theme.current" "$mode"

  apply_theme "$preset" "$variant" "$mode"
}

# Apply current theme based on mode settings
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

# Show current theme status
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

# Enable auto mode
enable_auto_mode() {
  meow_config_set "theme.mode" "auto"
  echo "Auto mode enabled. Theme will follow system appearance."
  echo "Applying current system theme..."
  apply_current
}

# Enable manual mode
enable_manual_mode() {
  meow_config_set "theme.mode" "manual"
  local current
  current=$(meow_config_get "theme.current" "dark")
  echo "Manual mode enabled. Current theme locked to: $current"
}

# Preview a theme without applying it
preview_theme() {
  local preset="$1"
  local variant="$2"
  
  # Validate theme exists
  theme_validate "$preset" "$variant" || return 1
  
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  Theme Preview: $preset / $variant"
  echo "═══════════════════════════════════════════════"
  echo ""
  
  # Show color palette
  echo "Color Palette:"
  echo "─────────────────────────────────────────────"
  
  local colors=(base surface0 surface1 surface2 overlay0 overlay1 overlay2 text subtext1 subtext0 red green yellow blue purple cyan orange pink maroon peach sky teal mauve lavender rosewater)
  
  for color in "${colors[@]}"; do
    local hex
    hex=$(theme_get_palette_color "$preset" "$variant" "$color" 2>/dev/null || echo "")
    if [[ -n "$hex" && "$hex" != "null" ]]; then
      theme_print_color_block "$hex" "$color"
    fi
  done
  
  echo ""
  echo "─────────────────────────────────────────────"
  echo "To apply this theme:"
  echo "  meow-theme preset $preset $variant"
  echo "═══════════════════════════════════════════════"
  echo ""
}

# List all available themes
list_themes() {
  echo "Available themes:"
  echo ""
  
  local presets
  presets=$(theme_list_presets)
  
  while IFS= read -r preset; do
    [[ -z "$preset" ]] && continue
    
    echo "  $preset"
    local variants
    variants=$(theme_list_variants "$preset")
    
    while IFS= read -r variant; do
      [[ -z "$variant" ]] && continue
      echo "    - $variant"
    done <<< "$variants"
  done <<< "$presets"
}

# Theme Build Functions
# =====================

# Build themes for all installed components
theme_build_all() {
  # Usage: theme_build_all [--preset PRESET] [--variant VARIANT] [--parallel]
  
  local requested_preset=""
  local requested_variant=""
  local parallel="false"
  
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
      --parallel)
        parallel="true"
        shift
        ;;
      *)
        echo "Unknown option: $1" >&2
        echo "Usage: meowctl theme build [--preset PRESET] [--variant VARIANT] [--parallel]" >&2
        return 1
        ;;
    esac
  done
  
  echo "Discovering theme generators..."
  local generators
  generators=$(theme_discover_generators)
  
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
    presets=$(theme_list_presets) || return 1
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
      variants=$(theme_list_variants "$preset") || continue
    fi
    
    # For each variant
    while IFS= read -r variant; do
      [[ -z "$variant" ]] && continue
      
      echo ""
      echo "Building theme: $preset / $variant"
      echo "----------------------------------------"
      
      if [[ "$parallel" == "true" ]]; then
        # Parallel generation
        local pids=()
        while IFS= read -r generator; do
          [[ -z "$generator" ]] && continue
          
          (
            local tool_name
            tool_name=$(theme_get_tool_name "$generator")
            
            if [[ ! -x "$generator" ]]; then
              exit 2
            fi
            
            if "$generator" "$preset" "$variant" >/dev/null 2>&1; then
              theme_format_success "  $tool_name"
              exit 0
            else
              theme_format_error "  $tool_name"
              exit 1
            fi
          ) &
          pids+=($!)
        done <<< "$generators"
        
        # Wait for all
        for pid in "${pids[@]}"; do
          if wait "$pid"; then
            ((total_generated++))
          else
            local exit_code=$?
            if [[ $exit_code -ne 2 ]]; then
              ((total_failed++))
            fi
          fi
        done
      else
        # Sequential generation
        while IFS= read -r generator; do
          [[ -z "$generator" ]] && continue
          
          local tool_name
          tool_name=$(theme_get_tool_name "$generator")
          
          printf "  %-15s ... " "$tool_name"
          
          if [[ ! -x "$generator" ]]; then
            echo "SKIP (not executable)"
            continue
          fi
          
          if "$generator" "$preset" "$variant" >/dev/null 2>&1; then
            echo "OK"
            ((total_generated++))
          else
            echo "FAILED"
            ((total_failed++))
          fi
        done <<< "$generators"
      fi
      
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

# Note: This is a library file meant to be sourced by meowctl or meow-theme.
