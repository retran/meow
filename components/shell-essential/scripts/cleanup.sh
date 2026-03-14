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
# @file: components/shell-essential/scripts/cleanup.sh
# @brief: Cleanup script for shell tools, caches, and temporary files.
# @author: Andrew Vasilyev
# @license: MIT
#
source "${MEOW}/lib/core/ui.sh"

ui_info "Starting essential shell cleanup..."

# Fisher cache
if [ -d "$HOME/.local/share/fisher" ]; then
  ui_info "Cleaning Fisher cache directory: '$HOME/.local/share/fisher'"
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '$HOME/.local/share/fisher'"
  else
    rm -rf "$HOME/.local/share/fisher" 2>/dev/null || true
  fi
fi

# Zellij cache
if [ -d "${XDG_CACHE_HOME:-$HOME/.cache}/zellij" ]; then
  ui_info "Cleaning Zellij cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_warn "DRY-RUN: Would remove '${XDG_CACHE_HOME:-$HOME/.cache}/zellij'"
  else
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zellij" 2>/dev/null || true
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

# Node.js cleanup
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

# Pipx cleanup
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
