#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    export MEOW_COMPONENTS_DIR="$TEST_TEMP_DIR/components"
    export MEOW_PRESETS_DIR="$TEST_TEMP_DIR/presets"
    mkdir -p "$MEOW_COMPONENTS_DIR" "$MEOW_PRESETS_DIR"
}

teardown() {
    teardown_test_env
}

@test "common.sh: reset_package_update_cache clears cache" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE="test::package"
    reset_package_update_cache
    [ -z "$MEOW_PACKAGE_UPDATE_CACHE" ]
}

@test "common.sh: _package_update_key generates correct key format" {
    source "${MEOW}/lib/package/common.sh"
    
    result=$(_package_update_key "npm" "express")
    [ "$result" = "npm::express" ]
}

@test "common.sh: _package_update_cache_contains returns false for empty cache" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    run _package_update_cache_contains "npm" "express"
    assert_failure
}

@test "common.sh: _package_update_cache_add adds entry to cache" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "express"
    
    echo "$MEOW_PACKAGE_UPDATE_CACHE" | grep -q "npm::express"
}

@test "common.sh: _package_update_cache_contains finds added entry" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "express"
    
    run _package_update_cache_contains "npm" "express"
    assert_success
}

@test "common.sh: _package_update_cache_add handles multiple entries" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "express"
    _package_update_cache_add "pip" "flask"
    _package_update_cache_add "cargo" "ripgrep"
    
    echo "$MEOW_PACKAGE_UPDATE_CACHE" | grep -q "npm::express"
    echo "$MEOW_PACKAGE_UPDATE_CACHE" | grep -q "pip::flask"
    echo "$MEOW_PACKAGE_UPDATE_CACHE" | grep -q "cargo::ripgrep"
}

@test "common.sh: _package_update_cache_contains distinguishes between different packages" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "express"
    
    run _package_update_cache_contains "npm" "express"
    assert_success
    
    run _package_update_cache_contains "npm" "react"
    assert_failure
}

@test "common.sh: _package_update_cache_contains handles same package in different managers" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "typescript"
    
    run _package_update_cache_contains "npm" "typescript"
    assert_success
    
    run _package_update_cache_contains "pipx" "typescript"
    assert_failure
}

@test "common.sh: _package_update_key is consistent" {
    source "${MEOW}/lib/package/common.sh"
    
    result1=$(_package_update_key "apt" "curl")
    result2=$(_package_update_key "apt" "curl")
    
    [ "$result1" = "$result2" ]
}

@test "common.sh: cache operations handle special characters in package names" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "@types/node"
    
    run _package_update_cache_contains "npm" "@types/node"
    assert_success
}

@test "common.sh: cache persists across multiple operations" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "first"
    _package_update_cache_add "npm" "second"
    
    run _package_update_cache_contains "npm" "first"
    assert_success
    run _package_update_cache_contains "npm" "second"
    assert_success
}

@test "common.sh: reset clears all entries" {
    source "${MEOW}/lib/package/common.sh"
    
    MEOW_PACKAGE_UPDATE_CACHE=""
    _package_update_cache_add "npm" "pkg1"
    _package_update_cache_add "pip" "pkg2"
    
    reset_package_update_cache
    
    run _package_update_cache_contains "npm" "pkg1"
    assert_failure
    run _package_update_cache_contains "pip" "pkg2"
    assert_failure
}

@test "config.sh: meow_pm_resolve_for_component returns default managers without preset" {
    source "${MEOW}/lib/package/config.sh"
    
    export MEOW_ACTIVE_PRESET_FILE=""
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
EOF
    
    result=$(meow_pm_resolve_for_component "test")
    [ -n "$result" ]
}

@test "config.sh: meow_pm_should_use_manager returns success for included manager" {
    source "${MEOW}/lib/package/config.sh"
    
    run meow_pm_should_use_manager "apt npm pip" "npm"
    assert_success
}

@test "config.sh: meow_pm_should_use_manager returns failure for excluded manager" {
    source "${MEOW}/lib/package/config.sh"
    
    run meow_pm_should_use_manager "apt pip" "npm"
    assert_failure
}

@test "config.sh: meow_pm_should_use_manager handles empty manager list" {
    source "${MEOW}/lib/package/config.sh"
    
    run meow_pm_should_use_manager "" "npm"
    assert_failure
}

@test "config.sh: meow_pm_should_use_manager handles manager with similar names" {
    source "${MEOW}/lib/package/config.sh"
    
    run meow_pm_should_use_manager "snap" "nap"
    assert_failure
    
    run meow_pm_should_use_manager "snap snapd" "snap"
    assert_success
}

@test "config.sh: meow_pm_resolve_for_component handles component-specific overrides" {
    source "${MEOW}/lib/package/config.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/custom"
    cat > "$MEOW_COMPONENTS_DIR/custom/component.yaml" <<EOF
name: custom
packages:
  - managers:
      include:
        - npm
EOF
    
    result=$(meow_pm_resolve_for_component "custom")
    echo "$result" | grep -q "npm"
}

@test "config.sh: _meow_pkg_match_entry filters by platform correctly" {
    source "${MEOW}/lib/package/config.sh"
    
    json='[{"match":{"platform":"linux"},"managers":{"include":["apt"]}}]'
    
    if [ "$IS_MACOS" = "true" ]; then
        result=$(_meow_pkg_match_entry "$json" "macos" "" "" "")
        [ "$result" = "[]" ]
    else
        result=$(_meow_pkg_match_entry "$json" "linux" "" "" "")
        [ "$result" != "[]" ]
    fi
}

@test "config.sh: meow_pm_should_use_manager handles whitespace correctly" {
    source "${MEOW}/lib/package/config.sh"
    
    run meow_pm_should_use_manager "  npm   pip  " "npm"
    assert_success
}

@test "config.sh: meow_pm_resolve_for_component returns consistent results" {
    source "${MEOW}/lib/package/config.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
EOF
    
    result1=$(meow_pm_resolve_for_component "test")
    result2=$(meow_pm_resolve_for_component "test")
    
    [ "$result1" = "$result2" ]
}
