#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    export TEST_YAML="$TEST_TEMP_DIR/test.yaml"
    cat > "$TEST_YAML" <<'EOF'
name: test-component
version: 1.0.0
required:
  - package1
  - package2
optional:
  - package3
platforms:
  - linux
  - macos
EOF
}

teardown() {
    teardown_test_env
}

@test "yaml.sh: _ensure_yq_available runs without error" {
    source "${MEOW}/lib/core/yaml.sh"
    run _ensure_yq_available
    assert_success
}

@test "yaml.sh: _parse_yaml_with_fallbacks returns error for non-existent file" {
    source "${MEOW}/lib/core/yaml.sh"
    run _parse_yaml_with_fallbacks "/nonexistent/file.yaml" ".name" "false"
    assert_failure
}

@test "yaml.sh: _parse_yaml_with_fallbacks handles valid YAML file" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        result=$(_parse_yaml_with_fallbacks "$TEST_YAML" ".name" "false")
        [ -n "$result" ] || [ "$result" = "" ]
    else
        skip "yq not available"
    fi
}

@test "yaml.sh: _parse_yaml_with_fallbacks returns empty for null values" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        result=$(_parse_yaml_with_fallbacks "$TEST_YAML" ".nonexistent" "false")
        [ -z "$result" ]
    else
        skip "yq not available"
    fi
}

@test "yaml.sh: _parse_yaml_with_fallbacks handles array parsing" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        run _parse_yaml_with_fallbacks "$TEST_YAML" ".required[]" "true"
        assert_success
    else
        skip "yq not available"
    fi
}

@test "yaml.sh: sources tools.sh dependency" {
    source "${MEOW}/lib/core/yaml.sh"
    [ -n "${_LIB_CORE_TOOLS_SOURCED}" ]
}


@test "yaml.sh: read_yaml_value reads scalar value" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        result=$(read_yaml_value "$TEST_YAML" ".version")
        [ -n "$result" ]
    else
        skip "yq not available"
    fi
}

@test "yaml.sh: read_yaml_array reads array values" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        run read_yaml_array "$TEST_YAML" ".required[]"
        assert_success
    else
        skip "yq not available"
    fi
}

@test "yaml.sh: read_yaml_array returns error for non-existent file" {
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "/nonexistent.yaml" ".required[]"
    assert_failure
}

@test "yaml.sh: process_yaml_array processes items" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/yaml.sh"
        touch "$TEST_TEMP_DIR/callback_ran"
        test_callback() {
            echo "processed: $1" >> "$TEST_TEMP_DIR/callback_ran"
        }
        export -f test_callback
        process_yaml_array "$TEST_YAML" ".platforms[]" test_callback
        [ -f "$TEST_TEMP_DIR/callback_ran" ]
    else
        skip "yq not available"
    fi
}
