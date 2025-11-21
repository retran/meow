#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
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

@test "env.sh: sets XDG_CACHE_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CACHE_HOME}" ]
}

@test "env.sh: sets XDG_DATA_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_DATA_HOME}" ]
}

@test "env.sh: sets XDG_STATE_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_STATE_HOME}" ]
}

@test "env.sh: sets LC_ALL variable" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LC_ALL}" ]
}

@test "env.sh: _meow_set_if_command_exists function exists" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    declare -f _meow_set_if_command_exists > /dev/null
}

@test "env.sh: _meow_source_component_env_scripts function exists" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    declare -f _meow_source_component_env_scripts > /dev/null
}

