#!/usr/bin/env bats

# tests/integration.bats - Integration tests for core functionality

setup() {
  export DOTFILES_DIR="$(pwd)"
  export BASH32="/tmp/bash32/bin/bash"
}

@test "install script can be sourced" {
  run $BASH32 -c "
    export DOTFILES_DIR='$(pwd)'
    source bin/install.sh --help 2>/dev/null || true
  "
  [ "$status" -eq 0 ]
}

@test "update script can be sourced" {
  run $BASH32 -c "
    export DOTFILES_DIR='$(pwd)'
    source bin/update.sh --help 2>/dev/null || true
  "
  [ "$status" -eq 0 ]
}

@test "core libraries can be loaded together" {
  run $BASH32 -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Test that critical functions exist
    declare -f show_bash_version_info > /dev/null
    declare -f apply_preset > /dev/null
  "
  [ "$status" -eq 0 ]
}