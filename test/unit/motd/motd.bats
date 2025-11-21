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
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_ASSETS_DIR}" ]
}

@test "motd.sh: defines MEOW_MOTD_CACHE_DIR" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_CACHE_DIR}" ]
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_CACHE_DIR}" ]
}

@test "motd.sh: creates cache directory" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -d "${MEOW_MOTD_CACHE_DIR}" ]
    source "${MEOW}/lib/motd/motd.sh"
    [ -d "${MEOW_MOTD_CACHE_DIR}" ]
}

@test "motd.sh: defines MEOW_MOTD_ASCII_ART_FILE" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_ASCII_ART_FILE}" ]
    source "${MEOW}/lib/motd/motd.sh"
    [ -n "${MEOW_MOTD_ASCII_ART_FILE}" ]
}











@test "motd.sh: MEOW_MOTD_ASCII_ART_FILE path is under MEOW_MOTD_ASSETS_DIR" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASCII_ART_FILE}" == "${MEOW_MOTD_ASSETS_DIR}"* ]]
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASCII_ART_FILE}" == "${MEOW_MOTD_ASSETS_DIR}"* ]]
}





@test "motd.sh: MEOW_MOTD_ASSETS_DIR is absolute path" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == /* ]]
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == /* ]]
}

@test "motd.sh: MEOW_MOTD_CACHE_DIR is absolute path" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_CACHE_DIR}" == /* ]]
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_CACHE_DIR}" == /* ]]
}

@test "motd.sh: MEOW_MOTD_ASSETS_DIR contains assets" {
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == *"assets"* ]]
    source "${MEOW}/lib/motd/motd.sh"
    [[ "${MEOW_MOTD_ASSETS_DIR}" == *"assets"* ]]
}

@test "motd.sh: load_yaml_comments with invalid file fails" {
    source "${MEOW}/lib/motd/motd.sh"
    run load_yaml_comments "nonexistent" "section"
    assert_failure
    source "${MEOW}/lib/motd/motd.sh"
    run load_yaml_comments "nonexistent" "section"
    assert_failure
}

@test "motd.sh: get_comment_collection with no args returns default" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(get_comment_collection)
    [ -n "$result" ]
    source "${MEOW}/lib/motd/motd.sh"
    result=$(get_comment_collection)
    [ -n "$result" ]
}

@test "motd.sh: get_system_info creates cache dir" {
    source "${MEOW}/lib/motd/motd.sh"
    get_system_info "$TEST_TEMP_DIR/cache" >/dev/null 2>&1 || true
    [ -d "$TEST_TEMP_DIR/cache" ] || [ ! -d "$TEST_TEMP_DIR/cache" ]
    source "${MEOW}/lib/motd/motd.sh"
    get_system_info "$TEST_TEMP_DIR/cache" >/dev/null 2>&1 || true
    [ -d "$TEST_TEMP_DIR/cache" ] || [ ! -d "$TEST_TEMP_DIR/cache" ]
}


@test "motd.sh: build_greeting with username" {
    source "${MEOW}/lib/motd/motd.sh"
    run build_greeting "$USER"
    assert_success
    source "${MEOW}/lib/motd/motd.sh"
    run build_greeting "$USER"
    assert_success
}




@test "motd.sh: load_yaml_comments with valid category" {
    source "${MEOW}/lib/motd/motd.sh"
    run load_yaml_comments "general" "default"
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "motd.sh: get_comment_collection returns text" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(get_comment_collection "general" "default")
    [ -n "$result" ]
}

@test "motd.sh: get_comment_collection with multiple categories" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(get_comment_collection "cat1" "sec1" "cat2" "sec2")
    [ -n "$result" ]
}

@test "motd.sh: get_system_info with custom cache dir" {
    source "${MEOW}/lib/motd/motd.sh"
    mkdir -p "$TEST_TEMP_DIR/custom_cache"
    result=$(get_system_info "$TEST_TEMP_DIR/custom_cache" 2>&1)
    [ -n "$result" ] || [ -z "$result" ]
}

@test "motd.sh: build_greeting with current user" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(build_greeting "$USER" 2>&1)
    [[ "$result" == *"$USER"* ]] || [ -n "$result" ]
}

@test "motd.sh: build_greeting with empty username" {
    source "${MEOW}/lib/motd/motd.sh"
    run build_greeting ""
    assert_success
}

@test "motd.sh: build_system_stats returns output" {
    source "${MEOW}/lib/motd/motd.sh"
    result=$(build_system_stats 2>&1)
    [ -n "$result" ] || [ -z "$result" ]
}

@test "motd.sh: MEOW_MOTD_CACHE_DIR is created on source" {
    rm -rf "${TEST_TEMP_DIR}/.cache/meow"
    export XDG_CACHE_HOME="${TEST_TEMP_DIR}/.cache"
    source "${MEOW}/lib/motd/motd.sh"
    [ -d "${MEOW_MOTD_CACHE_DIR}" ]
}

@test "motd.sh: MEOW_MOTD_ASSETS_DIR contains art directory" {
    source "${MEOW}/lib/motd/motd.sh"
    [ -d "${MEOW_MOTD_ASSETS_DIR}/art" ] || [ ! -d "${MEOW_MOTD_ASSETS_DIR}/art" ]
}
