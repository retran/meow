#!/usr/bin/env bats
# Comprehensive tests for pure shell YAML parser
# These tests should pass without yq dependency

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# Test simple scalar values
@test "yaml.sh: read string value without quotes" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test-component
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test-component" ]
}

@test "yaml.sh: read string value with double quotes" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: "test-component"
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test-component" ]
}

@test "yaml.sh: read string value with single quotes" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: 'test-component'
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test-component" ]
}

@test "yaml.sh: read numeric value" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
version: 123
port: 8080
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "version")
    [ "$result" = "123" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "port")
    [ "$result" = "8080" ]
}

@test "yaml.sh: read boolean value" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
enabled: true
disabled: false
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "enabled")
    [ "$result" = "true" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "disabled")
    [ "$result" = "false" ]
}

@test "yaml.sh: read value with spaces" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
description: This is a test description
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "description")
    [ "$result" = "This is a test description" ]
}

@test "yaml.sh: read value with colon in quoted string" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
url: "http://example.com:8080"
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "url")
    [ "$result" = "http://example.com:8080" ]
}

# Test arrays
@test "yaml.sh: read simple array" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
items:
  - item1
  - item2
  - item3
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_array "$TEST_TEMP_DIR/test.yaml" "items[]")
    [ "$(echo "$result" | wc -l)" -eq 3 ]
    [ "$(echo "$result" | sed -n '1p')" = "item1" ]
    [ "$(echo "$result" | sed -n '2p')" = "item2" ]
    [ "$(echo "$result" | sed -n '3p')" = "item3" ]
}

@test "yaml.sh: read array with quoted items" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
items:
  - "item 1"
  - 'item 2'
  - item3
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_array "$TEST_TEMP_DIR/test.yaml" "items[]")
    [ "$(echo "$result" | wc -l)" -eq 3 ]
}

@test "yaml.sh: read empty array" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
items: []
EOF
    source "${MEOW}/lib/core/yaml.sh"
    run read_yaml_array "$TEST_TEMP_DIR/test.yaml" "items[]"
    assert_failure
}

@test "yaml.sh: get array length" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
- item1
- item2
- item3
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_array_length "$TEST_TEMP_DIR/test.yaml")
    [ "$result" = "3" ]
}

@test "yaml.sh: get array item by index" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
- first
- second
- third
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_array_item "$TEST_TEMP_DIR/test.yaml" 0)
    [ "$result" = "first" ]
    result=$(yaml_array_item "$TEST_TEMP_DIR/test.yaml" 1)
    [ "$result" = "second" ]
    result=$(yaml_array_item "$TEST_TEMP_DIR/test.yaml" 2)
    [ "$result" = "third" ]
}

# Test nested objects
@test "yaml.sh: read nested value 2 levels" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
parent:
  child: value
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "parent.child")
    [ "$result" = "value" ]
}

@test "yaml.sh: read nested value 3 levels" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
level1:
  level2:
    level3: deep-value
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "level1.level2.level3")
    [ "$result" = "deep-value" ]
}

@test "yaml.sh: read nested array" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
parent:
  children:
    - child1
    - child2
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_nested_array "$TEST_TEMP_DIR/test.yaml" "parent" "children")
    [ "$(echo "$result" | wc -l)" -eq 2 ]
}

@test "yaml.sh: handle missing nested path" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
parent:
  child: value
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "parent.missing")
    [ -z "$result" ]
}

# Test edge cases
@test "yaml.sh: handle YAML comments" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
# This is a comment
name: test # inline comment
# Another comment
version: 1.0.0
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "version")
    [ "$result" = "1.0.0" ]
}

@test "yaml.sh: handle empty values" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name:
value: ""
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ -z "$result" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "value")
    [ -z "$result" ]
}

@test "yaml.sh: handle null values" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: null
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ -z "$result" ] || [ "$result" = "null" ]
}

@test "yaml.sh: handle missing keys" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "missing")
    [ -z "$result" ]
}

@test "yaml.sh: handle 2-space indentation" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
parent:
  child:
    - item1
    - item2
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_nested_array "$TEST_TEMP_DIR/test.yaml" "parent" "child")
    [ "$(echo "$result" | wc -l)" -eq 2 ]
}

@test "yaml.sh: handle 4-space indentation" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
parent:
    child:
        - item1
        - item2
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(yaml_nested_array "$TEST_TEMP_DIR/test.yaml" "parent" "child")
    [ "$(echo "$result" | wc -l)" -eq 2 ]
}

@test "yaml.sh: handle YAML document separator" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
---
name: test
version: 1.0.0
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test" ]
}

@test "yaml.sh: handle mixed content types" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
string: value
number: 42
boolean: true
array:
  - item1
  - item2
object:
  nested: value
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "string")
    [ "$result" = "value" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "number")
    [ "$result" = "42" ]
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "boolean")
    [ "$result" = "true" ]
}

@test "yaml.sh: handle file without trailing newline" {
    printf 'name: test' > "$TEST_TEMP_DIR/test.yaml"
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test" ]
}

@test "yaml.sh: yaml_path_exists returns true for existing path" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test
EOF
    source "${MEOW}/lib/core/yaml.sh"
    run yaml_path_exists "$TEST_TEMP_DIR/test.yaml" "name"
    assert_success
}

@test "yaml.sh: yaml_path_exists returns false for missing path" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test
EOF
    source "${MEOW}/lib/core/yaml.sh"
    run yaml_path_exists "$TEST_TEMP_DIR/test.yaml" "missing"
    assert_failure
}

# Test process_yaml_array
@test "yaml.sh: process_yaml_array calls callback for each item" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
items:
  - item1
  - item2
  - item3
EOF
    source "${MEOW}/lib/core/yaml.sh"
    
    # Create a callback that appends to a file
    callback() {
        echo "$1" >> "$TEST_TEMP_DIR/output.txt"
    }
    export -f callback
    
    process_yaml_array "$TEST_TEMP_DIR/test.yaml" "items[]" callback
    
    [ -f "$TEST_TEMP_DIR/output.txt" ]
    [ "$(cat "$TEST_TEMP_DIR/output.txt" | wc -l)" -eq 3 ]
    [ "$(sed -n '1p' "$TEST_TEMP_DIR/output.txt")" = "item1" ]
}

# Test real-world component YAML structure
@test "yaml.sh: parse component with platforms array" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
description: Test component
platforms:
  - match:
      platform: macos
  - match:
      platform: linux
depends_on:
  - shell-essential
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "description")
    [ "$result" = "Test component" ]
    
    result=$(read_yaml_array "$TEST_TEMP_DIR/test.yaml" "depends_on[]")
    [ "$(echo "$result" | wc -l)" -eq 1 ]
    [ "$(echo "$result" | sed -n '1p')" = "shell-essential" ]
}

# Test path syntax variations
@test "yaml.sh: read value with leading dot" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" ".name")
    [ "$result" = "test" ]
}

@test "yaml.sh: read value without leading dot" {
    cat > "$TEST_TEMP_DIR/test.yaml" <<'EOF'
name: test
EOF
    source "${MEOW}/lib/core/yaml.sh"
    result=$(read_yaml_value "$TEST_TEMP_DIR/test.yaml" "name")
    [ "$result" = "test" ]
}
