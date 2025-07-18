#!/usr/bin/env bats

# tests/comprehensive.bats - Comprehensive tests for the refactored shell scripts

setup() {
  export DOTFILES_DIR="$(pwd)"
  export BASH32="/tmp/bash32/bin/bash"
}

@test "bash 3.2 compatibility verified" {
  # Test that all scripts pass syntax check
  run bash -c "find . -name '*.sh' -type f -exec /tmp/bash32/bin/bash -n {} \;"
  [ "$status" -eq 0 ]
}

@test "no bash 4+ features remain" {
  # Check for problematic bash 4+ features
  run bash -c "grep -r 'declare -A\\|&>>\\|\\*\\*\\|readarray\\|mapfile\\|printf -v\\|declare -g' --include='*.sh' ."
  [ "$status" -ne 0 ]  # Should find nothing
}

@test "consistent shebang usage" {
  # All shell scripts should use bash
  run bash -c "find . -name '*.sh' -type f -exec head -1 {} \; | grep -v '#!/usr/bin/env bash'"
  [ -z "$output" ]
}

@test "ui functions maintain consistency" {
  run $BASH32 -c "
    export DOTFILES_DIR='$(pwd)'
    source lib/core/bash_compat.sh
    source lib/core/colors.sh
    source lib/core/ui.sh
    
    # Test that core UI functions work
    msg 0 'Test message'
    success 0 'Test success'
    warning 0 'Test warning'
    error 0 'Test error'
  "
  [ "$status" -eq 0 ]
}

@test "version detection works correctly" {
  run $BASH32 -c "
    source lib/core/bash_compat.sh
    version=\$(get_bash_version_number)
    echo \"Version: \$version\"
    [[ \$version -eq 302 ]]
  "
  [ "$status" -eq 0 ]
}

@test "compatibility warnings displayed" {
  run $BASH32 -c "
    source lib/core/bash_compat.sh
    warn_bash_compatibility 0
  "
  [ "$status" -eq 0 ]
  [[ "$output" =~ "compatibility mode" ]]
}