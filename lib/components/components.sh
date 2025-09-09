#!/usr/bin/env bash
# @file:    lib/components/components.sh
# @brief:   Component management utilities for modular system installation.
# @author:  Andrew Vasilyev
# @license: MIT
#

if [[ -n "${_LIB_CORE_COMPONENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_CORE_COMPONENTS_SOURCED=1

source "${MEOW}/lib/components/core.sh"
source "${MEOW}/lib/components/packages.sh"
source "${MEOW}/lib/components/repository.sh"
source "${MEOW}/lib/components/dependencies.sh"
source "${MEOW}/lib/components/symlinks.sh"
source "${MEOW}/lib/components/operations.sh"
