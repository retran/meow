#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_GO_DEVELOPMENT_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_GO_DEVELOPMENT_ENV_SOURCED=1

# Go environment
if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$(go env GOPATH)}"
  export PATH="$GOPATH/bin:$PATH"
fi
