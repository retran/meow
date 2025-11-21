#!/usr/bin/env bats
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Unit tests for lib/core/platform.sh

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "platform.sh: get_platform returns valid platform" {
    source "${MEOW}/lib/core/platform.sh"
    run get_platform
    assert_success
    [[ "${output}" =~ ^(macos|linux|unknown)$ ]]
    source "${MEOW}/lib/core/platform.sh"
    run get_platform
    assert_success
    [[ "${output}" =~ ^(macos|linux|unknown)$ ]]
}

@test "platform.sh: get_platform returns macos on Darwin" {
    if [ "$(uname -s)" = "Darwin" ]; then
        source "${MEOW}/lib/core/platform.sh"
        run get_platform
        assert_success
        assert_equal "${output}" "macos"
    else
        skip "Not running on macOS"
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        source "${MEOW}/lib/core/platform.sh"
        run get_platform
        assert_success
        assert_equal "${output}" "macos"
    else
        skip "Not running on macOS"
    fi
}

@test "platform.sh: get_platform returns linux on Linux" {
    if [ "$(uname -s)" = "Linux" ]; then
        source "${MEOW}/lib/core/platform.sh"
        run get_platform
        assert_success
        assert_equal "${output}" "linux"
    else
        skip "Not running on Linux"
    fi
    if [ "$(uname -s)" = "Linux" ]; then
        source "${MEOW}/lib/core/platform.sh"
        run get_platform
        assert_success
        assert_equal "${output}" "linux"
    else
        skip "Not running on Linux"
    fi
}

@test "platform.sh: IS_MACOS is set correctly" {
    source "${MEOW}/lib/core/platform.sh"
    if [ "$(uname -s)" = "Darwin" ]; then
        assert_equal "${IS_MACOS}" "true"
    else
        assert_equal "${IS_MACOS}" "false"
    fi
    source "${MEOW}/lib/core/platform.sh"
    if [ "$(uname -s)" = "Darwin" ]; then
        assert_equal "${IS_MACOS}" "true"
    else
        assert_equal "${IS_MACOS}" "false"
    fi
}

@test "platform.sh: MEOW_OS_ID is set" {
    source "${MEOW}/lib/core/platform.sh"
    [ -n "${MEOW_OS_ID+x}" ]
    source "${MEOW}/lib/core/platform.sh"
    [ -n "${MEOW_OS_ID+x}" ]
}

@test "platform.sh: meow_os_is works with empty argument" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is ""
    assert_failure
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is ""
    assert_failure
}

@test "platform.sh: meow_os_is returns correct result for current OS" {
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_is "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_is "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
}

@test "platform.sh: meow_os_is_like works with empty argument" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is_like ""
    assert_failure
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is_like ""
    assert_failure
}

@test "platform.sh: meow_os_is_like returns true for exact match" {
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_is_like "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_is_like "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
}

@test "platform.sh: meow_os_matches_any with no arguments fails" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_matches_any
    assert_failure
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_matches_any
    assert_failure
}

@test "platform.sh: meow_os_matches_any with current OS succeeds" {
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_matches_any "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
    if [ "$(uname -s)" = "Linux" ] && [ -f "/etc/os-release" ]; then
        source "${MEOW}/lib/core/platform.sh"
        if [ -n "${MEOW_OS_ID}" ]; then
            run meow_os_matches_any "${MEOW_OS_ID}"
            assert_success
        fi
    else
        skip "Not on Linux with /etc/os-release"
    fi
}

@test "platform.sh: IS_ALPINE set correctly on Alpine" {
    source "${MEOW}/lib/core/platform.sh"
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        if [ "${ID}" = "alpine" ]; then
            assert_equal "${IS_ALPINE}" "true"
        fi
    fi
    source "${MEOW}/lib/core/platform.sh"
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        if [ "${ID}" = "alpine" ]; then
            assert_equal "${IS_ALPINE}" "true"
        fi
    fi
}

@test "platform.sh: IS_ARCH set correctly on Arch" {
    source "${MEOW}/lib/core/platform.sh"
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        if [ "${ID}" = "arch" ]; then
            assert_equal "${IS_ARCH}" "true"
        fi
    fi
    source "${MEOW}/lib/core/platform.sh"
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        if [ "${ID}" = "arch" ]; then
            assert_equal "${IS_ARCH}" "true"
        fi
    fi
}

@test "platform.sh: meow_os_is correctly validates OS ID" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is "invalidOS123"
    assert_failure
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is "invalidOS123"
    assert_failure
}


@test "platform.sh: meow_os_matches_any with single invalid argument fails" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_matches_any "invalidOS123"
    assert_failure
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_matches_any "invalidOS123"
    assert_failure
}







@test "platform.sh: get_platform returns one of expected values" {
    source "${MEOW}/lib/core/platform.sh"
    result=$(get_platform)
    [[ "$result" =~ ^(macos|linux|unknown)$ ]]
    source "${MEOW}/lib/core/platform.sh"
    result=$(get_platform)
    [[ "$result" =~ ^(macos|linux|unknown)$ ]]
}

@test "platform.sh: meow_os_is with current OS succeeds" {
    source "${MEOW}/lib/core/platform.sh"
    if [ -n "$MEOW_OS_ID" ]; then
        run meow_os_is "$MEOW_OS_ID"
        assert_success
    else
        skip "MEOW_OS_ID not set"
    fi
    source "${MEOW}/lib/core/platform.sh"
    if [ -n "$MEOW_OS_ID" ]; then
        run meow_os_is "$MEOW_OS_ID"
        assert_success
    else
        skip "MEOW_OS_ID not set"
    fi
}



@test "platform.sh: get_platform output length is reasonable" {
    source "${MEOW}/lib/core/platform.sh"
    result=$(get_platform)
    [ "${#result}" -lt 50 ]
}

@test "platform.sh: get_platform called twice returns same result" {
    source "${MEOW}/lib/core/platform.sh"
    result1=$(get_platform)
    result2=$(get_platform)
    [ "$result1" = "$result2" ]
}

@test "platform.sh: meow_os_is with empty string" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is ""
    assert_failure
}

@test "platform.sh: meow_os_is with whitespace" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_is "   "
    assert_failure
}

@test "platform.sh: meow_os_matches_any with no arguments" {
    source "${MEOW}/lib/core/platform.sh"
    run meow_os_matches_any
    assert_failure
}



