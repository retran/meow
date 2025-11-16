#!/usr/bin/env bash
set -euo pipefail

install_zsh_plugins() {
  local zsh_custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local plugins=(zsh-autosuggestions zsh-syntax-highlighting)
  mkdir -p "$zsh_custom_dir/plugins"
  for plugin in "${plugins[@]}"; do
    local target="${zsh_custom_dir}/plugins/${plugin}"
    if [ ! -d "$target" ]; then
      git clone --depth 1 "https://github.com/zsh-users/${plugin}.git" "$target"
    else
      git -C "$target" pull --ff-only >/dev/null 2>&1 || true
    fi
  done
}

setup_tmux_plugin_manager() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir" ]; then
    git -C "$tpm_dir" pull --ff-only >/dev/null 2>&1
  else
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi
}

configure_npm_prefix() {
  local npm_global_path="${NPM_CONFIG_PREFIX:-${HOME}/.npm-global}"
  mkdir -p "$npm_global_path"
  npm config set prefix "$npm_global_path"
}
