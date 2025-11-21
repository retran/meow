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
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major" 0
    assert_success
}

@test "bash.sh: check_bash_version 3 2 succeeds (minimum requirement)" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 3 2
    assert_success
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 3 2
    assert_success
}

@test "bash.sh: check_bash_version with impossible version fails" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 99 99
    assert_failure
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 99 99
    assert_failure
}

@test "bash.sh: show_bash_version_info produces output" {
    source "${MEOW}/lib/core/bash.sh"
    run show_bash_version_info
    assert_success
    assert_output --partial "Bash version:"
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
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    assert_success
}

@test "bash.sh: get_bash_version_number handles different bash versions" {
    source "${MEOW}/lib/core/bash.sh"
    run get_bash_version_number
    assert_success
    [ "${output}" -gt 0 ]
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
    source "${MEOW}/lib/core/bash.sh"
    local current_major="${BASH_VERSION%%.*}"
    run check_bash_version "$current_major" 0
    assert_success
}

@test "bash.sh: check_bash_version with exact version match" {
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    local minor=$(echo "${BASH_VERSION}" | cut -d'.' -f2)
    run check_bash_version "$major" "$minor"
    assert_success
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    local minor=$(echo "${BASH_VERSION}" | cut -d'.' -f2)
    run check_bash_version "$major" "$minor"
    assert_success
}

@test "bash.sh: check_bash_version fails with too high major version" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 99 0
    assert_failure
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 99 0
    assert_failure
}

@test "bash.sh: check_bash_version fails with too high minor version" {
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major" 999
    assert_failure
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major" 999
    assert_failure
}

@test "bash.sh: show_bash_version_info contains version string" {
    source "${MEOW}/lib/core/bash.sh"
    result=$(show_bash_version_info 2>&1)
    [[ "$result" == *"$BASH_VERSION"* ]]
    source "${MEOW}/lib/core/bash.sh"
    result=$(show_bash_version_info 2>&1)
    [[ "$result" == *"$BASH_VERSION"* ]]
}

@test "bash.sh: warn_bash_compatibility runs on any bash version" {
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    assert_success
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    assert_success
}

@test "bash.sh: get_bash_version_number is numeric" {
    source "${MEOW}/lib/core/bash.sh"
    result=$(get_bash_version_number)
    [[ "$result" =~ ^[0-9]+$ ]]
    source "${MEOW}/lib/core/bash.sh"
    result=$(get_bash_version_number)
    [[ "$result" =~ ^[0-9]+$ ]]
}

@test "bash.sh: get_bash_version_number returns at least 302" {
    source "${MEOW}/lib/core/bash.sh"
    result=$(get_bash_version_number)
    [ "$result" -ge 302 ]
    source "${MEOW}/lib/core/bash.sh"
    result=$(get_bash_version_number)
    [ "$result" -ge 302 ]
}


@test "bash.sh: check_bash_version with current major version succeeds" {
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major"
    assert_success
    source "${MEOW}/lib/core/bash.sh"
    local major="${BASH_VERSION%%.*}"
    run check_bash_version "$major"
    assert_success
}

@test "bash.sh: get_bash_version_number is consistent" {
    source "${MEOW}/lib/core/bash.sh"
    local v1=$(get_bash_version_number)
    local v2=$(get_bash_version_number)
    [ "$v1" = "$v2" ]
    source "${MEOW}/lib/core/bash.sh"
    local v1=$(get_bash_version_number)
    local v2=$(get_bash_version_number)
    [ "$v1" = "$v2" ]
}

@test "bash.sh: warn_bash_compatibility produces consistent output" {
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    run warn_bash_compatibility
    assert_success
    source "${MEOW}/lib/core/bash.sh"
    run warn_bash_compatibility
    run warn_bash_compatibility
    assert_success
}

@test "bash.sh: show_bash_version_info contains bash keyword" {
    source "${MEOW}/lib/core/bash.sh"
    result=$(show_bash_version_info 2>&1)
    [[ "$result" =~ [Bb]ash ]] || [ -n "$result" ]
    source "${MEOW}/lib/core/bash.sh"
    result=$(show_bash_version_info 2>&1)
    [[ "$result" =~ [Bb]ash ]] || [ -n "$result" ]
}

@test "bash.sh: check_bash_version 0 0 succeeds" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 0 0
    assert_success
}

@test "bash.sh: check_bash_version handles negative major version" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version -1 0
    assert_success
}

@test "bash.sh: check_bash_version handles negative minor version" {
    source "${MEOW}/lib/core/bash.sh"
    run check_bash_version 3 -1
    assert_success
}

@test "bash.sh: get_bash_version_number handles BASH_VERSION correctly" {
    source "${MEOW}/lib/core/bash.sh"
    local version=$(get_bash_version_number)
    [ "$version" -gt 0 ]
}

@test "bash.sh: show_bash_version_info output is not empty" {
    source "${MEOW}/lib/core/bash.sh"
    result=$(show_bash_version_info 2>&1)
    [ -n "$result" ]
}


