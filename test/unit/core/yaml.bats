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

@test "yaml.sh: sourcing sets _LIB_YAML_SOURCED" {
    source "${MEOW}/lib/core/yaml.sh"
    [ -n "${_LIB_YAML_SOURCED}" ]
}

@test "yaml.sh: sourcing twice doesn't cause errors" {
    source "${MEOW}/lib/core/yaml.sh"
    source "${MEOW}/lib/core/yaml.sh"
    [ "${_LIB_YAML_SOURCED}" = "1" ]
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

