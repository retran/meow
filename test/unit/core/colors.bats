#!/usr/bin/env bats
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Unit tests for lib/core/colors.sh

load '../../test_helper'

setup() {
    setup_test_env
    export TERM=dumb
}

teardown() {
    teardown_test_env
}

@test "colors.sh: defines NORMAL color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${NORMAL+x}" ]
}

@test "colors.sh: defines RED color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RED+x}" ]
}

@test "colors.sh: defines GREEN color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${GREEN+x}" ]
}

@test "colors.sh: defines YELLOW color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${YELLOW+x}" ]
}

@test "colors.sh: defines BLUE color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${BLUE+x}" ]
}

@test "colors.sh: defines RESET color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RESET+x}" ]
}

@test "colors.sh: defines semantic SUCCESS color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${SUCCESS+x}" ]
}

@test "colors.sh: defines semantic WARNING color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${WARNING+x}" ]
}

@test "colors.sh: defines semantic ERROR color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${ERROR+x}" ]
}

@test "colors.sh: defines semantic INFO color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${INFO+x}" ]
}

@test "colors.sh: tput support detection works" {
    source "${MEOW}/lib/core/colors.sh"
    [ "${MEOW_TPUT_SUPPORTED}" = "0" ] || [ "${MEOW_TPUT_SUPPORTED}" = "1" ]
}

@test "colors.sh: non-tty environment has empty color codes" {
    run bash -c "source '${MEOW}/lib/core/colors.sh' && echo \"\${NORMAL}\" | cat"
    assert_success
}

@test "colors.sh: defines BOLD color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${BOLD+x}" ]
}

@test "colors.sh: defines HEADER color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${HEADER+x}" ]
}

@test "colors.sh: defines SUBHEADER color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUBHEADER+x}" ]
}

@test "colors.sh: all color variables are exported" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${NORMAL+x}" ]
    [ -n "${RED+x}" ]
    [ -n "${GREEN+x}" ]
    [ -n "${YELLOW+x}" ]
    [ -n "${BLUE+x}" ]
}
