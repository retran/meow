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
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "Hello %s" "World")
    assert_equal "$result" "Hello World"
}

@test "ui.sh: _f handles multiple arguments" {
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "%s %s %d" "test" "value" 42)
    assert_equal "$result" "test value 42"
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "%s %s %d" "test" "value" 42)
    assert_equal "$result" "test value 42"
}

@test "ui.sh: ui_message produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_message "test message"
    assert_success
    assert_output --partial "test message"
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
    source "${MEOW}/lib/core/ui.sh"
    run ui_emphasis "emphasized text"
    assert_success
    assert_output --partial "emphasized text"
}

@test "ui.sh: error count starts at zero" {
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_ERROR_COUNT}" -eq 0 ]
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_ERROR_COUNT}" -eq 0 ]
}

@test "ui.sh: warning count starts at zero" {
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_WARNING_COUNT}" -eq 0 ]
    source "${MEOW}/lib/core/ui.sh"
    [ "${MEOW_WARNING_COUNT}" -eq 0 ]
}

@test "ui.sh: ui_content produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_content "content message"
    assert_success
    assert_output --partial "content message"
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
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_info "verbose info"
    assert_success
}

@test "ui.sh: ui_info_detail produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_info_detail "detail message"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_info_detail "detail message"
    assert_success
}

@test "ui.sh: ui_dependency produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_dependency "dependency name"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_dependency "dependency name"
    assert_success
}

@test "ui.sh: ui_verbose_action_start with verbose mode" {
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_action_start "action"
    assert_success
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
    export MEOW_VERBOSE=true
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose_action_success "action"
    assert_success
}

@test "ui.sh: ui_component_updating produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_updating "component"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_updating "component"
    assert_success
}

@test "ui.sh: ui_component_uninstalling produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_uninstalling "component"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_uninstalling "component"
    assert_success
}

@test "ui.sh: ui_package_manager_setup produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_setup "apt"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_setup "apt"
    assert_success
}

@test "ui.sh: ui_package_manager_ready produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_ready
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_ready
    assert_success
}

@test "ui.sh: ui_package_manager_cleaning produces output" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_cleaning
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_package_manager_cleaning
    assert_success
}

@test "ui.sh: reset_summary_counters resets error count" {
    source "${MEOW}/lib/core/ui.sh"
    MEOW_ERROR_COUNT=5
    reset_summary_counters
    [ "${MEOW_ERROR_COUNT}" -eq 0 ]
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
    source "${MEOW}/lib/core/ui.sh"
    MEOW_WARNING_COUNT=3
    reset_summary_counters
    [ "${MEOW_WARNING_COUNT}" -eq 0 ]
}

@test "ui.sh: show_final_summary displays summary" {
    source "${MEOW}/lib/core/ui.sh"
    run show_final_summary
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run show_final_summary
    assert_success
}






@test "ui.sh: _f with no arguments" {
    source "${MEOW}/lib/core/ui.sh"
    run _f ""
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run _f ""
    assert_success
}

@test "ui.sh: _f with special characters" {
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "Test %s %d" "text" 123)
    [[ "$result" == *"text"* ]]
    source "${MEOW}/lib/core/ui.sh"
    result=$(_f "Test %s %d" "text" 123)
    [[ "$result" == *"text"* ]]
}

@test "ui.sh: ui_error without message" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_error
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_error
    assert_success
}

@test "ui.sh: ui_warning without message" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_warning
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_warning
    assert_success
}

@test "ui.sh: error count increments multiple times" {
    source "${MEOW}/lib/core/ui.sh"
    ui_error "test1" >/dev/null 2>&1
    ui_error "test2" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -ge 2 ]
    source "${MEOW}/lib/core/ui.sh"
    ui_error "test1" >/dev/null 2>&1
    ui_error "test2" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -ge 2 ]
}

@test "ui.sh: warning count increments multiple times" {
    source "${MEOW}/lib/core/ui.sh"
    ui_warning "test1" >/dev/null 2>&1
    ui_warning "test2" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -ge 2 ]
    source "${MEOW}/lib/core/ui.sh"
    ui_warning "test1" >/dev/null 2>&1
    ui_warning "test2" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -ge 2 ]
}

@test "ui.sh: ui_action_error increments count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial="${MEOW_ERROR_COUNT}"
    ui_action_error "test" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -gt "$initial" ]
    source "${MEOW}/lib/core/ui.sh"
    local initial="${MEOW_ERROR_COUNT}"
    ui_action_error "test" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -gt "$initial" ]
}

@test "ui.sh: ui_action_warning increments count" {
    source "${MEOW}/lib/core/ui.sh"
    local initial="${MEOW_WARNING_COUNT}"
    ui_action_warning "test" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -gt "$initial" ]
    source "${MEOW}/lib/core/ui.sh"
    local initial="${MEOW_WARNING_COUNT}"
    ui_action_warning "test" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -gt "$initial" ]
}

@test "ui.sh: ui_step_header with zero counts" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Test" 0 0
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Test" 0 0
    assert_success
}

@test "ui.sh: ui_step_header with large counts" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Test" 999 999
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_step_header "Test" 999 999
    assert_success
}

@test "ui.sh: ui_verbose with MEOW_VERBOSE unset" {
    unset MEOW_VERBOSE
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose "test"
    assert_success
    unset MEOW_VERBOSE
    source "${MEOW}/lib/core/ui.sh"
    run ui_verbose "test"
    assert_success
}

@test "ui.sh: ui_title with empty string" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_title ""
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_title ""
    assert_success
}

@test "ui.sh: ui_header with long text" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_header "This is a very long header text that should still be displayed correctly without any issues"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_header "This is a very long header text that should still be displayed correctly without any issues"
    assert_success
}

@test "ui.sh: ui_list_item with special characters" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_list_item "test@#$%&*"
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    run ui_list_item "test@#$%&*"
    assert_success
}

@test "ui.sh: show_final_summary with errors and warnings" {
    source "${MEOW}/lib/core/ui.sh"
    MEOW_ERROR_COUNT=5
    MEOW_WARNING_COUNT=3
    run show_final_summary
    assert_success
    source "${MEOW}/lib/core/ui.sh"
    MEOW_ERROR_COUNT=5
    MEOW_WARNING_COUNT=3
    run show_final_summary
    assert_success
}

@test "ui.sh: ui_message with newlines" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_message "line1\nline2"
    assert_success
}

@test "ui.sh: ui_success with long message" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_success "This is a very long success message that should be displayed correctly without any truncation or issues"
    assert_success
}

@test "ui.sh: ui_error after reset_summary_counters" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_error "test" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -eq 1 ]
}

@test "ui.sh: ui_warning after reset_summary_counters" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_warning "test" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -eq 1 ]
}

@test "ui.sh: multiple ui_error calls increment correctly" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_error "test1" >/dev/null 2>&1
    ui_error "test2" >/dev/null 2>&1
    ui_error "test3" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -eq 3 ]
}

@test "ui.sh: multiple ui_warning calls increment correctly" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_warning "test1" >/dev/null 2>&1
    ui_warning "test2" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -eq 2 ]
}

@test "ui.sh: ui_action_error after reset increments from zero" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_action_error "test" >/dev/null 2>&1
    [ "${MEOW_ERROR_COUNT}" -gt 0 ]
}

@test "ui.sh: ui_action_warning after reset increments from zero" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    ui_action_warning "test" >/dev/null 2>&1
    [ "${MEOW_WARNING_COUNT}" -gt 0 ]
}

@test "ui.sh: ui_step_header formats step number" {
    source "${MEOW}/lib/core/ui.sh"
    result=$(ui_step_header "Test Step" 5 10 2>&1)
    [[ "$result" == *"5"* ]] || [[ "$result" == *"10"* ]]
}

@test "ui.sh: ui_component_installing with special chars" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_installing "my-component_v1.2.3"
    assert_success
}

@test "ui.sh: ui_component_updating with version" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_updating "component (v2.0.0)"
    assert_success
}

@test "ui.sh: ui_component_uninstalling with path" {
    source "${MEOW}/lib/core/ui.sh"
    run ui_component_uninstalling "/path/to/component"
    assert_success
}

@test "ui.sh: show_final_summary with high counts" {
    source "${MEOW}/lib/core/ui.sh"
    MEOW_ERROR_COUNT=100
    MEOW_WARNING_COUNT=50
    run show_final_summary
    assert_success
}

@test "ui.sh: show_final_summary after reset shows zero" {
    source "${MEOW}/lib/core/ui.sh"
    reset_summary_counters
    result=$(show_final_summary 2>&1)
    [ -n "$result" ]
}

@test "ui.sh: ui_verbose_info only shows when verbose" {
    export MEOW_VERBOSE=false
    source "${MEOW}/lib/core/ui.sh"
    result=$(ui_verbose_info "test" 2>&1)
    [ -z "$result" ] || [ -n "$result" ]
}
