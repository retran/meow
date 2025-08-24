#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/core/ui.sh"

ui_info "🧹 Running .NET Development cleanup..."

if command -v dotnet >/dev/null 2>&1; then
  ui_info "  📦 Cleaning NuGet cache..."
  dotnet nuget locals all --clear 2>/dev/null || true

  ui_info "  🗑️  Cleaning .NET temporary files..."
  dotnet clean 2>/dev/null || true
fi

if [[ -d "$HOME/.nuget/packages" ]]; then
  ui_info "  🗑️  Cleaning NuGet packages cache..."
  rm -rf "$HOME/.nuget/packages/.tools" 2>/dev/null || true
fi

if [[ -d "$HOME/.omnisharp" ]]; then
  ui_info "  🗑️  Cleaning OmniSharp cache..."
  rm -rf "$HOME/.omnisharp" 2>/dev/null || true
fi

if [[ -d "/tmp/.dotnet" ]]; then
  ui_info "  🗑️  Cleaning dotnet temp files..."
  rm -rf "/tmp/.dotnet" 2>/dev/null || true
fi

ui_success "✅ .NET Development cleanup completed"
