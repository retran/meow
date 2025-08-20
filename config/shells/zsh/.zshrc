#!/usr/bin/env zsh

# config/shells/zsh configuration file for Meow

# Function to check if plugin is available (component installed)
_is_plugin_available() {
  local plugin="$1"
  local plugin_file="${MEOW}/plugins/${plugin}/plugin.yaml"

  [[ -f "$plugin_file" ]] || return 1

  local available_when
  available_when=$(yq eval '.available_when' "$plugin_file" 2>/dev/null)

  # If no available_when specified, plugin is always available
  if [[ -z "$available_when" || "$available_when" == "null" ]]; then
    return 0
  fi

  # Check if required component is installed
  local component_symlink="${MEOW}/.installed/components/${available_when}"
  [[ -L "$component_symlink" ]]
}

# Source component interactive shell scripts
if [[ -d "${MEOW}/.installed/components" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for component_link in "${MEOW}/.installed/components"/*; do
    [[ -L "$component_link" ]] || continue
    component_name=$(basename "$component_link")
    init_script="${MEOW}/components/${component_name}/init.sh"
    if [[ -f "$init_script" ]]; then
      # shellcheck source=/dev/null
      source "$init_script"
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Source preset interactive shell scripts
if [[ -d "${MEOW}/.installed/presets" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for preset_link in "${MEOW}/.installed/presets"/*; do
    [[ -L "$preset_link" ]] || continue
    preset_name=$(basename "$preset_link")
    init_script="${MEOW}/presets/${preset_name}/init.sh"
    if [[ -f "$init_script" ]]; then
      # shellcheck source=/dev/null
      source "$init_script"
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Source plugin interactive shell scripts
if [[ -d "${MEOW}/.installed/plugins" ]]; then
  # Use nullglob to avoid errors when no files match
  setopt nullglob 2>/dev/null || true
  for plugin_link in "${MEOW}/.installed/plugins"/*; do
    [[ -L "$plugin_link" ]] || continue
    plugin_name=$(basename "$plugin_link")

    # Only load init.sh if plugin is available
    if _is_plugin_available "$plugin_name"; then
      init_script="${MEOW}/plugins/${plugin_name}/init.sh"
      if [[ -f "$init_script" ]]; then
        # shellcheck source=/dev/null
        source "$init_script"
      fi
    fi
  done
  unsetopt nullglob 2>/dev/null || true
fi

# Load zsh-autosuggestions
if [[ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Load zsh-syntax-highlighting
if [[ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
