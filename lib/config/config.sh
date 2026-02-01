#!/usr/bin/env bash
# MIT License
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# @file: lib/config/config.sh
# @brief: Unified configuration system for .meow environment
# @author: Andrew Vasilyev
# @license: MIT

# Configuration system for .meow
# Provides a simple key-value config store with namespaces
# Config location: ~/.config/meow/config.conf

set -euo pipefail

# Config file location (XDG compliant)
MEOW_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/meow"
MEOW_CONFIG_FILE="$MEOW_CONFIG_DIR/config.conf"

# Ensure config directory exists
mkdir -p "$MEOW_CONFIG_DIR"

# Initialize default config if it doesn't exist
_meow_config_init() {
    if [[ -f "$MEOW_CONFIG_FILE" ]]; then
        return 0
    fi
    
    cat > "$MEOW_CONFIG_FILE" <<'EOF'
# Meow Configuration File
# Format: NAMESPACE.KEY=VALUE
# Lines starting with # are comments
# Empty lines are ignored
#
# Note: Neovim has its own config at ~/.config/meowvim/config.lua

# Theme settings (shared across terminal apps)
theme.preset=catppuccin
theme.mode=night
theme.auto_sync=true

# Terminal settings (Ghostty)
terminal.font_size=14
terminal.font_family=JetBrainsMono Nerd Font Mono
terminal.opacity=1.0

# Shell settings (Starship prompt)
shell.starship_palette=default
shell.show_battery=false
shell.show_memory=false

# System settings
system.check_updates=true
EOF
    
    echo "Created default config at $MEOW_CONFIG_FILE" >&2
}

# Get a config value
# Usage: meow_config_get NAMESPACE.KEY [default]
meow_config_get() {
    local key="$1"
    local default="${2:-}"
    
    _meow_config_init
    
    if [[ ! -f "$MEOW_CONFIG_FILE" ]]; then
        echo "$default"
        return 1
    fi
    
    # Read value from config file
    local value
    value=$(grep -E "^${key}=" "$MEOW_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | tail -n1 || echo "$default")
    
    echo "$value"
}

# Set a config value
# Usage: meow_config_set NAMESPACE.KEY VALUE
meow_config_set() {
    local key="$1"
    local value="$2"
    
    _meow_config_init
    
    # Check if key exists
    if grep -qE "^${key}=" "$MEOW_CONFIG_FILE" 2>/dev/null; then
        # Update existing value (macOS compatible)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$MEOW_CONFIG_FILE"
        else
            sed -i "s|^${key}=.*|${key}=${value}|" "$MEOW_CONFIG_FILE"
        fi
    else
        # Append new value
        echo "${key}=${value}" >> "$MEOW_CONFIG_FILE"
    fi
}

# Delete a config value
# Usage: meow_config_delete NAMESPACE.KEY
meow_config_delete() {
    local key="$1"
    
    if [[ ! -f "$MEOW_CONFIG_FILE" ]]; then
        return 0
    fi
    
    # Delete key (macOS compatible)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/^${key}=/d" "$MEOW_CONFIG_FILE"
    else
        sed -i "/^${key}=/d" "$MEOW_CONFIG_FILE"
    fi
}

# List all config values in a namespace
# Usage: meow_config_list [NAMESPACE]
meow_config_list() {
    local namespace="${1:-}"
    
    _meow_config_init
    
    if [[ -z "$namespace" ]]; then
        # List all
        grep -E "^[a-z_]+\.[a-z_]+=.*" "$MEOW_CONFIG_FILE" 2>/dev/null || true
    else
        # List namespace
        grep -E "^${namespace}\.[a-z_]+=.*" "$MEOW_CONFIG_FILE" 2>/dev/null || true
    fi
}

# Get all values in a namespace as shell variables
# Usage: eval "$(meow_config_namespace theme)"
# Result: sets THEME_PRESET, THEME_MODE, etc.
meow_config_namespace() {
    local namespace="$1"
    
    _meow_config_init
    
    local output=""
    while IFS='=' read -r key value; do
        # Remove namespace prefix and convert to uppercase
        local var_name
        var_name=$(echo "${key#${namespace}.}" | tr '[:lower:]' '[:upper:]' | tr '.' '_')
        output+="${var_name}='${value}'\n"
    done < <(meow_config_list "$namespace")
    
    echo -e "$output"
}

# Interactive config editor (using gum if available)
meow_config_edit() {
    if command -v gum >/dev/null 2>&1; then
        # Use gum for interactive editing
        local namespaces=("theme" "terminal" "shell" "system")
        local namespace
        namespace=$(printf '%s\n' "${namespaces[@]}" | gum filter --placeholder "Select namespace...")
        
        if [[ -n "$namespace" ]]; then
            echo "Config values for $namespace:"
            meow_config_list "$namespace"
            echo ""
            
            local action
            action=$(gum choose "Add/Update value" "Delete value" "Cancel")
            
            case "$action" in
                "Add/Update value")
                    local key
                    key=$(gum input --placeholder "Key (without namespace prefix)")
                    if [[ -n "$key" ]]; then
                        local value
                        value=$(gum input --placeholder "Value" --value "$(meow_config_get "${namespace}.${key}")")
                        if [[ -n "$value" ]]; then
                            meow_config_set "${namespace}.${key}" "$value"
                            echo "Set ${namespace}.${key} = $value"
                        fi
                    fi
                    ;;
                "Delete value")
                    local key
                    key=$(gum input --placeholder "Key (without namespace prefix)")
                    if [[ -n "$key" ]]; then
                        meow_config_delete "${namespace}.${key}"
                        echo "Deleted ${namespace}.${key}"
                    fi
                    ;;
            esac
        fi
    else
        # Fallback to direct file editing
        "${EDITOR:-vim}" "$MEOW_CONFIG_FILE"
    fi
}

# Show current config
meow_config_show() {
    _meow_config_init
    
    if command -v gum >/dev/null 2>&1; then
        gum style \
            --border double --border-foreground 212 \
            --margin "1 2" --padding "1 2" \
            "Meow Configuration" \
            "" \
            "Location: $MEOW_CONFIG_FILE"
        echo ""
    else
        echo "=== Meow Configuration ==="
        echo "Location: $MEOW_CONFIG_FILE"
        echo ""
    fi
    
    # Show config grouped by namespace
    for namespace in theme terminal shell system; do
        echo "[$namespace]"
        meow_config_list "$namespace" | sed 's/^[^.]*\./  /' || echo "  (no values)"
        echo ""
    done
    
    echo "Note: Neovim has separate config at ~/.config/meowvim/config.lua"
}

# CLI interface when run directly
if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
    case "${1:-}" in
        get)
            shift
            meow_config_get "$@"
            ;;
        set)
            shift
            meow_config_set "$@"
            ;;
        delete)
            shift
            meow_config_delete "$@"
            ;;
        list)
            shift
            meow_config_list "$@"
            ;;
        namespace)
            shift
            meow_config_namespace "$@"
            ;;
        edit)
            meow_config_edit
            ;;
        show)
            meow_config_show
            ;;
        *)
            cat <<EOF
Usage: config.sh <command> [args]

Commands:
  get KEY [DEFAULT]       Get config value
  set KEY VALUE           Set config value
  delete KEY              Delete config value
  list [NAMESPACE]        List config values
  namespace NAMESPACE     Export namespace as shell variables
  edit                    Interactive config editor
  show                    Show all configuration

Examples:
  config.sh get theme.preset catppuccin
  config.sh set theme.mode night
  config.sh list theme
  eval "\$(config.sh namespace theme)"
EOF
            exit 1
            ;;
    esac
fi
