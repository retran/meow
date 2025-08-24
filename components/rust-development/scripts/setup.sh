#!/usr/bin/env bash

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/system/rust.sh"

setup_rustup || true
