#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "session.sh: sourcing sets _LIB_CORE_SESSION_SOURCED" {
    source "${MEOW}/lib/core/session.sh"
    [ -n "${_LIB_CORE_SESSION_SOURCED}" ]
}

@test "session.sh: sourcing twice doesn't cause errors" {
    source "${MEOW}/lib/core/session.sh"
    source "${MEOW}/lib/core/session.sh"
    [ "${_LIB_CORE_SESSION_SOURCED}" = "1" ]
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
