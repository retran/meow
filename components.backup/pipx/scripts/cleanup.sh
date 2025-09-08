#!/usr/bin/env bash

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running Pipx cleanup..."

if command -v pipx >/dev/null 2>&1; then
  ui_info "  📦 Cleaning pipx cache..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  🔄 (dry-run) Would run: pipx uninstall-all --force"
  else
    if ! pipx uninstall-all --force >/dev/null 2>&1; then
      ui_warn "Failed to uninstall all pipx packages"
    fi
  fi
fi

if [ -d "$HOME/.local/share/pipx" ]; then
  ui_info "  🗑️  Cleaning pipx installation directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  🔄 (dry-run) Would remove: $HOME/.local/share/pipx"
  else
    if ! rm -rf "$HOME/.local/share/pipx" >/dev/null 2>&1; then
      ui_warn "Failed to remove pipx installation directory"
    fi
  fi
fi

if [ -d "$HOME/.cache/pipx" ]; then
  ui_info "  🗑️  Cleaning pipx cache directory..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  🔄 (dry-run) Would remove: $HOME/.cache/pipx"
  else
    if ! rm -rf "$HOME/.cache/pipx" >/dev/null 2>&1; then
      ui_warn "Failed to remove pipx cache directory"
    fi
  fi
fi

if [ -d "$HOME/.local/bin" ]; then
  ui_info "  🗑️  Cleaning pipx binaries..."
  if [ "${MEOW_DRY_RUN:-false}" = "true" ]; then
    ui_info "  🔄 (dry-run) Would clean pipx binaries in: $HOME/.local/bin"
  else
    if ! find "$HOME/.local/bin" -type l -exec sh -c 'readlink "$1" | grep -q "pipx" && rm "$1"' _ {} \; >/dev/null 2>&1; then
      ui_warn "Failed to clean pipx binaries"
    fi
  fi
fi

if [ "${MEOW_VERBOSE:-false}" = "true" ]; then
  ui_info "✅ Pipx cleanup completed"
else
  ui_success "✅ Pipx cleanup completed"
fi
