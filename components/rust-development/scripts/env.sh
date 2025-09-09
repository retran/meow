#!/usr/bin/env bash
# @file:    components/rust-development/scripts/env.sh
# @brief:   Installation or configuration script for rust-development component.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [ -n "${_COMPONENT_RUST_DEVELOPMENT_ENV_SOURCED:-}" ]; then
  return 0
fi
_COMPONENT_RUST_DEVELOPMENT_ENV_SOURCED=1

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

export RUST_BACKTRACE=1
export CARGO_INCREMENTAL=1

if command -v cargo >/dev/null 2>&1 && [ -d "$HOME/.cargo/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.cargo/bin:"*) ;;
    *)
      export PATH="$HOME/.cargo/bin:$PATH"
      ;;
  esac
fi
