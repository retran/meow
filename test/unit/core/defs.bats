#!/usr/bin/env bats
# MIT License
#
# Copyright (c) 2025 Andrew Vasilyev <me@retran.me>
#
# Unit tests for lib/core/defs.sh

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
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

@test "defs.sh: all directory constants are absolute paths" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_PRESETS_DIR}" == /* ]]
    [[ "${MEOW_COMPONENTS_DIR}" == /* ]]
    [[ "${MEOW_INSTALLED_PRESETS_DIR}" == /* ]]
}

@test "defs.sh: MEOW_DOWNLOADS_DIR contains .downloads" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_DOWNLOADS_DIR}" == *".downloads"* ]]
}

@test "defs.sh: MEOW_INSTALLED_COMPONENTS_DIR contains .installed" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_INSTALLED_COMPONENTS_DIR}" == *".installed"* ]]
}

@test "defs.sh: MEOW_PRESETS_DIR ends with presets" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_PRESETS_DIR}" == *"presets" ]]
}

@test "defs.sh: MEOW_COMPONENTS_DIR ends with components" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_COMPONENTS_DIR}" == *"components" ]]
}

@test "defs.sh: MEOW_INSTALLED_PRESETS_DIR path structure" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_INSTALLED_PRESETS_DIR}" == *".installed/presets" ]]
}

@test "defs.sh: MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR structure" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR}" == *".installed/components.manual" ]]
}

@test "defs.sh: all paths start with MEOW variable" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_PRESETS_DIR}" == "${MEOW}"* ]]
    [[ "${MEOW_COMPONENTS_DIR}" == "${MEOW}"* ]]
}

@test "defs.sh: MEOW_DOWNLOADS_DIR is absolute path" {
    source "${MEOW}/lib/core/defs.sh"
    [[ "${MEOW_DOWNLOADS_DIR}" == /* ]]
}
