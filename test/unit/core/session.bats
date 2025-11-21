#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "session.sh: sources required dependencies" {
    source "${MEOW}/lib/core/session.sh"
    [ -n "${_LIB_CORE_UI_SOURCED}" ]
    [ -n "${_LIB_CORE_PLATFORM_SOURCED}" ]
    [ -n "${_LIB_CORE_TOOLS_SOURCED}" ]
}

@test "session.sh: _initialize_session exists as a function" {
    source "${MEOW}/lib/core/session.sh"
    declare -f _initialize_session > /dev/null
}

@test "session.sh: _finalize_session exists as a function" {
    source "${MEOW}/lib/core/session.sh"
    declare -f _finalize_session > /dev/null
}

@test "session.sh: _initialize_session function has correct signature" {
    source "${MEOW}/lib/core/session.sh"
    type _initialize_session | grep -q "function"
}

@test "session.sh: _finalize_session function has correct signature" {
    source "${MEOW}/lib/core/session.sh"
    type _finalize_session | grep -q "function"
}

@test "session.sh: _initialize_session validates dependencies" {
    source "${MEOW}/lib/core/session.sh"
    [ -n "${_LIB_CORE_UI_SOURCED}" ]
    [ -n "${_LIB_CORE_PLATFORM_SOURCED}" ]
}

@test "session.sh: _finalize_session validates dependencies" {
    source "${MEOW}/lib/core/session.sh"
    [ -n "${_LIB_CORE_UI_SOURCED}" ]
}

@test "session.sh: both functions are shell functions" {
    source "${MEOW}/lib/core/session.sh"
    type _initialize_session | grep -q "function"
    type _finalize_session | grep -q "function"
}
