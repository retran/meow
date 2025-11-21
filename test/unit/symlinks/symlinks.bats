#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "symlinks.sh: sourcing sets _LIB_PACKAGE_SYMLINKS_SOURCED" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    [ -n "${_LIB_PACKAGE_SYMLINKS_SOURCED}" ]
}

@test "symlinks.sh: expand_path expands tilde" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/test")
    [[ "$result" == "$HOME/test" ]]
}

@test "symlinks.sh: expand_path expands environment variables" {
    export TEST_VAR="/test/path"
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "\$TEST_VAR/file")
    [[ "$result" == "/test/path/file" ]]
}

@test "symlinks.sh: create_symlink creates symlink" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/source"
    local target_link="$TEST_TEMP_DIR/target"
    touch "$source_file"
    create_symlink "$source_file" "$target_link" >/dev/null 2>&1
    [ -L "$target_link" ]
    [ "$(readlink "$target_link")" = "$source_file" ]
}

@test "symlinks.sh: create_symlink skips if source doesn't exist" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/nonexistent"
    local target_link="$TEST_TEMP_DIR/target"
    run create_symlink "$source_file" "$target_link"
    [ ! -L "$target_link" ]
}

@test "symlinks.sh: create_symlink in dry-run mode doesn't create symlink" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/source"
    local target_link="$TEST_TEMP_DIR/target"
    touch "$source_file"
    create_symlink "$source_file" "$target_link" >/dev/null 2>&1
    [ ! -L "$target_link" ]
}

@test "symlinks.sh: debug function exists" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    declare -f debug > /dev/null
}

@test "symlinks.sh: list_backups function exists" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    declare -f list_backups > /dev/null
}

@test "symlinks.sh: restore_backup function exists" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    declare -f restore_backup > /dev/null
}

@test "symlinks.sh: setup_component_symlinks_from_file function exists" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    declare -f setup_component_symlinks_from_file > /dev/null
}

@test "symlinks.sh: sources required dependencies" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    [ -n "${_LIB_CORE_UI_SOURCED}" ]
    [ -n "${_LIB_DEFS_SOURCED}" ]
    [ -n "${_LIB_CORE_DRY_RUN_SOURCED}" ]
}

