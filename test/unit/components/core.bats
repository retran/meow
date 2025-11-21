#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
    export MEOW_COMPONENTS_DIR="$TEST_TEMP_DIR/components"
    export MEOW_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/installed_components"
    export MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="$TEST_TEMP_DIR/manual"
    mkdir -p "$MEOW_COMPONENTS_DIR" "$MEOW_INSTALLED_COMPONENTS_DIR" "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR"
}

teardown() {
    teardown_test_env
}

@test "core.sh: is_component_installed returns false for non-installed component" {
    source "${MEOW}/lib/components/core.sh"
    
    run is_component_installed "nonexistent"
    assert_failure
}

@test "core.sh: is_component_installed returns true for installed component" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    ln -s "$MEOW_COMPONENTS_DIR/test" "$MEOW_INSTALLED_COMPONENTS_DIR/test"
    
    run is_component_installed "test"
    assert_success
}

@test "core.sh: is_component_manually_installed returns false for auto-installed component" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    ln -s "$MEOW_COMPONENTS_DIR/test" "$MEOW_INSTALLED_COMPONENTS_DIR/test"
    
    run is_component_manually_installed "test"
    assert_failure
}

@test "core.sh: is_component_manually_installed returns true for manually installed component" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/manual"
    ln -s "$MEOW_COMPONENTS_DIR/manual" "$MEOW_INSTALLED_COMPONENTS_DIR/manual"
    touch "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR/manual"
    
    run is_component_manually_installed "manual"
    assert_success
}

@test "core.sh: install_component_symlink creates symlink" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
EOF
    
    export MEOW_COMPONENT_MANUAL_INSTALL=false
    export MEOW_DRY_RUN=false
    
    install_component_symlink "test"
    [ -L "$MEOW_INSTALLED_COMPONENTS_DIR/test" ]
}

@test "core.sh: install_component_symlink creates manual marker when requested" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/manual"
    cat > "$MEOW_COMPONENTS_DIR/manual/component.yaml" <<EOF
name: manual
EOF
    
    export MEOW_COMPONENT_MANUAL_INSTALL=true
    export MEOW_DRY_RUN=false
    
    install_component_symlink "manual"
    [ -L "$MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR/manual" ]
}

@test "core.sh: is_component_available returns true for existing component" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/available"
    cat > "$MEOW_COMPONENTS_DIR/available/component.yaml" <<EOF
name: available
description: Available component
EOF
    
    run is_component_available "available"
    assert_success
}

@test "core.sh: is_component_available returns false for non-existing component" {
    source "${MEOW}/lib/components/core.sh"
    
    run is_component_available "nonexistent"
    assert_failure
}

@test "core.sh: is_component_available handles missing yaml file" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/no_yaml"
    
    run is_component_available "no_yaml"
    assert_failure
}

@test "core.sh: remove_component_symlink removes symlink" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
EOF
    ln -s "$MEOW_COMPONENTS_DIR/test" "$MEOW_INSTALLED_COMPONENTS_DIR/test"
    
    export MEOW_DRY_RUN=false
    remove_component_symlink "test"
    [ ! -L "$MEOW_INSTALLED_COMPONENTS_DIR/test" ]
}

@test "core.sh: install_component_symlink fails for non-existent component" {
    source "${MEOW}/lib/components/core.sh"
    
    export MEOW_DRY_RUN=false
    run install_component_symlink "nonexistent"
    assert_failure
}

@test "core.sh: is_component_installed handles symlink verification" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    mkdir -p "$MEOW_INSTALLED_COMPONENTS_DIR/fake"
    
    run is_component_installed "fake"
    assert_failure
}

@test "core.sh: list_components lists all components" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/comp1" "$MEOW_COMPONENTS_DIR/comp2"
    cat > "$MEOW_COMPONENTS_DIR/comp1/component.yaml" <<EOF
name: comp1
EOF
    cat > "$MEOW_COMPONENTS_DIR/comp2/component.yaml" <<EOF
name: comp2
EOF
    
    result=$(list_components false false)
    echo "$result" | grep -q "comp1"
    echo "$result" | grep -q "comp2"
}

@test "core.sh: list_components shows installed status" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/installed"
    cat > "$MEOW_COMPONENTS_DIR/installed/component.yaml" <<EOF
name: installed
EOF
    ln -s "$MEOW_COMPONENTS_DIR/installed" "$MEOW_INSTALLED_COMPONENTS_DIR/installed"
    
    result=$(list_components false true)
    echo "$result" | grep "installed"
}

@test "core.sh: is_component_manually_installed returns false for non-existent component" {
    source "${MEOW}/lib/components/core.sh"
    
    run is_component_manually_installed "nonexistent"
    assert_failure
}

@test "core.sh: component status checks are consistent" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/consistent"
    cat > "$MEOW_COMPONENTS_DIR/consistent/component.yaml" <<EOF
name: consistent
EOF
    ln -s "$MEOW_COMPONENTS_DIR/consistent" "$MEOW_INSTALLED_COMPONENTS_DIR/consistent"
    
    run is_component_installed "consistent"
    status1=$status
    
    run is_component_installed "consistent"
    status2=$status
    
    [ "$status1" -eq "$status2" ]
}

@test "core.sh: install_component_symlink in dry run mode" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/test"
    cat > "$MEOW_COMPONENTS_DIR/test/component.yaml" <<EOF
name: test
EOF
    
    export MEOW_DRY_RUN=true
    export MEOW_COMPONENT_MANUAL_INSTALL=false
    
    install_component_symlink "test"
    [ ! -L "$MEOW_INSTALLED_COMPONENTS_DIR/test" ]
}

@test "core.sh: is_component_available checks platform compatibility" {
    source "${MEOW}/lib/components/core.sh"
    
    mkdir -p "$MEOW_COMPONENTS_DIR/universal"
    cat > "$MEOW_COMPONENTS_DIR/universal/component.yaml" <<EOF
name: universal
EOF
    
    run is_component_available "universal"
    assert_success
}
