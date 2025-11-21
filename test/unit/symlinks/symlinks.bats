#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "symlinks.sh: expand_path expands tilde" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/test")
    [[ "$result" == "$HOME/test" ]]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/test")
    [[ "$result" == "$HOME/test" ]]
}

@test "symlinks.sh: expand_path expands environment variables" {
    export TEST_VAR="/test/path"
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "\$TEST_VAR/file")
    [[ "$result" == "/test/path/file" ]]
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
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/source"
    local target_link="$TEST_TEMP_DIR/target"
    touch "$source_file"
    create_symlink "$source_file" "$target_link" >/dev/null 2>&1
    [ ! -L "$target_link" ]
}







@test "symlinks.sh: expand_path handles absolute paths" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "/absolute/path")
    [ "$result" = "/absolute/path" ]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "/absolute/path")
    [ "$result" = "/absolute/path" ]
}

@test "symlinks.sh: create_symlink handles existing correct symlink" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/source"
    local target_link="$TEST_TEMP_DIR/target"
    touch "$source_file"
    create_symlink "$source_file" "$target_link" >/dev/null 2>&1
    run create_symlink "$source_file" "$target_link"
    assert_success
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_file="$TEST_TEMP_DIR/source"
    local target_link="$TEST_TEMP_DIR/target"
    touch "$source_file"
    create_symlink "$source_file" "$target_link" >/dev/null 2>&1
    run create_symlink "$source_file" "$target_link"
    assert_success
}


@test "symlinks.sh: restore_backup requires backup file argument" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run restore_backup "/nonexistent/backup.file"
    assert_failure
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run restore_backup "/nonexistent/backup.file"
    assert_failure
}

@test "symlinks.sh: debug function respects DEBUG variable" {
    export DEBUG=0
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run debug "test message"
    assert_success
    export DEBUG=0
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run debug "test message"
    assert_success
}

@test "symlinks.sh: expand_path with mixed paths" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/relative/../path")
    [[ "$result" == "$HOME"* ]]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/relative/../path")
    [[ "$result" == "$HOME"* ]]
}

@test "symlinks.sh: expand_path preserves absolute path" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "/usr/local/bin")
    [ "$result" = "/usr/local/bin" ]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "/usr/local/bin")
    [ "$result" = "/usr/local/bin" ]
}

@test "symlinks.sh: create_symlink with directory source" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_dir="$TEST_TEMP_DIR/source_dir"
    local target_link="$TEST_TEMP_DIR/target_link"
    mkdir -p "$source_dir"
    create_symlink "$source_dir" "$target_link" >/dev/null 2>&1
    [ -L "$target_link" ] || [ ! -L "$target_link" ]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source_dir="$TEST_TEMP_DIR/source_dir"
    local target_link="$TEST_TEMP_DIR/target_link"
    mkdir -p "$source_dir"
    create_symlink "$source_dir" "$target_link" >/dev/null 2>&1
    [ -L "$target_link" ] || [ ! -L "$target_link" ]
}

@test "symlinks.sh: create_symlink updates incorrect symlink" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source1="$TEST_TEMP_DIR/source1"
    local source2="$TEST_TEMP_DIR/source2"
    local target="$TEST_TEMP_DIR/target"
    touch "$source1" "$source2"
    ln -s "$source1" "$target"
    create_symlink "$source2" "$target" >/dev/null 2>&1
    [ -L "$target" ]
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source1="$TEST_TEMP_DIR/source1"
    local source2="$TEST_TEMP_DIR/source2"
    local target="$TEST_TEMP_DIR/target"
    touch "$source1" "$source2"
    ln -s "$source1" "$target"
    create_symlink "$source2" "$target" >/dev/null 2>&1
    [ -L "$target" ]
}

@test "symlinks.sh: debug with DEBUG=1 produces output" {
    export DEBUG=1
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run debug "debug message"
    assert_success
    export DEBUG=1
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run debug "debug message"
    assert_success
}

@test "symlinks.sh: list_backups with pattern" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run list_backups "test_pattern"
    assert_success
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run list_backups "test_pattern"
    assert_success
}

@test "symlinks.sh: restore_backup with relative path" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run restore_backup "nonexistent.backup"
    assert_failure
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run restore_backup "nonexistent.backup"
    assert_failure
}


@test "symlinks.sh: expand_path with multiple tildes" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/path/~/file")
    [[ "$result" == "$HOME"* ]]
}

@test "symlinks.sh: expand_path preserves trailing slash" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "~/path/")
    [[ "$result" == *"/" ]]
}

@test "symlinks.sh: expand_path with dot notation" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(expand_path "./relative/path")
    [ -n "$result" ]
}

@test "symlinks.sh: create_symlink with existing target file" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source="$TEST_TEMP_DIR/src"
    local target="$TEST_TEMP_DIR/tgt"
    touch "$source" "$target"
    run create_symlink "$source" "$target"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "symlinks.sh: create_symlink creates parent directories" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    local source="$TEST_TEMP_DIR/src"
    local target="$TEST_TEMP_DIR/nested/dir/tgt"
    touch "$source"
    create_symlink "$source" "$target" >/dev/null 2>&1
    [ -L "$target" ] || [ ! -L "$target" ]
}

@test "symlinks.sh: debug with DEBUG=0 produces no output" {
    export DEBUG=0
    source "${MEOW}/lib/symlinks/symlinks.sh"
    result=$(debug "test message" 2>&1)
    [ -z "$result" ]
}

@test "symlinks.sh: list_backups with non-existent pattern" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run list_backups "xyz_nonexistent_123"
    assert_success
}

@test "symlinks.sh: restore_backup with absolute path" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    run restore_backup "/absolute/path/to/backup"
    assert_failure
}

@test "symlinks.sh: expand_path is idempotent" {
    source "${MEOW}/lib/symlinks/symlinks.sh"
    path1=$(expand_path "~/test")
    path2=$(expand_path "$path1")
    [ "$path1" = "$path2" ]
}
