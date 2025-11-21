#!/usr/bin/env bats
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Unit tests for lib/core/bash.sh

load '../../test_helper'

setup() {
    setup_test_env
    source "${MEOW}/lib/core/ui.sh"
}

teardown() {
    teardown_test_env
}

@test "bash.sh: get_bash_version_number returns a number" {
    source "${MEOW}/lib/core/bash.sh"
    run get_bash_version_number
    assert_success
    [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "bash.sh: get_bash_version_number returns sensible value" {
    source "${MEOW}/lib/core/bash.sh"
    run get_bash_version_number
    assert_success
    [ "${output}" -ge 302 ]
    [ "${output}" -lt 1000 ]
}

@test "bash.sh: check_bash_version with current version succeeds" {
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major" 0
    assert_success
}

@test "bash.sh: check_bash_version 3 2 succeeds (minimum requirement)" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 3 2
    assert_success
}

@test "bash.sh: check_bash_version with impossible version fails" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 99 99
    assert_failure
}

@test "bash.sh: show_bash_version_info produces output" {
    source "${MEOW}/lib/core/bash.sh"
    run show_bash_version_info
    assert_success
    assert_output --partial "Bash version:"
}

@test "bash.sh: show_bash_version_info mentions bash version" {
    source "${MEOW}/lib/core/bash.sh"
    run show_bash_version_info
    assert_success
    assert_output --partial "${BASH_VERSION}"
}

@test "bash.sh: warn_bash_compatibility produces output for bash 3.x" {
    source "${MEOW}/lib/core/bash.sh"
    # Only test if we're actually on Bash 3.x
    if ! check_bash_version 4 0; then
        run warn_bash_compatibility
        assert_success
        assert_output --partial "compatibility"
    fi
}

@test "bash.sh: warn_bash_compatibility runs without error on bash 4+" {
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    assert_success
}

@test "bash.sh: get_bash_version_number handles different bash versions" {
    source "${MEOW}/lib/core/bash.sh"
    run get_bash_version_number
    assert_success
    [ "${output}" -gt 0 ]
}

@test "bash.sh: check_bash_version validates major version correctly" {
    source "${MEOW}/lib/core/bash.sh"
    local current_major="${BASH_VERSION%%.*}"
    run check_bash_version "$current_major" 0
    assert_success
}
