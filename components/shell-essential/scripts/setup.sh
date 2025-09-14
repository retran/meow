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

setup_tmux_plugin_manager() {
  if ! command -v tmux >/dev/null 2>&1; then
    ui_warning "tmux is not installed. Skipping Plugin Manager setup."
    return 0
  fi

  ui_step_header "Setting up tmux Plugin Manager"

  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    ui_action_success "tmux Plugin Manager is already installed."

    if [ "${MEOW_DRY_RUN:-}" = "true" ]; then
      ui_info "(dry-run) Would update tmux Plugin Manager"
      return 0
    fi

    ui_spinner "Updating tmux Plugin Manager..." \
      --success "tmux Plugin Manager updated." \
      --fail "Failed to update tmux Plugin Manager." \
      git -C "$HOME/.tmux/plugins/tpm" pull

    return $?
  fi

  if [ "${MEOW_DRY_RUN:-}" = "true" ]; then
    ui_info "(dry-run) Would create directory and install tmux Plugin Manager"
    return 0
  fi

  mkdir -p "$HOME/.tmux/plugins"

  ui_spinner "Installing tmux Plugin Manager..." \
    --success "tmux Plugin Manager installed." \
    --fail "Failed to install tmux Plugin Manager." \
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

  return $?
}

configure_tmux() {
  ui_step_header "Setting up tmux environment"

  if setup_tmux_plugin_manager; then
    ui_action_success "tmux environment setup complete."
  else
    ui_warning "tmux environment setup had issues, continuing..."
  fi
  return 0
}

setup_ohmyzsh() {
  ui_action_start "Checking for Oh My Zsh installation..."

  local ohmyzsh_path="$HOME/.oh-my-zsh"

  if [ -d "$ohmyzsh_path" ]; then
    ui_action_success "Oh My Zsh is already installed."

    if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
      ui_action_start "Skipping Oh My Zsh update (dry-run mode)"
      return 0
    fi

    ui_spinner "Updating Oh My Zsh..." \
      --success "Oh My Zsh updated successfully." \
      --fail "Failed to update Oh My Zsh." \
      sh -c "ZSH=\"\$1\" zsh -c \"source \\\"\$ZSH/oh-my-zsh.sh\\\" && omz update\"" _ "$ohmyzsh_path"
    return $?
  fi

  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_action_start "Skipping Oh My Zsh installation (dry-run mode)"
    return 0
  fi

  ui_spinner "Installing Oh My Zsh..." \
    --success "Oh My Zsh installed successfully." \
    --fail "Failed to install Oh My Zsh." \
    sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh'
  return $?
}

configure_zsh() {
  ui_step_header "Setting up Zsh environment"

  if setup_ohmyzsh; then
    ui_action_success "Zsh environment setup complete."
  else
    ui_warning "Oh My Zsh setup had issues, continuing..."
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

install_zsh_plugins() {
  local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local plugins_installed_count=0
  local plugins_skipped_count=0
  local plugins_failed_count=0
  local return_status=0

  ui_action_start "$(_f "Checking Zsh plugins in '%s'" "$zsh_custom_dir")"

  if [ -d "$zsh_custom_dir" ]; then
    if [ ! -d "${zsh_custom_dir}/plugins/zsh-autosuggestions" ]; then
      ui_action_start "$(_f "Cloning zsh-autosuggestions to '%s/plugins'" "$zsh_custom_dir")"
      if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
        ui_info "(dry-run) Would clone zsh-autosuggestions"
        plugins_installed_count=$((plugins_installed_count + 1))
      elif git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
        "${zsh_custom_dir}/plugins/zsh-autosuggestions" >/dev/null 2>&1; then
        ui_action_success "zsh-autosuggestions cloned successfully"
        plugins_installed_count=$((plugins_installed_count + 1))
      else
        ui_action_fail "$(_f "Failed to clone zsh-autosuggestions. Check internet connection or permissions.")"
        plugins_failed_count=$((plugins_failed_count + 1))
        return_status=1
      fi
    else
      ui_info "$(_f "zsh-autosuggestions already installed in '%s/plugins'." "$zsh_custom_dir")"
      plugins_skipped_count=$((plugins_skipped_count + 1))
    fi

    if [ ! -d "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" ]; then
      ui_action_start "$(_f "Cloning zsh-syntax-highlighting to '%s/plugins'" "$zsh_custom_dir")"
      if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
        ui_info "(dry-run) Would clone zsh-syntax-highlighting"
        plugins_installed_count=$((plugins_installed_count + 1))
      elif git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${zsh_custom_dir}/plugins/zsh-syntax-highlighting" >/dev/null 2>&1; then
        ui_action_success "zsh-syntax-highlighting cloned successfully"
        plugins_installed_count=$((plugins_installed_count + 1))
      else
        ui_action_fail "$(_f "Failed to clone zsh-syntax-highlighting. Check internet connection or permissions.")"
        plugins_failed_count=$((plugins_failed_count + 1))
        return_status=1
      fi
    else
      ui_info "$(_f "zsh-syntax-highlighting already installed in '%s/plugins'." "$zsh_custom_dir")"
      plugins_skipped_count=$((plugins_skipped_count + 1))
    fi

    if [ "$plugins_failed_count" -gt 0 ]; then
      ui_action_fail "$(_f "Zsh plugin check completed with %d failures, %d installed, %d skipped." "$plugins_failed_count" "$plugins_installed_count" "$plugins_skipped_count")"
    elif [ "$plugins_installed_count" -gt 0 ]; then
      ui_action_success "$(_f "Zsh plugin check completed: %d installed, %d skipped." "$plugins_installed_count" "$plugins_skipped_count")"
    else
      ui_action_success "All required Zsh plugins are already installed."
    fi

  else
    ui_warning "$(_f "Oh My Zsh custom directory not found at '%s'. Skipping Zsh plugin installation." "$zsh_custom_dir")"
    return_status=1
  fi
  return "$return_status"
}

if [ "$MEOW_VERBOSE" = "true" ]; then
  ui_info "Installing zsh plugins"
fi

install_zsh_plugins

if command -v tmux >/dev/null 2>&1; then
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Configuring tmux"
  fi
  configure_tmux || true
fi

if command -v zsh >/dev/null 2>&1; then
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Configuring zsh"
  fi
  configure_zsh || true
fi

if command -v npm >/dev/null 2>&1; then
  if [ "$MEOW_VERBOSE" = "true" ]; then
    ui_info "Configuring npm"
  fi
  configure_npm || true
fi
