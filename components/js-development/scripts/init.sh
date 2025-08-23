#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_JS_DEVELOPMENT_INIT_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_JS_DEVELOPMENT_INIT_SOURCED=1
