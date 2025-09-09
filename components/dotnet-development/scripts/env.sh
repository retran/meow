#!/usr/bin/env bash
# @file:    components/dotnet-development/scripts/env.sh
# @brief:   Environment configuration script for .NET development tools and SDK paths.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_DOTNET_DEVELOPMENT_ENV_SOURCED:-}" ]; then
  exit 0
fi
_COMPONENT_DOTNET_DEVELOPMENT_ENV_SOURCED=1

if [ -d "$HOME/.dotnet/tools" ]; then
  export PATH="$HOME/.dotnet/tools:$PATH"
fi

export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
