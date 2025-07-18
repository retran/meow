#!/usr/bin/env bats

# tests/here_strings.bats - Tests for here-string compatibility fixes

setup() {
  export DOTFILES_DIR="$(pwd)"
  export BASH32="/tmp/bash32/bin/bash"
}

@test "motd.sh functions work with bash 3.2" {
  run $BASH32 -c "
    source lib/core/colors.sh
    source lib/motd/motd.sh
    
    # Test that the function exists and can be called
    declare -f get_comment_collection > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "presets.sh functions work with bash 3.2" {
  run $BASH32 -c "
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
    
    # Test that key functions exist
    declare -f apply_preset > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "update.sh functions work with bash 3.2" {
  run $BASH32 -c "
    source lib/core/colors.sh
    source lib/core/ui.sh
    source lib/package/presets.sh
    source lib/commands/update.sh
    
    # Test that key functions exist
    declare -f update_preset_with_dependencies > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "no here-strings remain in shell scripts" {
  run bash -c "grep -r '<<<' --include='*.sh' lib/ bin/ scripts/ config/ || true"
  [ -z "$output" ]
}