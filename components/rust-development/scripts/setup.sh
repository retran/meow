#!/usr/bin/env bash

COMPONENT_NAME="$1"
MEOW="$2"

# Source the rust.sh library
if [ -f "${MEOW}/lib/system/rust.sh" ]; then
  source "${MEOW}/lib/system/rust.sh"
else
  echo "Error: rust.sh not found at ${MEOW}/lib/system/rust.sh" >&2
  exit 1
fi

# Setup rustup with verbose and dry-run support
if [ "$MEOW_VERBOSE" = "true" ]; then
  echo "Setting up rustup for component: $COMPONENT_NAME"
fi

if [ "$MEOW_DRY_RUN" = "true" ]; then
  echo "DRY-RUN: Would setup rustup for component: $COMPONENT_NAME"
else
  setup_rustup || true
fi
