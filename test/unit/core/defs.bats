#!/usr/bin/env bats
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Unit tests for lib/core/defs.sh

load '../../test_helper'

setup() {
    setup_test_env
    # MEOW is already set by test_helper
}

teardown() {
    teardown_test_env
}

@test "defs.sh: sourcing sets _LIB_DEFS_SOURCED" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${_LIB_DEFS_SOURCED}" ]
}

@test "defs.sh: sourcing twice doesn't cause errors" {
    source "${MEOW}/lib/core/defs.sh"
    source "${MEOW}/lib/core/defs.sh"
    assert [ "${_LIB_DEFS_SOURCED}" = "1" ]
}

@test "defs.sh: defines MEOW_PRESETS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_PRESETS_DIR}" ]
    assert_equal "${MEOW_PRESETS_DIR}" "${MEOW}/presets"
}

@test "defs.sh: defines MEOW_COMPONENTS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_COMPONENTS_DIR}" ]
    assert_equal "${MEOW_COMPONENTS_DIR}" "${MEOW}/components"
}

@test "defs.sh: defines MEOW_INSTALLED_PRESETS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_INSTALLED_PRESETS_DIR}" ]
    assert_equal "${MEOW_INSTALLED_PRESETS_DIR}" "${MEOW}/.installed/presets"
}

@test "defs.sh: defines MEOW_INSTALLED_COMPONENTS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_INSTALLED_COMPONENTS_DIR}" ]
    assert_equal "${MEOW_INSTALLED_COMPONENTS_DIR}" "${MEOW}/.installed/components"
}

@test "defs.sh: defines MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}" ]
    assert_equal "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}" "${MEOW}/.installed/components-manual"
}

@test "defs.sh: defines MEOW_DOWNLOADS_DIR" {
    source "${MEOW}/lib/core/defs.sh"
    assert [ -n "${MEOW_DOWNLOADS_DIR}" ]
    assert_equal "${MEOW_DOWNLOADS_DIR}" "${MEOW}/.downloads"
}

@test "defs.sh: all directory constants use MEOW variable" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_PRESETS_DIR}" == "${MEOW}"* ]]
    [[ "${MEOW_COMPONENTS_DIR}" == "${MEOW}"* ]]
    [[ "${MEOW_INSTALLED_PRESETS_DIR}" == "${MEOW}"* ]]
}
