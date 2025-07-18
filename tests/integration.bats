#!/usr/bin/env bats

# tests/integration.bats - Integration tests for core functionality

setup() {
  export DOTFILES_DIR="$(pwd)"
}

@test "core libraries can be loaded without errors" {
  run bash -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
  "
  [ "$status" -eq 0 ]
}

@test "package management libraries load correctly" {
  run bash -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
  "
  [ "$status" -eq 0 ]
}

@test "ui functions work correctly" {
  run bash -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    
    # Test basic UI functions
    msg 0 'Test message'
    success 0 'Test success'
    info 0 'Test info'
    action_msg 0 'Test action'
  "
  [ "$status" -eq 0 ]
}

@test "preset management functions exist and are callable" {
  run bash -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Verify critical functions exist
    declare -f apply_preset > /dev/null
    declare -f list_installed_presets > /dev/null
    declare -f save_installed_preset > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "motd functions load and work" {
  run bash -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/colors.sh
    source lib/motd/motd.sh
    
    # Test that key functions exist
    declare -f get_comment_collection > /dev/null
    declare -f display_art_and_stats > /dev/null
  "
  [ "$status" -eq 0 ]
}