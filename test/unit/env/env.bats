#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "env.sh: sourcing sets _MEOW_CORE_ENV_SOURCED" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${_MEOW_CORE_ENV_SOURCED}" ]
}

@test "env.sh: sourcing twice doesn't cause errors" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    source "${MEOW}/lib/env/env.sh"
    [ "${_MEOW_CORE_ENV_SOURCED}" = "1" ]
}

@test "env.sh: MEOW variable is set after sourcing" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${MEOW}" ]
}

@test "env.sh: sets XDG_CONFIG_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CONFIG_HOME}" ]
}

@test "env.sh: sets LANG variable" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LANG}" ]
}
