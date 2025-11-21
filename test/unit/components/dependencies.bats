#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    export MEOW_COMPONENTS_DIR="$TEST_TEMP_DIR/components"
    export MEOW_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/installed_components"
    export MEOW_INSTALLED_PRESETS_DIR="$TEST_TEMP_DIR/installed_presets"
    export MEOW_PRESETS_DIR="$TEST_TEMP_DIR/presets"
    mkdir -p "$MEOW_COMPONENTS_DIR" "$MEOW_INSTALLED_COMPONENTS_DIR" "$MEOW_INSTALLED_PRESETS_DIR" "$MEOW_PRESETS_DIR"
}

teardown() {
    teardown_test_env
}

@test "dependencies.sh: get_component_dependencies returns empty for component with no dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    copy_fixture_components simple
    
    run get_component_dependencies "simple"
    assert_success
    [ -z "$output" ]
}

@test "dependencies.sh: get_component_dependencies returns single dependency" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    copy_fixture_components with_dep
    
    run get_component_dependencies "with_dep"
    assert_success
    [ "$output" = "base" ]
}

@test "dependencies.sh: get_component_dependencies returns multiple dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    copy_fixture_components multi_dep
    
    result=$(get_component_dependencies "multi_dep")
    echo "$result" | grep -q "base"
    echo "$result" | grep -q "utils"
    echo "$result" | grep -q "config"
}

@test "dependencies.sh: get_component_dependencies strips components/ prefix" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
depends_on:
  - components/dependency
EOF
    
    run get_component_dependencies "test"
    assert_success
    [ "$output" = "dependency" ]
    [[ "$output" != *"components/"* ]]
}

@test "dependencies.sh: get_component_dependencies fails for non-existent component" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    run get_component_dependencies "nonexistent"
    assert_failure
}

@test "dependencies.sh: get_component_dependencies fails for empty component name" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    run get_component_dependencies ""
    assert_failure
}

@test "dependencies.sh: topological_sort_for_installation with no dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/a" "$MEOW_COMPONENTS_DIR/b"
    cat > "$MEOW_COMPONENTS_DIR/a/component.yaml" <<EOF
name: a
EOF
    cat > "$MEOW_COMPONENTS_DIR/b/component.yaml" <<EOF
name: b
EOF
    
    result=$(topological_sort_for_installation "a" "b")
    echo "$result" | grep -q "a"
    echo "$result" | grep -q "b"
}

@test "dependencies.sh: topological_sort_for_installation orders dependencies correctly" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/app"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/app/component.yaml" <<EOF
name: app
depends_on:
  - components/base
EOF
    
    result=$(topological_sort_for_installation "app" "base")
    
    base_line=$(echo "$result" | grep -n "base" | cut -d: -f1)
    app_line=$(echo "$result" | grep -n "app" | cut -d: -f1)
    
    [ "$base_line" -lt "$app_line" ]
}

@test "dependencies.sh: topological_sort_for_installation handles chain of dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/a" "$MEOW_COMPONENTS_DIR/b" "$MEOW_COMPONENTS_DIR/c"
    cat > "$MEOW_COMPONENTS_DIR/a/component.yaml" <<EOF
name: a
EOF
    cat > "$MEOW_COMPONENTS_DIR/b/component.yaml" <<EOF
name: b
depends_on:
  - components/a
EOF
    cat > "$MEOW_COMPONENTS_DIR/c/component.yaml" <<EOF
name: c
depends_on:
  - components/b
EOF
    
    result=$(topological_sort_for_installation "c" "b" "a")
    
    a_line=$(echo "$result" | grep -n "^a$" | cut -d: -f1)
    b_line=$(echo "$result" | grep -n "^b$" | cut -d: -f1)
    c_line=$(echo "$result" | grep -n "^c$" | cut -d: -f1)
    
    [ "$a_line" -lt "$b_line" ]
    [ "$b_line" -lt "$c_line" ]
}

@test "dependencies.sh: topological_sort_for_installation handles diamond dependency" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/left" "$MEOW_COMPONENTS_DIR/right" "$MEOW_COMPONENTS_DIR/top"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/left/component.yaml" <<EOF
name: left
depends_on:
  - components/base
EOF
    cat > "$MEOW_COMPONENTS_DIR/right/component.yaml" <<EOF
name: right
depends_on:
  - components/base
EOF
    cat > "$MEOW_COMPONENTS_DIR/top/component.yaml" <<EOF
name: top
depends_on:
  - components/left
  - components/right
EOF
    
    result=$(topological_sort_for_installation "top" "left" "right" "base")
    
    base_line=$(echo "$result" | grep -n "^base$" | cut -d: -f1)
    left_line=$(echo "$result" | grep -n "^left$" | cut -d: -f1)
    right_line=$(echo "$result" | grep -n "^right$" | cut -d: -f1)
    top_line=$(echo "$result" | grep -n "^top$" | cut -d: -f1)
    
    [ "$base_line" -lt "$left_line" ]
    [ "$base_line" -lt "$right_line" ]
    [ "$left_line" -lt "$top_line" ]
    [ "$right_line" -lt "$top_line" ]
}

@test "dependencies.sh: topological_sort_for_installation detects circular dependency" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/a" "$MEOW_COMPONENTS_DIR/b"
    cat > "$MEOW_COMPONENTS_DIR/a/component.yaml" <<EOF
name: a
depends_on:
  - components/b
EOF
    cat > "$MEOW_COMPONENTS_DIR/b/component.yaml" <<EOF
name: b
depends_on:
  - components/a
EOF
    
    run topological_sort_for_installation "a" "b"
    echo "$output" | grep -q "Circular"
}

@test "dependencies.sh: topological_sort_for_installation returns empty for no arguments" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    run topological_sort_for_installation
    assert_success
    [ -z "$output" ]
}

@test "dependencies.sh: collect_dependencies_recursively_for_installation_stdout collects all dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/mid" "$MEOW_COMPONENTS_DIR/top"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/mid/component.yaml" <<EOF
name: mid
depends_on:
  - components/base
EOF
    cat > "$MEOW_COMPONENTS_DIR/top/component.yaml" <<EOF
name: top
depends_on:
  - components/mid
EOF
    
    result=$(collect_dependencies_recursively_for_installation_stdout "top")
    echo "$result" | grep -q "mid"
    echo "$result" | grep -q "base"
}

@test "dependencies.sh: collect_all_dependencies_for_installation includes target component" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/simple"
    cat > "$MEOW_COMPONENTS_DIR/simple/component.yaml" <<EOF
name: simple
EOF
    
    result=$(collect_all_dependencies_for_installation "simple")
    echo "$result" | grep -q "simple"
}

@test "dependencies.sh: collect_all_dependencies_for_installation deduplicates dependencies" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/left" "$MEOW_COMPONENTS_DIR/right"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/left/component.yaml" <<EOF
name: left
depends_on:
  - components/base
EOF
    cat > "$MEOW_COMPONENTS_DIR/right/component.yaml" <<EOF
name: right
depends_on:
  - components/base
  - components/left
EOF
    
    result=$(collect_all_dependencies_for_installation "right")
    base_count=$(echo "$result" | grep -c "^base$")
    [ "$base_count" -eq 1 ]
}

@test "dependencies.sh: collect_all_dependencies_for_installation returns sorted output" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/app"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/app/component.yaml" <<EOF
name: app
depends_on:
  - components/base
EOF
    
    result=$(collect_all_dependencies_for_installation "app")
    base_line=$(echo "$result" | grep -n "^base$" | cut -d: -f1)
    app_line=$(echo "$result" | grep -n "^app$" | cut -d: -f1)
    
    [ "$base_line" -lt "$app_line" ]
}

@test "dependencies.sh: get_components_depending_on returns empty for unused component" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_INSTALLED_COMPONENTS_DIR/unused"
    cat > "$MEOW_INSTALLED_COMPONENTS_DIR/unused/component.yaml" <<EOF
name: unused
EOF
    ln -s "$MEOW_INSTALLED_COMPONENTS_DIR/unused" "$MEOW_INSTALLED_COMPONENTS_DIR/unused"
    
    run get_components_depending_on "unused"
    [ -z "$output" ] || [ "$output" = $'\n' ]
}

@test "dependencies.sh: get_components_depending_on finds dependent component" {
    source "${MEOW}/lib/components/core.sh"
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/base" "$MEOW_COMPONENTS_DIR/app"
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/app/component.yaml" <<EOF
name: app
depends_on:
  - components/base
EOF
    
    ln -s "$MEOW_COMPONENTS_DIR/base" "$MEOW_INSTALLED_COMPONENTS_DIR/base"
    ln -s "$MEOW_COMPONENTS_DIR/app" "$MEOW_INSTALLED_COMPONENTS_DIR/app"
    
    result=$(get_components_depending_on "base")
    echo "$result" | grep -q "app"
}

@test "dependencies.sh: should_remove_dependency returns failure for manually installed component" {
    source "${MEOW}/lib/components/core.sh"
    source "${MEOW}/lib/components/dependencies.sh"
    
    export MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/manual"
    mkdir -p "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/manual"
    cat > "$MEOW_COMPONENTS_DIR/manual/component.yaml" <<EOF
name: manual
EOF
    
    ln -s "$MEOW_COMPONENTS_DIR/manual" "$MEOW_INSTALLED_COMPONENTS_DIR/manual"
    touch "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR/manual"
    
    run should_remove_dependency "manual"
    assert_failure
}

@test "dependencies.sh: topological_sort handles empty component names gracefully" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/valid"
    cat > "$MEOW_COMPONENTS_DIR/valid/component.yaml" <<EOF
name: valid
EOF
    
    result=$(topological_sort_for_installation "valid" "" "  ")
    echo "$result" | grep -q "valid"
    [ $(echo "$result" | wc -l) -eq 1 ]
}

@test "dependencies.sh: collect_dependencies handles component with no dependency section" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/nodeps"
    cat > "$MEOW_COMPONENTS_DIR/nodeps/component.yaml" <<EOF
name: nodeps
description: No dependencies
EOF
    
    run get_component_dependencies "nodeps"
    assert_success
}

@test "dependencies.sh: get_presets_depending_on returns empty for unused component" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/unused"
    
    run get_presets_depending_on "unused"
    [ -z "$output" ] || [ "$output" = $'\n' ]
}

@test "dependencies.sh: topological_sort is stable for independent components" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/a" "$MEOW_COMPONENTS_DIR/b" "$MEOW_COMPONENTS_DIR/c"
    for comp in a b c; do
        cat > "$MEOW_COMPONENTS_DIR/$comp/component.yaml" <<EOF
name: $comp
EOF
    done
    
    result1=$(topological_sort_for_installation "a" "b" "c")
    result2=$(topological_sort_for_installation "a" "b" "c")
    
    [ "$result1" = "$result2" ]
}

@test "dependencies.sh: collect_all_dependencies handles self-dependency gracefully" {
    source "${MEOW}/lib/components/dependencies.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/self"
    cat > "$MEOW_COMPONENTS_DIR/self/component.yaml" <<EOF
name: self
depends_on:
  - components/self
EOF
    
    run collect_all_dependencies_for_installation "self"
    self_count=$(echo "$output" | grep -c "^self$" || true)
    [ "$self_count" -le 2 ]
}
