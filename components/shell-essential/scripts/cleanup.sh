#!/usr/bin/env bash
# @file:    components/shell-essential/scripts/cleanup.sh
# @brief:   Cleanup script for shell tools, caches, and temporary files.
# @author:  Andrew Vasilyev
# @license: MIT
#

source "${MEOW}/lib/core/ui.sh"

ui_info "Starting essential shell cleanup..."

if [ -d "$HOME/.zsh_cache" ]; then
  ui_info "Cleaning Zsh cache directory: '$HOME/.zsh_cache'"
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.zsh_cache'"
  else
    rm -rf "$HOME/.zsh_cache" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.oh-my-zsh/cache" ]; then
  ui_info "Cleaning Oh My Zsh cache directory: '$HOME/.oh-my-zsh/cache'"
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.oh-my-zsh/cache'"
  else
    rm -rf "$HOME/.oh-my-zsh/cache" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.tmux" ]; then
  ui_info "Cleaning Tmux session logs and resurrect cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.tmux/logs'"
    ui_warn "DRY-RUN: Would remove '$HOME/.tmux/resurrect'"
  else
    rm -rf "$HOME/.tmux/logs" 2>/dev/null || true
    rm -rf "$HOME/.tmux/resurrect" 2>/dev/null || true
  fi
fi

ui_info "Cleaning old shell history backup files..."
if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
  ui_warn "DRY-RUN: Would remove '$HOME/.zsh_history.old'"
  ui_warn "DRY-RUN: Would remove '$HOME/.bash_history.old'"
else
  rm -f "$HOME/.zsh_history.old" 2>/dev/null || true
  rm -f "$HOME/.bash_history.old" 2>/dev/null || true
fi

if [ -d "$HOME/.zcompdump" ]; then
  ui_info "Cleaning Zsh completion cache files..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.zcompdump*'"
  else
    rm -f "$HOME/.zcompdump*" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.fzf" ]; then
  ui_info "Cleaning fzf Git repository cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.fzf/.git'"
  else
    rm -rf "$HOME/.fzf/.git" 2>/dev/null || true
  fi
fi

# Node.js cleanup (since node functionality is now in shell-essential)
if command -v npm >/dev/null 2>&1; then
  ui_info "Cleaning npm cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would run: npm cache clean --force"
  else
    npm cache clean --force 2>/dev/null || true
  fi
fi

if command -v yarn >/dev/null 2>&1; then
  ui_info "Cleaning yarn cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would run: yarn cache clean"
  else
    yarn cache clean 2>/dev/null || true
  fi
fi

if command -v pnpm >/dev/null 2>&1; then
  ui_info "Cleaning pnpm store..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would run: pnpm store prune"
  else
    pnpm store prune 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.npm/_cacache" ]; then
  ui_info "Cleaning npm global cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would remove: $HOME/.npm/_cacache"
  else
    rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
  fi
fi

if [ -d "$HOME/.node-gyp" ]; then
  ui_info "Cleaning node-gyp cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would remove: $HOME/.node-gyp"
  else
    rm -rf "$HOME/.node-gyp" 2>/dev/null || true
  fi
fi

# Pipx cleanup (since pipx functionality is now in shell-essential)
if command -v pipx >/dev/null 2>&1; then
  ui_info "Cleaning pipx cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would run: pipx uninstall-all --force"
  else
    if ! pipx uninstall-all --force >/dev/null 2>&1; then
      ui_warn "Failed to uninstall all pipx packages"
    fi
  fi
fi

if [ -d "$HOME/.local/share/pipx" ]; then
  ui_info "Cleaning pipx installation directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would remove: $HOME/.local/share/pipx"
  else
    if ! rm -rf "$HOME/.local/share/pipx" >/dev/null 2>&1; then
      ui_warn "Failed to remove pipx installation directory"
    fi
  fi
fi

if [ -d "$HOME/.cache/pipx" ]; then
  ui_info "Cleaning pipx cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would remove: $HOME/.cache/pipx"
  else
    if ! rm -rf "$HOME/.cache/pipx" >/dev/null 2>&1; then
      ui_warn "Failed to remove pipx cache directory"
    fi
  fi
fi

if [ -d "$HOME/.local/bin" ]; then
  ui_info "Cleaning pipx binaries..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "(dry-run) Would clean pipx binaries in: $HOME/.local/bin"
  else
    if ! find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; >/dev/null 2>&1; then
      ui_warn "Failed to clean pipx binaries"
    fi
  fi
fi

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "Verbose mode enabled"
fi

ui_success "Essential shell cleanup completed successfully."
