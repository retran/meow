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
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${MEOW}" ]
}

@test "env.sh: sets XDG_CONFIG_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CONFIG_HOME}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CONFIG_HOME}" ]
}

@test "env.sh: sets LANG variable" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LANG}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LANG}" ]
}

@test "env.sh: sets XDG_CACHE_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CACHE_HOME}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_CACHE_HOME}" ]
}

@test "env.sh: sets XDG_DATA_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_DATA_HOME}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_DATA_HOME}" ]
}

@test "env.sh: sets XDG_STATE_HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_STATE_HOME}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${XDG_STATE_HOME}" ]
}

@test "env.sh: sets LC_ALL variable" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LC_ALL}" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ -n "${LC_ALL}" ]
}




@test "env.sh: XDG variables use HOME correctly" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == "$HOME"* ]]
    [[ "${XDG_CACHE_HOME}" == "$HOME"* ]]
    [[ "${XDG_DATA_HOME}" == "$HOME"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == "$HOME"* ]]
    [[ "${XDG_CACHE_HOME}" == "$HOME"* ]]
    [[ "${XDG_DATA_HOME}" == "$HOME"* ]]
}

@test "env.sh: LANG is set to UTF-8" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${LANG}" == *"UTF-8"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${LANG}" == *"UTF-8"* ]]
}

@test "env.sh: LC_ALL is set to UTF-8" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${LC_ALL}" == *"UTF-8"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${LC_ALL}" == *"UTF-8"* ]]
}

@test "env.sh: MEOW is absolute path" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${MEOW}" == /* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${MEOW}" == /* ]]
}

@test "env.sh: XDG_CONFIG_HOME is absolute path" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == /* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == /* ]]
}

@test "env.sh: XDG_CACHE_HOME is absolute path" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CACHE_HOME}" == /* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CACHE_HOME}" == /* ]]
}

@test "env.sh: XDG_DATA_HOME is absolute path" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_DATA_HOME}" == /* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_DATA_HOME}" == /* ]]
}

@test "env.sh: XDG_STATE_HOME is absolute path" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_STATE_HOME}" == /* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_STATE_HOME}" == /* ]]
}

@test "env.sh: XDG_CONFIG_HOME contains .config" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == *".config"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == *".config"* ]]
}

@test "env.sh: XDG_CACHE_HOME contains .cache" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CACHE_HOME}" == *".cache"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CACHE_HOME}" == *".cache"* ]]
}

@test "env.sh: XDG_DATA_HOME contains .local/share" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_DATA_HOME}" == *".local/share"* ]]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_DATA_HOME}" == *".local/share"* ]]
}

@test "env.sh: LANG equals en_US.UTF-8" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${LANG}" = "en_US.UTF-8" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${LANG}" = "en_US.UTF-8" ]
}

@test "env.sh: LC_ALL equals en_US.UTF-8" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${LC_ALL}" = "en_US.UTF-8" ]
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${LC_ALL}" = "en_US.UTF-8" ]
}

@test "env.sh: MEOW ends with .meow" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${MEOW}" == *".meow" ]]
}

@test "env.sh: XDG variables don't overlap" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${XDG_CONFIG_HOME}" != "${XDG_CACHE_HOME}" ]
    [ "${XDG_CONFIG_HOME}" != "${XDG_DATA_HOME}" ]
}

@test "env.sh: XDG_STATE_HOME is different from others" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${XDG_STATE_HOME}" != "${XDG_CONFIG_HOME}" ]
    [ "${XDG_STATE_HOME}" != "${XDG_CACHE_HOME}" ]
}

@test "env.sh: LANG and LC_ALL match" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [ "${LANG}" = "${LC_ALL}" ]
}

@test "env.sh: all XDG paths contain HOME" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == *"$HOME"* ]]
    [[ "${XDG_CACHE_HOME}" == *"$HOME"* ]]
    [[ "${XDG_DATA_HOME}" == *"$HOME"* ]]
    [[ "${XDG_STATE_HOME}" == *"$HOME"* ]]
}

@test "env.sh: MEOW variable is not modified on re-source" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    meow1="${MEOW}"
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    meow2="${MEOW}"
    [ "$meow1" = "$meow2" ]
}

@test "env.sh: XDG_CONFIG_HOME ends with .config" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_CONFIG_HOME}" == *".config" ]]
}

@test "env.sh: XDG_DATA_HOME contains share" {
    unset _MEOW_CORE_ENV_SOURCED
    source "${MEOW}/lib/env/env.sh"
    [[ "${XDG_DATA_HOME}" == *"share"* ]]
}
