#!/usr/bin/env bash
# @file:    components/go-development/scripts/env.sh
# @brief:   Installation or configuration script for go-development component.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_GO_DEVELOPMENT_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_GO_DEVELOPMENT_ENV_SOURCED=1

if command -v go >/dev/null 2>&1; then
  export GOPATH="${GOPATH:-$(go env GOPATH)}"

  case ":${PATH}:" in
    *:"${GOPATH}/bin":*) ;;
    *)
      export PATH="${GOPATH}/bin:${PATH}"
      ;;
  esac
fi
