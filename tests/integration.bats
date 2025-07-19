#!/usr/bin/env bats

# tests/integration.bats - Integration tests for core functionality

setup() {
  export MEOW="$(pwd)"
}

@test "core libraries can be loaded without errors" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
  "
  [ "$status" -eq 0 ]
}

@test "package management libraries load correctly" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
  "
  [ "$status" -eq 0 ]
}

@test "ui functions work correctly" {
  run bash -c "
    export MEOW='$(pwd)'
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
    export MEOW='$(pwd)'
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
    export MEOW='$(pwd)'
    source lib/core/colors.sh
    source lib/motd/motd.sh
    
    # Test that key functions exist
    declare -f get_comment_collection > /dev/null
    declare -f display_art_and_stats > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "install script shows help correctly" {
  run bash -c "./bin/install.sh --help"
  [ "$status" -eq 0 ]
  [[ "$output" == *"meow"* ]]
  [[ "$output" == *"PRESET"* ]]
}

@test "update script shows help correctly" {
  run bash -c "./bin/update.sh --help"
  [ "$status" -eq 0 ]
  [[ "$output" == *"meow"* ]]
  [[ "$output" == *"Updates packages"* ]]
}

@test "environment variables are properly configured" {
  run bash -c "
    source config/env/env.sh
    echo \$MEOW
    [[ -n \$MEOW ]]
    [[ -n \$XDG_CONFIG_HOME ]]
    [[ -n \$EDITOR ]]
  "
  [ "$status" -eq 0 ]
}

@test "bash compatibility functions work" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/bash_compat.sh
    
    # Test version detection
    get_bash_version_numeric
    show_bash_version_info 0
  "
  [ "$status" -eq 0 ]
}

@test "package manager common functions are available" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/common.sh
    
    # Test that common functions exist
    declare -f install_packages_generic > /dev/null
    declare -f update_packages_generic > /dev/null
  "
  [ "$status" -eq 0 ]
}