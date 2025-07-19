#!/usr/bin/env bats

# tests/package_manager.bats - Package manager functionality tests

setup() {
  export MEOW="$(pwd)"
}

@test "homebrew package functions are available" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/homebrew.sh
    
    # Test that homebrew functions exist
    declare -f setup_homebrew > /dev/null
    declare -f cleanup_homebrew > /dev/null
    declare -f is_package_installed > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "npm package functions are available" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh  
    source lib/package/npm.sh
    
    # Test that npm functions exist
    declare -f install_npm_packages > /dev/null
    declare -f update_npm_packages > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "cargo package functions are available" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/cargo.sh
    
    # Test that cargo functions exist  
    declare -f install_cargo_packages > /dev/null
    declare -f update_cargo_packages > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "go package functions are available" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/go.sh
    
    # Test that go functions exist
    declare -f install_go_packages > /dev/null  
    declare -f update_go_packages > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "package files exist and are properly formatted" {
  # Check for essential package files
  [ -f "packages/homebrew/core-development.Brewfile" ]
  [ -f "packages/npm/javascript.npmfile" ]
  [ -f "packages/pipx/core-development.Pipxfile" ]
  
  # Verify package files are not empty
  [ -s "packages/homebrew/core-development.Brewfile" ]
  [ -s "packages/npm/javascript.npmfile" ]
}

@test "symlink management functions work" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/symlinks.sh
    
    # Test that symlink functions exist
    declare -f setup_symlinks > /dev/null
  "
  [ "$status" -eq 0 ]
}

@test "vscode extension management functions work" {
  run bash -c "
    export MEOW='$(pwd)'
    source lib/core/ui.sh
    source lib/package/vscode.sh
    
    # Test that vscode functions exist
    declare -f install_vscode_extensions > /dev/null
    declare -f update_vscode_extensions > /dev/null
  "
  [ "$status" -eq 0 ]
}