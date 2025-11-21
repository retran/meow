#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "presets/presets.sh: sources without error" {
    source "${MEOW}/lib/presets/presets.sh"
}
