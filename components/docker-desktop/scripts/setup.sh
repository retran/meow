#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🚀 Running OrbStack setup..."

if ! command -v orb >/dev/null 2>&1; then
  ui_warning "OrbStack CLI not found. Installation may not be complete."
  exit 1
fi

if ! pgrep -f "OrbStack" >/dev/null; then
  ui_info "  ▶️  Starting OrbStack..."
  open -a OrbStack 2>/dev/null || true

  ui_info "  ⏳ Waiting for OrbStack to start..."
  local attempts=0
  while ! orb status >/dev/null 2>&1 && [[ $attempts -lt 30 ]]; do
    sleep 2
    ((attempts++))
  done

  if [[ $attempts -eq 30 ]]; then
    ui_warning "OrbStack startup timed out. Please start it manually."
    exit 1
  fi
fi

ui_success "✅ OrbStack setup completed"
ui_info "ℹ️  OrbStack is ready to use with Docker and Linux VMs"
