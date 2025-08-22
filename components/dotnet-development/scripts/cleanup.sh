#!/usr/bin/env bash

# .NET Development component cleanup script
# This script is executed when the dotnet-development component is being uninstalled

set -euo pipefail

# Source the strings for localized messages
source "${MEOW}/lib/strings/strings.sh"

echo "$(get_static_message "dotnet_cleanup_running")"

# Clear NuGet cache
if command -v dotnet >/dev/null 2>&1; then
  echo "$(get_static_message "dotnet_cleaning_nuget_cache")"
  dotnet nuget locals all --clear 2>/dev/null || true

  echo "$(get_static_message "dotnet_cleaning_temp_files")"
  dotnet clean 2>/dev/null || true
fi

# Clean up NuGet packages cache manually if needed
if [[ -d "$HOME/.nuget/packages" ]]; then
  echo "$(get_static_message "dotnet_cleaning_nuget_packages")"
  rm -rf "$HOME/.nuget/packages/.tools" 2>/dev/null || true
fi

# Clean up Visual Studio Code omnisharp cache
if [[ -d "$HOME/.omnisharp" ]]; then
  echo "$(get_static_message "dotnet_cleaning_omnisharp")"
  rm -rf "$HOME/.omnisharp" 2>/dev/null || true
fi

# Clean up dotnet temp directories
if [[ -d "/tmp/.dotnet" ]]; then
  echo "$(get_static_message "dotnet_cleaning_dotnet_temp")"
  rm -rf "/tmp/.dotnet" 2>/dev/null || true
fi

echo "$(get_static_message "dotnet_cleanup_completed")"
