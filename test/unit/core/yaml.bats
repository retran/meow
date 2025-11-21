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
EOF
}

teardown() {
    teardown_test_env
}

@test "yaml.sh: sourcing sets _LIB_YAML_SOURCED" {
    source "${MEOW}/lib/core/yaml.sh"
    [ -n "${_LIB_YAML_SOURCED}" ]
}

@test "yaml.sh: _ensure_yq_available runs without error" {
    source "${MEOW}/lib/core/yaml.sh"
    run _ensure_yq_available
    assert_success
}
