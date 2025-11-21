#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "package/homebrew.sh: sources without error" {
    source "${MEOW}/lib/package/homebrew.sh"
}
