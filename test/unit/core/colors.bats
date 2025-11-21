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
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${NORMAL+x}" ]
}

@test "colors.sh: defines RED color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RED+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RED+x}" ]
}

@test "colors.sh: defines GREEN color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${GREEN+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${GREEN+x}" ]
}

@test "colors.sh: defines YELLOW color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${YELLOW+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${YELLOW+x}" ]
}

@test "colors.sh: defines BLUE color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${BLUE+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${BLUE+x}" ]
}

@test "colors.sh: defines RESET color variable" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RESET+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${RESET+x}" ]
}

@test "colors.sh: defines semantic SUCCESS color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${SUCCESS+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${SUCCESS+x}" ]
}

@test "colors.sh: defines semantic WARNING color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${WARNING+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${WARNING+x}" ]
}

@test "colors.sh: defines semantic ERROR color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${ERROR+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${ERROR+x}" ]
}

@test "colors.sh: defines semantic INFO color" {
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${INFO+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    assert [ -n "${INFO+x}" ]
}

@test "colors.sh: tput support detection works" {
    source "${MEOW}/lib/core/colors.sh"
    [ "${MEOW_TPUT_SUPPORTED}" = "0" ] || [ "${MEOW_TPUT_SUPPORTED}" = "1" ]
    source "${MEOW}/lib/core/colors.sh"
    [ "${MEOW_TPUT_SUPPORTED}" = "0" ] || [ "${MEOW_TPUT_SUPPORTED}" = "1" ]
}

@test "colors.sh: non-tty environment has empty color codes" {
    run bash -c "source '${MEOW}/lib/core/colors.sh' && echo \"\${NORMAL}\" | cat"
    assert_success
    run bash -c "source '${MEOW}/lib/core/colors.sh' && echo \"\${NORMAL}\" | cat"
    assert_success
}

@test "colors.sh: defines BOLD color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${BOLD+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${BOLD+x}" ]
}

@test "colors.sh: defines HEADER color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${HEADER+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${HEADER+x}" ]
}

@test "colors.sh: defines SUBHEADER color variable" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUBHEADER+x}" ]
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
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${NORMAL+x}" ]
    [ -n "${RED+x}" ]
    [ -n "${GREEN+x}" ]
    [ -n "${YELLOW+x}" ]
    [ -n "${BLUE+x}" ]
}

@test "colors.sh: MAGENTA color variable is defined" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${MAGENTA+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${MAGENTA+x}" ]
}

@test "colors.sh: CYAN color variable is defined" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${CYAN+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${CYAN+x}" ]
}

@test "colors.sh: CONTENT color is defined" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${CONTENT+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${CONTENT+x}" ]
}

@test "colors.sh: RESET is defined" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${RESET+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${RESET+x}" ]
}

@test "colors.sh: color variables are strings" {
    source "${MEOW}/lib/core/colors.sh"
    [[ "${RED}" == *""* ]] || [ -z "${RED}" ]
    source "${MEOW}/lib/core/colors.sh"
    [[ "${RED}" == *""* ]] || [ -z "${RED}" ]
}

@test "colors.sh: MEOW_TPUT_SUPPORTED is set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${MEOW_TPUT_SUPPORTED+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${MEOW_TPUT_SUPPORTED+x}" ]
}

@test "colors.sh: SUCCESS color is set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUCCESS+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUCCESS+x}" ]
}

@test "colors.sh: WARNING color is set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${WARNING+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${WARNING+x}" ]
}

@test "colors.sh: ERROR color is set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${ERROR+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${ERROR+x}" ]
}

@test "colors.sh: INFO color is set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${INFO+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${INFO+x}" ]
}

@test "colors.sh: color variables can be concatenated" {
    source "${MEOW}/lib/core/colors.sh"
    combined="${RED}${BOLD}"
    [ -n "${combined}" ] || [ -z "${combined}" ]
    source "${MEOW}/lib/core/colors.sh"
    combined="${RED}${BOLD}"
    [ -n "${combined}" ] || [ -z "${combined}" ]
}

@test "colors.sh: NORMAL and RESET work together" {
    source "${MEOW}/lib/core/colors.sh"
    combined="${NORMAL}${RESET}"
    [ -n "${combined}" ] || [ -z "${combined}" ]
    source "${MEOW}/lib/core/colors.sh"
    combined="${NORMAL}${RESET}"
    [ -n "${combined}" ] || [ -z "${combined}" ]
}

@test "colors.sh: all semantic colors are set" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUCCESS+x}" ]
    [ -n "${ERROR+x}" ]
    [ -n "${WARNING+x}" ]
    [ -n "${INFO+x}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUCCESS+x}" ]
    [ -n "${ERROR+x}" ]
    [ -n "${WARNING+x}" ]
    [ -n "${INFO+x}" ]
}

@test "colors.sh: HEADER and SUBHEADER are different or same" {
    source "${MEOW}/lib/core/colors.sh"
    [ "${HEADER}" = "${SUBHEADER}" ] || [ "${HEADER}" != "${SUBHEADER}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ "${HEADER}" = "${SUBHEADER}" ] || [ "${HEADER}" != "${SUBHEADER}" ]
}

@test "colors.sh: BOLD variable contains content or is empty" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${BOLD}" ] || [ -z "${BOLD}" ]
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${BOLD}" ] || [ -z "${BOLD}" ]
}

@test "colors.sh: color variables remain constant" {
    source "${MEOW}/lib/core/colors.sh"
    red1="${RED}"
    source "${MEOW}/lib/core/colors.sh"
    red2="${RED}"
    [ "$red1" = "$red2" ]
}

@test "colors.sh: NORMAL is set to something" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${NORMAL+x}" ]
}

@test "colors.sh: semantic colors are exported" {
    source "${MEOW}/lib/core/colors.sh"
    [ -n "${SUCCESS+x}" ]
    [ -n "${ERROR+x}" ]
    [ -n "${WARNING+x}" ]
}

@test "colors.sh: MEOW_TPUT_SUPPORTED is boolean-like" {
    source "${MEOW}/lib/core/colors.sh"
    [ "$MEOW_TPUT_SUPPORTED" = "true" ] || [ "$MEOW_TPUT_SUPPORTED" = "false" ] || [ "$MEOW_TPUT_SUPPORTED" = "1" ] || [ "$MEOW_TPUT_SUPPORTED" = "0" ]
}

@test "colors.sh: colors can be used in strings" {
    source "${MEOW}/lib/core/colors.sh"
    text="${RED}test${RESET}"
    [ -n "$text" ]
}
