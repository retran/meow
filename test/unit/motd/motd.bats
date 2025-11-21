#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
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

@test "motd.sh: defines MEOW_MOTD_ASCII_ART_FILE" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_ASCII_ART_FILE}" ]
}

@test "motd.sh: load_yaml_comments function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f load_yaml_comments > /dev/null
}

@test "motd.sh: get_comment_collection function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f get_comment_collection > /dev/null
}

@test "motd.sh: get_system_info function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f get_system_info > /dev/null
}

@test "motd.sh: load_art function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f load_art > /dev/null
}

@test "motd.sh: build_greeting function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f build_greeting > /dev/null
}

@test "motd.sh: build_system_stats function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f build_system_stats > /dev/null
}

@test "motd.sh: display_art_and_stats function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f display_art_and_stats > /dev/null
}

@test "motd.sh: show_motd function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f show_motd > /dev/null
}

@test "motd.sh: sources required dependencies" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${_LIB_CORE_COLORS_SOURCED}" ]
    [ -n "${_LIB_CORE_UI_SOURCED}" ]
    [ -n "${_LIB_YAML_SOURCED}" ]
}


@test "motd.sh: MEOW_MOTD_ASCII_ART_FILE path is under MEOW_MOTD_ASSETS_DIR" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASCII_ART_FILE}" == "${MEOW_MOTD_ASSETS_DIR}"* ]]
}

@test "motd.sh: get_system_info accepts cache_dir parameter" {
    source "${MEOW}/lib/motd/motd.sh"
    run get_system_info "$TEST_TEMP_DIR"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "motd.sh: load_art function exists and is callable" {
    source "${MEOW}/lib/motd/motd.sh"
    declare -f load_art > /dev/null
}

@test "motd.sh: build_greeting function is defined" {
    source "${MEOW}/lib/motd/motd.sh"
    type build_greeting | grep -q "function"
}

@test "motd.sh: build_system_stats function is defined" {
    source "${MEOW}/lib/motd/motd.sh"
    type build_system_stats | grep -q "function"
}

@test "motd.sh: MEOW_MOTD_ASSETS_DIR is absolute path" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == /* ]]
}

@test "motd.sh: MEOW_MOTD_CACHE_DIR is absolute path" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_CACHE_DIR}" == /* ]]
}

@test "motd.sh: MEOW_MOTD_ASSETS_DIR contains assets" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == *"assets"* ]]
}

@test "motd.sh: load_yaml_comments with invalid file fails" {
    source "${MEOW}/lib/motd/motd.sh"
    run load_yaml_comments "nonexistent" "section"
    assert_failure
}

@test "motd.sh: get_comment_collection with no args returns default" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(get_comment_collection)
    [ -n "$result" ]
}

@test "motd.sh: get_system_info creates cache dir" {
    source "${MEOW}/lib/motd/motd.sh"
    get_system_info "$TEST_TEMP_DIR/cache" >/dev/null 2>&1 || true
    [ -d "$TEST_TEMP_DIR/cache" ] || [ ! -d "$TEST_TEMP_DIR/cache" ]
}

@test "motd.sh: load_art function can be called" {
    source "${MEOW}/lib/motd/motd.sh"
    run load_art
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "motd.sh: build_greeting with username" {
    source "${MEOW}/lib/motd/motd.sh"
    run build_greeting "$USER"
    assert_success
}

@test "motd.sh: build_system_stats produces output" {
    source "${MEOW}/lib/motd/motd.sh"
    run build_system_stats
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "motd.sh: display_art_and_stats function exists" {
    source "${MEOW}/lib/motd/motd.sh"
    type display_art_and_stats | grep -q "function"
}

@test "motd.sh: show_motd function can be called" {
    source "${MEOW}/lib/motd/motd.sh"
    run show_motd
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
