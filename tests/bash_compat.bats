#!/usr/bin/env bats

# tests/bash_compat.bats - Tests for bash 3.2 compatibility

setup() {
  export DOTFILES_DIR="$(pwd)"
  export BASH32="/tmp/bash32/bin/bash"
}

@test "bash_compat.sh loads without errors" {
  run $BASH32 -c "source lib/core/bash_compat.sh"
  [ "$status" -eq 0 ]
}

@test "colors.sh loads without errors" {
  run $BASH32 -c "source lib/core/colors.sh"
  [ "$status" -eq 0 ]
}

@test "ui.sh loads without errors" {
  run $BASH32 -c "
    source lib/core/bash_compat.sh
    source lib/core/colors.sh  
    source lib/core/ui.sh
  "
  [ "$status" -eq 0 ]
}

@test "bash version detection works" {
  run $BASH32 -c "
    source lib/core/bash_compat.sh
    get_bash_version_number
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^3[0-9]+$ ]]
}

@test "check_bash_version function works" {
  run $BASH32 -c "
    source lib/core/bash_compat.sh
    check_bash_version 3 2
  "
  [ "$status" -eq 0 ]
}

@test "all shell scripts pass syntax check with bash 3.2" {
  while IFS= read -r script; do
    run $BASH32 -n "$script"
    [ "$status" -eq 0 ]
  done < <(find . -name "*.sh" -type f)
}