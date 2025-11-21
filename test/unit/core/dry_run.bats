#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    source "${MEOW}/lib/core/ui.sh"
}

teardown() {
    teardown_test_env
}

@test "dry_run.sh: is_dry_run returns false by default" {
    export MEOW_DRY_RUN=false
    source "${MEOW}/lib/core/dry_run.sh"
    run is_dry_run
    assert_failure
}

@test "dry_run.sh: is_dry_run returns true when MEOW_DRY_RUN=true" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run is_dry_run
    assert_success
}

@test "dry_run.sh: dry_run_command executes in non-dry-run mode" {
    export MEOW_DRY_RUN=false
    source "${MEOW}/lib/core/dry_run.sh"
    local test_file="$TEST_TEMP_DIR/test_file"
    dry_run_command "touch file" touch "$test_file"
    [ -f "$test_file" ]
}

@test "dry_run.sh: dry_run_command skips execution in dry-run mode" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    local test_file="$TEST_TEMP_DIR/test_file"
    dry_run_command "touch file" touch "$test_file"
    [ ! -f "$test_file" ]
}

@test "dry_run.sh: dry_run_info produces output" {
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_info "test message"
    assert_success
    assert_output --partial "test message"
}

@test "dry_run.sh: dry_run_file_operation returns 0 in dry-run mode" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_file_operation "create_dir" "/some/path"
    assert_success
}

@test "dry_run.sh: dry_run_file_operation returns 1 in normal mode" {
    export MEOW_DRY_RUN=false
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_file_operation "create_dir" "/some/path"
    assert_failure
}

@test "dry_run.sh: dry_run_package_operation works for install" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_package_operation "apt" "install" "package1 package2"
    assert_success
}

@test "dry_run.sh: dry_run_git_operation works for clone" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_git_operation "clone" "/path/to/repo" "https://example.com/repo.git"
    assert_success
}

@test "dry_run.sh: dry_run_script_execution works" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_script_execution "/path/to/script.sh" "my script"
    assert_success
}

@test "dry_run.sh: dry_run_command respects MEOW_DRY_RUN setting" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    local executed=false
    dry_run_command "test" bash -c "executed=true" || true
    [ "$executed" = "false" ]
}

@test "dry_run.sh: dry_run_ui_info produces output in dry-run mode" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_ui_info "test message"
    assert_success
}

@test "dry_run.sh: dry_run_command_info displays command in dry-run" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/dry_run.sh"
    run dry_run_command_info "test command"
    assert_success
}
