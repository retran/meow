#!/usr/bin/env bash
# Sets DOTNET_ROOT and ensures dotnet/tools are on PATH
if [ -n "${_COMPONENT_DOTNET_TOOLCHAIN_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_DOTNET_TOOLCHAIN_ENV_SOURCED=1

DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
if [ -d "$DOTNET_ROOT" ]; then
  export DOTNET_ROOT
  case ":${PATH}:" in
    *:"${DOTNET_ROOT}":*) ;;
    *) PATH="${DOTNET_ROOT}:${PATH}" ;;
  esac
fi

DOTNET_TOOLS_DIR="${DOTNET_ROOT}/tools"
if [ -d "$DOTNET_TOOLS_DIR" ]; then
  case ":${PATH}:" in
    *:"${DOTNET_TOOLS_DIR}":*) ;;
    *) PATH="${PATH}:${DOTNET_TOOLS_DIR}" ;;
  esac
fi

export PATH
