#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    export MEOW_COMPONENTS_DIR="$TEST_TEMP_DIR/components"
    export MEOW_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/installed_components"
    export MEOW_INSTALLED_PRESETS_DIR="$TEST_TEMP_DIR/installed_presets"
    export MEOW_PRESETS_DIR="$TEST_TEMP_DIR/presets"
    export MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/manual"
    mkdir -p "$MEOW_COMPONENTS_DIR" "$MEOW_INSTALLED_COMPONENTS_DIR" "$MEOW_INSTALLED_PRESETS_DIR" "$MEOW_PRESETS_DIR" "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
}

teardown() {
    teardown_test_env
}

@test "presets.sh: is_preset_installed returns false for non-installed preset" {
    source "${MEOW}/lib/presets/presets.sh"
    
    run is_preset_installed "nonexistent"
    assert_failure
}

@test "presets.sh: is_preset_installed returns true for installed preset" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/test"
    ln -s "$MEOW_PRESETS_DIR/test" "$MEOW_INSTALLED_PRESETS_DIR/test"
    
    run is_preset_installed "test"
    assert_success
}

@test "presets.sh: get_preset_file returns correct path" {
    source "${MEOW}/lib/presets/presets.sh"
    
    result=$(get_preset_file "mypreset")
    [ "$result" = "${MEOW_PRESETS_DIR}/mypreset/preset.yaml" ]
}

@test "presets.sh: is_preset_available returns true for preset without platform restrictions" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/universal"
    cat > "$MEOW_PRESETS_DIR/universal/preset.yaml" <<EOF
name: universal
description: Universal preset
required:
  - base
EOF
    
    run is_preset_available "universal"
    assert_success
}

@test "presets.sh: is_preset_available returns false for missing preset file" {
    source "${MEOW}/lib/presets/presets.sh"
    
    run is_preset_available "nonexistent"
    assert_failure
}

@test "presets.sh: get_preset_required_components returns components list" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/test"
    cat > "$MEOW_PRESETS_DIR/test/preset.yaml" <<EOF
name: test
required:
  - component1
  - component2
  - component3
EOF
    
    result=$(get_preset_required_components "test")
    echo "$result" | grep -q "component1"
    echo "$result" | grep -q "component2"
    echo "$result" | grep -q "component3"
}

@test "presets.sh: get_preset_required_components returns empty for preset with no requirements" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/empty"
    cat > "$MEOW_PRESETS_DIR/empty/preset.yaml" <<EOF
name: empty
description: Empty preset
EOF
    
    result=$(get_preset_required_components "empty")
    [ -z "$result" ]
}

@test "presets.sh: get_preset_required_components handles preset inheritance with extends" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/base" "$MEOW_PRESETS_DIR/extended"
    cat > "$MEOW_PRESETS_DIR/base/preset.yaml" <<EOF
name: base
required:
  - base-component
EOF
    cat > "$MEOW_PRESETS_DIR/extended/preset.yaml" <<EOF
name: extended
extends:
  - base
required:
  - extended-component
EOF
    
    result=$(get_preset_required_components "extended")
    echo "$result" | grep -q "base-component"
    echo "$result" | grep -q "extended-component"
}

@test "presets.sh: get_preset_required_components detects circular inheritance" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/a" "$MEOW_PRESETS_DIR/b"
    cat > "$MEOW_PRESETS_DIR/a/preset.yaml" <<EOF
name: a
extends:
  - b
required:
  - comp-a
EOF
    cat > "$MEOW_PRESETS_DIR/b/preset.yaml" <<EOF
name: b
extends:
  - a
required:
  - comp-b
EOF
    
    run get_preset_required_components "a"
    assert_failure
    echo "$output" | grep -qi "circular"
}

@test "presets.sh: collect_preset_components_for_installation includes dependencies" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/test" "$MEOW_COMPONENTS_DIR/app" "$MEOW_COMPONENTS_DIR/base"
    cat > "$MEOW_PRESETS_DIR/test/preset.yaml" <<EOF
name: test
required:
  - app
EOF
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/app/component.yaml" <<EOF
name: app
depends_on:
  - components/base
EOF
    
    result=$(collect_preset_components_for_installation "test")
    echo "$result" | grep -q "base"
    echo "$result" | grep -q "app"
}

@test "presets.sh: collect_preset_components_for_installation returns sorted order" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/test" "$MEOW_COMPONENTS_DIR/app" "$MEOW_COMPONENTS_DIR/base"
    cat > "$MEOW_PRESETS_DIR/test/preset.yaml" <<EOF
name: test
required:
  - app
EOF
    cat > "$MEOW_COMPONENTS_DIR/base/component.yaml" <<EOF
name: base
EOF
    cat > "$MEOW_COMPONENTS_DIR/app/component.yaml" <<EOF
name: app
depends_on:
  - components/base
EOF
    
    result=$(collect_preset_components_for_installation "test")
    base_line=$(echo "$result" | grep -n "^base$" | cut -d: -f1)
    app_line=$(echo "$result" | grep -n "^app$" | cut -d: -f1)
    
    [ "$base_line" -lt "$app_line" ]
}

@test "presets.sh: collect_preset_components_for_installation handles multiple components" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/multi"
    for comp in comp1 comp2 comp3; do
        mkdir -p "$MEOW_COMPONENTS_DIR/$comp"
        cat > "$MEOW_COMPONENTS_DIR/$comp/component.yaml" <<EOF
name: $comp
EOF
    done
    
    cat > "$MEOW_PRESETS_DIR/multi/preset.yaml" <<EOF
name: multi
required:
  - comp1
  - comp2
  - comp3
EOF
    
    result=$(collect_preset_components_for_installation "multi")
    echo "$result" | grep -q "comp1"
    echo "$result" | grep -q "comp2"
    echo "$result" | grep -q "comp3"
}

@test "presets.sh: collect_preset_components_for_installation deduplicates components" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/test"
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
EOF
    
    cat > "$MEOW_PRESETS_DIR/test/preset.yaml" <<EOF
name: test
required:
  - left
  - right
EOF
    
    result=$(collect_preset_components_for_installation "test")
    base_count=$(echo "$result" | grep -c "^base$")
    [ "$base_count" -eq 1 ]
}

@test "presets.sh: remove_preset_tracking removes symlink in dry run" {
    source "${MEOW}/lib/presets/presets.sh"
    export MEOW_DRY_RUN=true
    
    mkdir -p "$MEOW_PRESETS_DIR/test"
    ln -s "$MEOW_PRESETS_DIR/test" "$MEOW_INSTALLED_PRESETS_DIR/test"
    
    remove_preset_tracking "test"
    
    [ -L "$MEOW_INSTALLED_PRESETS_DIR/test" ]
}

@test "presets.sh: get_preset_required_components handles extends with multiple parents" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/base1" "$MEOW_PRESETS_DIR/base2" "$MEOW_PRESETS_DIR/child"
    cat > "$MEOW_PRESETS_DIR/base1/preset.yaml" <<EOF
name: base1
required:
  - comp1
EOF
    cat > "$MEOW_PRESETS_DIR/base2/preset.yaml" <<EOF
name: base2
required:
  - comp2
EOF
    cat > "$MEOW_PRESETS_DIR/child/preset.yaml" <<EOF
name: child
extends:
  - base1
  - base2
required:
  - comp3
EOF
    
    result=$(get_preset_required_components "child")
    echo "$result" | grep -q "comp1"
    echo "$result" | grep -q "comp2"
    echo "$result" | grep -q "comp3"
}

@test "presets.sh: collect_preset_components handles empty required list" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/empty"
    cat > "$MEOW_PRESETS_DIR/empty/preset.yaml" <<EOF
name: empty
description: No components
EOF
    
    result=$(collect_preset_components_for_installation "empty")
    [ -z "$result" ] || [ $(echo "$result" | wc -l) -eq 0 ]
}

@test "presets.sh: get_preset_file path format is consistent" {
    source "${MEOW}/lib/presets/presets.sh"
    
    result1=$(get_preset_file "test")
    result2=$(get_preset_file "test")
    
    [ "$result1" = "$result2" ]
    [[ "$result1" == *"/preset.yaml" ]]
}

@test "presets.sh: is_preset_available handles platform-specific preset on macos" {
    if [ "$IS_MACOS" != "true" ]; then
        skip "Not on macOS"
    fi
    
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/macos"
    cat > "$MEOW_PRESETS_DIR/macos/preset.yaml" <<EOF
name: macos
platforms:
  - macos
required:
  - macos-comp
EOF
    
    run is_preset_available "macos"
    assert_success
}

@test "presets.sh: is_preset_available handles platform-specific preset on linux" {
    if [ "$IS_MACOS" = "true" ]; then
        skip "Not on Linux"
    fi
    
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/linux"
    cat > "$MEOW_PRESETS_DIR/linux/preset.yaml" <<EOF
name: linux
platforms:
  - linux
required:
  - linux-comp
EOF
    
    run is_preset_available "linux"
    assert_success
}

@test "presets.sh: get_preset_required_components returns error for missing preset" {
    source "${MEOW}/lib/presets/presets.sh"
    
    run get_preset_required_components "nonexistent"
    assert_failure
}

@test "presets.sh: collect_preset_components handles complex dependency graph" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/complex"
    mkdir -p "$MEOW_COMPONENTS_DIR/a" "$MEOW_COMPONENTS_DIR/b" "$MEOW_COMPONENTS_DIR/c" "$MEOW_COMPONENTS_DIR/d"
    
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
  - components/a
EOF
    cat > "$MEOW_COMPONENTS_DIR/d/component.yaml" <<EOF
name: d
depends_on:
  - components/b
  - components/c
EOF
    
    cat > "$MEOW_PRESETS_DIR/complex/preset.yaml" <<EOF
name: complex
required:
  - d
EOF
    
    result=$(collect_preset_components_for_installation "complex")
    
    a_line=$(echo "$result" | grep -n "^a$" | cut -d: -f1)
    b_line=$(echo "$result" | grep -n "^b$" | cut -d: -f1)
    c_line=$(echo "$result" | grep -n "^c$" | cut -d: -f1)
    d_line=$(echo "$result" | grep -n "^d$" | cut -d: -f1)
    
    [ "$a_line" -lt "$b_line" ]
    [ "$a_line" -lt "$c_line" ]
    [ "$b_line" -lt "$d_line" ]
    [ "$c_line" -lt "$d_line" ]
}

@test "presets.sh: get_preset_required_components handles nested inheritance" {
    source "${MEOW}/lib/presets/presets.sh"
    
    mkdir -p "$MEOW_PRESETS_DIR/base" "$MEOW_PRESETS_DIR/mid" "$MEOW_PRESETS_DIR/top"
    cat > "$MEOW_PRESETS_DIR/base/preset.yaml" <<EOF
name: base
required:
  - base-comp
EOF
    cat > "$MEOW_PRESETS_DIR/mid/preset.yaml" <<EOF
name: mid
extends:
  - base
required:
  - mid-comp
EOF
    cat > "$MEOW_PRESETS_DIR/top/preset.yaml" <<EOF
name: top
extends:
  - mid
required:
  - top-comp
EOF
    
    result=$(get_preset_required_components "top")
    echo "$result" | grep -q "base-comp"
    echo "$result" | grep -q "mid-comp"
    echo "$result" | grep -q "top-comp"
}
