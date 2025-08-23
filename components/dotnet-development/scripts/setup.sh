#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

if ! command -v dotnet >/dev/null 2>&1; then
  ui_warning "$(get_static_message "dotnet_not_found_skip")"
  exit 0
fi

ui_action_start "$(get_static_message "dotnet_configuring")"

ui_info "$(get_static_message "dotnet_configuring_tools_path")"
dotnet_tools_path="$HOME/.dotnet/tools"
mkdir -p "$dotnet_tools_path" 2>/dev/null || true

ui_info "$(get_static_message "dotnet_installing_global_tools")"

dotnet tool install --global dotnet-ef 2>/dev/null || dotnet tool update --global dotnet-ef 2>/dev/null || true

dotnet tool install --global dotnet-aspnet-codegenerator 2>/dev/null || dotnet tool update --global dotnet-aspnet-codegenerator 2>/dev/null || true

ui_info "$(get_static_message "dotnet_configuring_dev_certificates")"
dotnet dev-certs https --trust 2>/dev/null || true

ui_info "$(get_static_message "dotnet_configuring_nuget_sources")"
dotnet nuget add source https://api.nuget.org/v3/index.json --name "nuget.org" 2>/dev/null || true

if [[ ! -f "$HOME/global.json" ]]; then
  ui_info "$(get_static_message "dotnet_creating_global_json")"
  cat > "$HOME/global.json" << 'EOF'
{
  "sdk": {
    "allowPrerelease": false,
    "rollForward": "latestMinor"
  }
}
EOF
fi

ui_action_success "$(get_static_message "dotnet_configured_successfully")"
