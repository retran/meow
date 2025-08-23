#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_COMPONENT_KOTLIN_DEVELOPMENT_ENV_SOURCED:-}" ]]; then
  return 0
fi
_COMPONENT_KOTLIN_DEVELOPMENT_ENV_SOURCED=1

if command -v java >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    java_home_path="/opt/homebrew/opt/temurin@21/libexec/openjdk.jdk/Contents/Home"
    if [[ -d "$java_home_path" ]]; then
      export JAVA_HOME="$java_home_path"
    else
      java_home_path="$(/usr/libexec/java_home -v 21 2>/dev/null || /usr/libexec/java_home 2>/dev/null || true)"
      if [[ -n "$java_home_path" ]]; then
        export JAVA_HOME="$java_home_path"
      fi
    fi
  fi
fi
