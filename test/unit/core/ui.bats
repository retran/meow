#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "ui.sh: _f formats strings correctly" {
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "Hello %s" "World")
    assert_equal "$result" "Hello World"
}

@test "ui.sh: _f handles multiple arguments" {
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "%s %s %d" "test" "value" 42)
    assert_equal "$result" "test value 42"
}

@test "ui.sh: ui_message produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_message "test message"
    assert_success
    assert_output --partial "test message"
}

@test "ui.sh: ui_success produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_success "success message"
    assert_success
    assert_output --partial "success message"
}

@test "ui.sh: ui_error increments error count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial_count=$MEOW_ERROR_COUNT
    ui_error "error message" 2>/dev/null
    [ $MEOW_ERROR_COUNT -eq $((initial_count + 1)) ]
}

@test "ui.sh: ui_warning increments warning count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial_count=$MEOW_WARNING_COUNT
    ui_warning "warning message" 2>/dev/null
    [ $MEOW_WARNING_COUNT -eq $((initial_count + 1)) ]
}

@test "ui.sh: ui_verbose respects MEOW_VERBOSE=false" {
    export MEOW_VERBOSE=false
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose "verbose message"
    assert_success
    refute_output --partial "verbose message"
}

@test "ui.sh: ui_verbose shows output when MEOW_VERBOSE=true" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose "verbose message"
    assert_success
    assert_output --partial "verbose message"
}

@test "ui.sh: ui_title produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_title "title message"
    assert_success
    assert_output --partial "title message"
}

@test "ui.sh: ui_action_start produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_action_start "action message"
    assert_success
    assert_output --partial "action message"
}

@test "ui.sh: ui_action_success produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_action_success "success message"
    assert_success
    assert_output --partial "success message"
}

@test "ui.sh: ui_action_error increments error count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial_count=$MEOW_ERROR_COUNT
    ui_action_error "error message" 2>/dev/null
    [ $MEOW_ERROR_COUNT -eq $((initial_count + 1)) ]
}

@test "ui.sh: ui_action_warning increments warning count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial_count=$MEOW_WARNING_COUNT
    ui_action_warning "warning message"
    [ $MEOW_WARNING_COUNT -eq $((initial_count + 1)) ]
}

@test "ui.sh: ui_component_installing produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_installing "test-component"
    assert_success
    assert_output --partial "test-component"
}

@test "ui.sh: ui_step_header with counts" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Step Name" 2 5
    assert_success
    assert_output --partial "Step Name"
    assert_output --partial "(2/5)"
}

@test "ui.sh: ui_step_header without counts" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Step Name"
    assert_success
    assert_output --partial "Step Name"
    refute_output --partial "/"
}
