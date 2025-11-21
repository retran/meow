#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "session.sh: _initialize_session runs without error" {
    source "${MEOW}/lib/core/session.sh"
    run _initialize_session
    assert_success
}

@test "session.sh: _finalize_session runs without error" {
    source "${MEOW}/lib/core/session.sh"
    run _finalize_session
    assert_success
}

@test "session.sh: _initialize_session can be called multiple times" {
    source "${MEOW}/lib/core/session.sh"
    _initialize_session
    run _initialize_session
    assert_success
}

@test "session.sh: _finalize_session can be called multiple times" {
    source "${MEOW}/lib/core/session.sh"
    _finalize_session
    run _finalize_session
    assert_success
}

@test "session.sh: _initialize_session followed by _finalize_session" {
    source "${MEOW}/lib/core/session.sh"
    _initialize_session
    run _finalize_session
    assert_success
}
