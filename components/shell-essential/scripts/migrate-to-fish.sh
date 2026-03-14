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
# @file: components/shell-essential/scripts/migrate-to-fish.sh
# @brief: One-shot migration script — removes zsh/oh-my-zsh/direnv, sets fish as default shell.
# @author: Andrew Vasilyev
# @license: MIT
#
# Usage: bash migrate-to-fish.sh
# This script is intentionally standalone. Run it once, then restart your terminal.
#
set -euo pipefail

# ============================================================================
# Helpers
# ============================================================================

_info()    { printf '\033[34m  info\033[0m  %s\n' "$*"; }
_ok()      { printf '\033[32m    ok\033[0m  %s\n' "$*"; }
_warn()    { printf '\033[33m  warn\033[0m  %s\n' "$*"; }
_step()    { printf '\033[1;37m  ----  %s\033[0m\n' "$*"; }
_confirm() {
  local prompt="$1"
  if command -v gum >/dev/null 2>&1; then
    gum confirm "$prompt"
  else
    printf '%s [y/N] ' "$prompt"
    read -r _ans
    case "$_ans" in [yY]*) return 0;; *) return 1;; esac
  fi
}

# ============================================================================
# Pre-flight checks
# ============================================================================

_step "Migration: zsh → fish"
echo
echo "  This script will:"
echo "    1. Remove oh-my-zsh"
echo "    2. Remove zsh config files (.zshrc, .zprofile, .zlogin, .zlogout)"
echo "    3. Remove zsh history and cache files"
echo "    4. Remove zsh from package managers (not /bin/zsh — system shell is untouched)"
echo "    5. Remove direnv (conflicts with mise)"
echo "    6. Set fish as the default login shell"
echo
echo "  /bin/zsh (macOS system shell) is NEVER touched."
echo

if ! _confirm "Proceed with migration?"; then
  echo "Aborted."
  exit 0
fi

# ============================================================================
# Step 1 — Remove oh-my-zsh
# ============================================================================

_step "Removing oh-my-zsh"

if [ -d "$HOME/.oh-my-zsh" ]; then
  if [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
    _info "Running oh-my-zsh uninstaller..."
    # The uninstaller tries to run chsh; we suppress errors and handle shell separately
    ZSH="$HOME/.oh-my-zsh" bash "$HOME/.oh-my-zsh/tools/uninstall.sh" 2>/dev/null || true
  fi
  # Belt-and-suspenders: remove the directory regardless
  rm -rf "$HOME/.oh-my-zsh"
  _ok "Removed ~/.oh-my-zsh"
else
  _info "~/.oh-my-zsh not found — skipping"
fi

# ============================================================================
# Step 2 — Remove zsh config files
# ============================================================================

_step "Removing zsh config files"

for f in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zlogin" "$HOME/.zlogout" "$HOME/.zshenv"; do
  if [ -f "$f" ] || [ -L "$f" ]; then
    rm -f "$f"
    _ok "Removed $f"
  fi
done

# ============================================================================
# Step 3 — Remove zsh history and caches
# ============================================================================

_step "Removing zsh history and caches"

rm -f "$HOME/.zsh_history" "$HOME/.zsh_history.old" 2>/dev/null || true
rm -f "$HOME/.zcompdump" 2>/dev/null || true
rm -f "$HOME"/.zcompdump.* 2>/dev/null || true
rm -rf "$HOME/.zsh_cache" 2>/dev/null || true
_ok "Cleaned zsh history and cache files"

# ============================================================================
# Step 4 — Remove zsh packages (NOT /bin/zsh)
# ============================================================================

_step "Removing zsh packages from package managers"

_remove_pkg() {
  local mgr="$1" pkg="$2"
  case "$mgr" in
    brew)
      if brew list --formula 2>/dev/null | grep -qx "$pkg"; then
        brew uninstall --ignore-dependencies "$pkg" 2>/dev/null && _ok "brew: removed $pkg" || _warn "brew: failed to remove $pkg"
      fi
      ;;
    apt)
      if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
        sudo apt-get remove -y "$pkg" 2>/dev/null && _ok "apt: removed $pkg" || _warn "apt: failed to remove $pkg"
      fi
      ;;
    apk)
      if apk info "$pkg" 2>/dev/null | grep -q "$pkg"; then
        sudo apk del "$pkg" 2>/dev/null && _ok "apk: removed $pkg" || _warn "apk: failed to remove $pkg"
      fi
      ;;
    pacman)
      if pacman -Qi "$pkg" 2>/dev/null | grep -q Name; then
        sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null && _ok "pacman: removed $pkg" || _warn "pacman: failed to remove $pkg"
      fi
      ;;
    dnf)
      if rpm -q "$pkg" 2>/dev/null | grep -qv 'not installed'; then
        sudo dnf remove -y "$pkg" 2>/dev/null && _ok "dnf: removed $pkg" || _warn "dnf: failed to remove $pkg"
      fi
      ;;
  esac
}

ZSH_PKGS=(zsh zsh-autosuggestions zsh-syntax-highlighting)

if command -v brew >/dev/null 2>&1; then
  for p in "${ZSH_PKGS[@]}"; do _remove_pkg brew "$p"; done
elif command -v apt-get >/dev/null 2>&1; then
  for p in "${ZSH_PKGS[@]}"; do _remove_pkg apt "$p"; done
elif command -v apk >/dev/null 2>&1; then
  for p in "${ZSH_PKGS[@]}"; do _remove_pkg apk "$p"; done
elif command -v pacman >/dev/null 2>&1; then
  for p in "${ZSH_PKGS[@]}"; do _remove_pkg pacman "$p"; done
elif command -v dnf >/dev/null 2>&1; then
  for p in "${ZSH_PKGS[@]}"; do _remove_pkg dnf "$p"; done
else
  _warn "No recognised package manager found — skipping zsh package removal"
fi

# ============================================================================
# Step 5 — Remove direnv
# ============================================================================

_step "Removing direnv"

if command -v mise >/dev/null 2>&1; then
  if mise ls 2>/dev/null | grep -q direnv; then
    mise uninstall direnv 2>/dev/null && _ok "mise: uninstalled direnv" || _warn "mise: failed to uninstall direnv"
  else
    _info "direnv not installed via mise — skipping"
  fi

  # Remove direnv from ~/.config/mise/config.toml if present
  local_mise_config="${XDG_CONFIG_HOME:-$HOME/.config}/mise/config.toml"
  if [ -f "$local_mise_config" ] && grep -q 'direnv' "$local_mise_config"; then
    # Remove the direnv line(s)
    tmp=$(mktemp)
    grep -v 'direnv' "$local_mise_config" > "$tmp" && mv "$tmp" "$local_mise_config"
    _ok "Removed direnv from $local_mise_config"
  fi
fi

# Remove direnv binary from common locations (if installed outside mise)
for bin_path in "$HOME/.local/bin/direnv" "/usr/local/bin/direnv"; do
  if [ -f "$bin_path" ]; then
    rm -f "$bin_path" && _ok "Removed $bin_path" || _warn "Could not remove $bin_path"
  fi
done

# ============================================================================
# Step 6 — Set fish as default shell
# ============================================================================

_step "Setting fish as default login shell"

fish_path=$(command -v fish 2>/dev/null || true)

if [ -z "$fish_path" ]; then
  _warn "fish not found in PATH — install fish first, then run: chsh -s \$(which fish)"
else
  # Add to /etc/shells if needed
  if ! grep -qF "$fish_path" /etc/shells 2>/dev/null; then
    _info "Adding $fish_path to /etc/shells"
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [ "$SHELL" = "$fish_path" ]; then
    _ok "fish is already the default shell"
  else
    chsh -s "$fish_path" && _ok "Default shell changed to $fish_path" || _warn "chsh failed — run manually: chsh -s $fish_path"
  fi
fi

# ============================================================================
# Done
# ============================================================================

echo
_step "Migration complete"
echo
echo "  Restart your terminal (or open a new window) to start using fish."
echo "  Fisher and plugins will be set up automatically on first launch via meowctl."
echo
