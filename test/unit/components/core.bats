#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "components/core.sh: sources without error" {
    source "${MEOW}/lib/components/core.sh"
}

@test "components/core.sh: sets guard variable" {
    source "${MEOW}/lib/components/core.sh"
    [ -n "${_LIB_COMPONENTS_CORE_SOURCED:-}" ]
}
