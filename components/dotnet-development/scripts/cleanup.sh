#!/usr/bin/env bash

set -euo pipefail

source "${MEOW}/lib/strings/strings.sh"
source "${MEOW}/lib/core/ui.sh"

ui_info "$(fmt "dotnet_cleanup_running")"

if command -v dotnet >/dev/null 2>&1; then
  ui_info "$(fmt "dotnet_cleaning_nuget_cache")"
  dotnet nuget locals all --clear 2>/dev/null || true

  ui_info "$(fmt "dotnet_cleaning_temp_files")"
  dotnet clean 2>/dev/null || true
fi

if [[ -d "$HOME/.nuget/packages" ]]; then
  ui_info "$(fmt "dotnet_cleaning_nuget_packages")"
  rm -rf "$HOME/.nuget/packages/.tools" 2>/dev/null || true
fi

if [[ -d "$HOME/.omnisharp" ]]; then
  ui_info "$(fmt "dotnet_cleaning_omnisharp")"
  rm -rf "$HOME/.omnisharp" 2>/dev/null || true
fi

if [[ -d "/tmp/.dotnet" ]]; then
  ui_info "$(fmt "dotnet_cleaning_dotnet_temp")"
  rm -rf "/tmp/.dotnet" 2>/dev/null || true
fi

ui_success "$(fmt "dotnet_cleanup_completed")"
