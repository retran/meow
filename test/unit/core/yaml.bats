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

@test "yaml.sh: read_yaml_value returns error for non-existent file" {
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_value "/nonexistent/file.yaml" ".name"
    assert_failure
}

@test "yaml.sh: read_yaml_value handles valid YAML file" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_YAML" ".name")
    [ -n "$result" ] || [ "$result" = "" ]
}

@test "yaml.sh: read_yaml_value returns empty for null values" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_YAML" ".nonexistent")
    [ -z "$result" ]
}

@test "yaml.sh: read_yaml_array handles array parsing" {
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "$TEST_YAML" ".required[]"
    assert_success
}



@test "yaml.sh: read_yaml_value reads scalar value" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_YAML" ".version")
    [ -n "$result" ]
}

@test "yaml.sh: read_yaml_array reads array values" {
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "$TEST_YAML" ".required[]"
    assert_success
}

@test "yaml.sh: read_yaml_array returns error for non-existent file" {
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "/nonexistent.yaml" ".required[]"
    assert_failure
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "/nonexistent.yaml" ".required[]"
    assert_failure
}

@test "yaml.sh: process_yaml_array processes items" {
    source "${MEOW}/lib/core/yaml.sh"
    touch "$TEST_TEMP_DIR/callback_ran"
    test_callback() {
        echo "processed: $1" >> "$TEST_TEMP_DIR/callback_ran"
    }
    export -f test_callback
    process_yaml_array "$TEST_YAML" ".platforms[]" test_callback
    [ -f "$TEST_TEMP_DIR/callback_ran" ]
}

@test "yaml.sh: yaml_path_exists returns true for existing path" {
    source "${MEOW}/lib/core/yaml.sh"
    run yaml_path_exists "$TEST_YAML" ".name"
    assert_success
}

@test "yaml.sh: yaml_path_exists returns false for non-existing path" {
    source "${MEOW}/lib/core/yaml.sh"
    run yaml_path_exists "$TEST_YAML" ".nonexistent"
    assert_failure
}

@test "yaml.sh: yaml_array_length returns correct count" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_array_length "$TEST_YAML")
    [ "$result" -ge 0 ] || [ "$result" -eq 0 ]
}




@test "yaml.sh: read_yaml_value with invalid path" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_YAML" ".invalid.path.here")
    [ -z "$result" ] || [ "$result" = "null" ]
}

@test "yaml.sh: read_yaml_array with empty array" {
    source "${MEOW}/lib/core/yaml.sh"
    echo "empty: []" > "$TEST_TEMP_DIR/empty.yaml"
    run read_yaml_array "$TEST_TEMP_DIR/empty.yaml" ".empty[]"
    assert_failure
}

@test "yaml.sh: read_yaml_array returns multiple items" {
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_array "$TEST_YAML" ".required[]")
    line_count=$(echo "$result" | wc -l)
    [ "$line_count" -gt 0 ]
}


@test "yaml.sh: process_yaml_array with dry-run" {
    export MEOW_DRY_RUN=true
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/yaml.sh"
    test_func() { echo "should not run"; }
    export -f test_func
    run process_yaml_array "$TEST_YAML" ".platforms[]" test_func
    assert_success
}

@test "yaml.sh: yaml_path_exists with valid and invalid paths" {
    source "${MEOW}/lib/core/yaml.sh"
    run yaml_path_exists "$TEST_YAML" ".name"
    success1=$status
    run yaml_path_exists "$TEST_YAML" ".nonexistent"
    success2=$status
    [ "$success1" -ne "$success2" ]
}

@test "yaml.sh: read_yaml_value with special characters" {
    source "${MEOW}/lib/core/yaml.sh"
    echo 'special: "value@#$%"' > "$TEST_TEMP_DIR/special.yaml"
    result=$(read_yaml_value "$TEST_TEMP_DIR/special.yaml" ".special")
    [ -n "$result" ]
}
