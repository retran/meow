#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "motd.sh: sourcing sets _LIB_MOTD_SOURCED" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${_LIB_MOTD_SOURCED}" ]
}

@test "motd.sh: sourcing twice doesn't cause errors" {
    source "${MEOW}/lib/motd/motd.sh"
    source "${MEOW}/lib/motd/motd.sh"
    [ "${_LIB_MOTD_SOURCED}" = "1" ]
}

@test "motd.sh: defines MEOW_MOTD_ASSETS_DIR" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_ASSETS_DIR}" ]
}

@test "motd.sh: defines MEOW_MOTD_CACHE_DIR" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_CACHE_DIR}" ]
}

@test "motd.sh: creates cache directory" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -d "${MEOW_MOTD_CACHE_DIR}" ]
}
