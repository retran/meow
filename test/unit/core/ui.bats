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

@test "ui.sh: ui_info produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_info "info message"
    assert_success
    assert_output --partial "info message"
}

@test "ui.sh: ui_header produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_header "header message"
    assert_success
    assert_output --partial "header message"
}

@test "ui.sh: ui_subheader produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_subheader "subheader message"
    assert_success
    assert_output --partial "subheader message"
}

@test "ui.sh: ui_list_item produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_list_item "list item"
    assert_success
    assert_output --partial "list item"
}

@test "ui.sh: ui_indent produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_indent "indented text"
    assert_success
    assert_output --partial "indented text"
}

@test "ui.sh: ui_emphasis produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_emphasis "emphasized text"
    assert_success
    assert_output --partial "emphasized text"
}

@test "ui.sh: error count starts at zero" {
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_ERROR_COUNT}" -eq 0 ]
}

@test "ui.sh: warning count starts at zero" {
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_WARNING_COUNT}" -eq 0 ]
}

@test "ui.sh: ui_content produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_content "content message"
    assert_success
    assert_output --partial "content message"
}

@test "ui.sh: ui_verbose_message respects MEOW_VERBOSE" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_message "verbose message"
    assert_success
}

@test "ui.sh: ui_verbose_info produces output when verbose" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_info "verbose info"
    assert_success
}

@test "ui.sh: ui_info_detail produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_info_detail "detail message"
    assert_success
}

@test "ui.sh: ui_dependency produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_dependency "dependency name"
    assert_success
}

@test "ui.sh: ui_verbose_action_start with verbose mode" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_action_start "action"
    assert_success
}

@test "ui.sh: ui_verbose_action_success with verbose mode" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_action_success "action"
    assert_success
}

@test "ui.sh: ui_component_updating produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_updating "component"
    assert_success
}

@test "ui.sh: ui_component_uninstalling produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_uninstalling "component"
    assert_success
}

@test "ui.sh: ui_package_manager_setup produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_setup "apt"
    assert_success
}

@test "ui.sh: ui_package_manager_ready produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_ready
    assert_success
}

@test "ui.sh: ui_package_manager_cleaning produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_cleaning
    assert_success
}

@test "ui.sh: reset_summary_counters resets error count" {
    source "${MEOW}/lib/core/ui.sh"
    MEOW_ERROR_COUNT=5
    reset_summary_counters
    [ "${MEOW_ERROR_COUNT}" -eq 0 ]
}

@test "ui.sh: reset_summary_counters resets warning count" {
    source "${MEOW}/lib/core/ui.sh"
    MEOW_WARNING_COUNT=3
    reset_summary_counters
    [ "${MEOW_WARNING_COUNT}" -eq 0 ]
}

@test "ui.sh: show_final_summary displays summary" {
    source "${MEOW}/lib/core/ui.sh"
    run show_final_summary
    assert_success
}

@test "ui.sh: _meow_hide_cursor function exists" {
    source "${MEOW}/lib/core/ui.sh"
    declare -f _meow_hide_cursor > /dev/null
}

@test "ui.sh: _meow_show_cursor function exists" {
    source "${MEOW}/lib/core/ui.sh"
    declare -f _meow_show_cursor > /dev/null
}

@test "ui.sh: _meow_clear_line_sequence function exists" {
    source "${MEOW}/lib/core/ui.sh"
    declare -f _meow_clear_line_sequence > /dev/null
}

@test "ui.sh: _meow_spinner_color function exists" {
    source "${MEOW}/lib/core/ui.sh"
    declare -f _meow_spinner_color > /dev/null
}

@test "ui.sh: ui_confirm function exists" {
    source "${MEOW}/lib/core/ui.sh"
    declare -f ui_confirm > /dev/null
}
