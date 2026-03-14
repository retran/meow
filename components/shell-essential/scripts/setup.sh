#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# @file: components/shell-essential/scripts/setup.sh
# @brief: Setup script for essential shell tools and development environment.
# @author: Andrew Vasilyev
# @license: MIT
#
COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/package/homebrew.sh"
source "${MEOW}/lib/package/apt.sh"
source "${MEOW}/lib/core/ui.sh"

# Create meow config directory for theme management
setup_meow_config_dir() {
  ui_step_header "Setting up meow config directory"

  CONFIG_DIR="${HOME}/.config/meow"
  if [ ! -d "${CONFIG_DIR}" ]; then
    if [ "${MEOW_DRY_RUN:-}" = "true" ]; then
      ui_info "(dry-run) Would create config directory: ${CONFIG_DIR}"
    else
      mkdir -p "${CONFIG_DIR}"
      ui_action_success "Created config directory: ${CONFIG_DIR}"
    fi
  else
    ui_action_success "Config directory exists: ${CONFIG_DIR}"
  fi
}

# Install Fisher (fish plugin manager)
setup_fisher() {
  ui_step_header "Setting up Fisher (fish plugin manager)"

  if ! command -v fish >/dev/null 2>&1; then
    ui_warning "fish not found — skipping Fisher installation."
    return 0
  fi

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would install Fisher via curl"
    return 0
  fi

  # Install or update Fisher
  if fish -c 'functions -q fisher' 2>/dev/null; then
    ui_spinner "Updating Fisher..." \
      --success "Fisher updated." \
      --fail "Failed to update Fisher." \
      fish -c 'fisher update'
  else
    ui_spinner "Installing Fisher..." \
      --success "Fisher installed." \
      --fail "Failed to install Fisher." \
      fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
  fi
  return $?
}

# Install fish plugins via Fisher
install_fish_plugins() {
  ui_step_header "Installing fish plugins"

  if ! command -v fish >/dev/null 2>&1; then
    ui_warning "fish not found — skipping plugin installation."
    return 0
  fi

  if ! fish -c 'functions -q fisher' 2>/dev/null; then
    ui_warning "Fisher not available — skipping plugin installation."
    return 0
  fi

  local plugins=(
    "PatrickF1/fzf.fish"         # fzf key bindings and completions
    "jorgebucaran/autopair.fish" # auto-close brackets/quotes
    "edc/bass"                   # source bash scripts from fish
    "meaningful-ooo/sponge"      # remove failed/silent commands from history
  )

  local installed=0 failed=0

  for plugin in "${plugins[@]}"; do
    if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
      ui_info "(dry-run) Would install fish plugin: $plugin"
      installed=$((installed + 1))
      continue
    fi

    if fish -c "fisher list | grep -qF '$plugin'" 2>/dev/null; then
      ui_info "Already installed: $plugin"
    else
      if fish -c "fisher install '$plugin'" 2>/dev/null; then
        ui_action_success "Installed: $plugin"
        installed=$((installed + 1))
      else
        ui_action_fail "Failed to install: $plugin"
        failed=$((failed + 1))
      fi
    fi
  done

  if [ "$failed" -gt 0 ]; then
    ui_warning "Fish plugin installation completed with $failed failure(s)."
    return 1
  fi

  ui_action_success "Fish plugins installed/verified."
  return 0
}

# Set fish as default shell
set_default_shell() {
  ui_step_header "Setting fish as default shell"

  local fish_path
  fish_path=$(command -v fish 2>/dev/null || true)

  if [ -z "$fish_path" ]; then
    ui_warning "fish not found in PATH — cannot set default shell."
    return 0
  fi

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would add $fish_path to /etc/shells and run chsh"
    return 0
  fi

  # Add fish to /etc/shells if not already listed
  if ! grep -qF "$fish_path" /etc/shells 2>/dev/null; then
    ui_action_start "Adding $fish_path to /etc/shells"
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  # Change default shell if not already fish
  if [ "$SHELL" != "$fish_path" ]; then
    ui_spinner "Changing default shell to fish..." \
      --success "Default shell set to fish. Restart your terminal." \
      --fail "Failed to change default shell." \
      chsh -s "$fish_path"
    return $?
  else
    ui_action_success "fish is already the default shell."
  fi

  return 0
}

configure_npm() {
  if ! command -v npm >/dev/null 2>&1; then
    ui_warning "npm command not found. Skipping Node.js configuration."
    return 0
  fi

  ui_step_header "Setting up npm environment"
  ui_action_start "Configuring npm for global packages without sudo."

  npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Creating npm global directory: '$npm_global_path'"
  fi

  if [ "$MEOW_DRY_RUN" != "true" ]; then
    mkdir -p "$npm_global_path" || {
      ui_action_fail "Failed to create npm global installation directory: '$npm_global_path'."
      return 1
    }
  fi

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Setting npm prefix to: '$npm_global_path'"
  fi

  if [ "$MEOW_DRY_RUN" != "true" ]; then
    npm config set prefix "$npm_global_path" || {
      ui_action_fail "Failed to set npm prefix to '$npm_global_path'."
      return 1
    }
  fi

  ui_action_success "NPM configured successfully."
  return 0
}

# ============================================================================
# Main
# ============================================================================

if command -v fish >/dev/null 2>&1; then
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Setting up Fisher"
  fi
  setup_fisher || true

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Installing fish plugins"
  fi
  install_fish_plugins || true

  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Setting fish as default shell"
  fi
  set_default_shell || true
else
  ui_warning "fish is not installed. Skipping Fisher and plugin setup."
fi

if command -v npm >/dev/null 2>&1; then
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Configuring npm"
  fi
  configure_npm || true
fi

if [ "$MEOW_VERBOSE" = "true" ]; then
  ui_info "Setting up meow config directory"
fi
setup_meow_config_dir || true
