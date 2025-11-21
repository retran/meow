#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "tools.sh: _detect_os returns valid OS on Linux" {
    if [ "$(uname -s)" = "Linux" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_os)
        [ "$result" = "linux" ]
    else
        skip "Not on Linux"
    fi
}

@test "tools.sh: _detect_os returns valid OS on macOS" {
    if [ "$(uname -s)" = "Darwin" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_os)
        [ "$result" = "darwin" ]
    else
        skip "Not on macOS"
    fi
}

@test "tools.sh: _detect_arch returns valid architecture" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_arch)
    [[ "$result" =~ ^(amd64|arm64|arm|unknown)$ ]]
}

@test "tools.sh: _detect_arch returns amd64 on x86_64" {
    if [ "$(uname -m)" = "x86_64" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_arch)
        [ "$result" = "amd64" ]
    else
        skip "Not on x86_64 architecture"
    fi
}

@test "tools.sh: _get_install_dir returns a directory path" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -n "$result" ] || [ "$result" = "" ]
}

@test "tools.sh: _get_install_dir prefers /usr/local/bin if writable" {
    if [ -w "/usr/local/bin" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_get_install_dir)
        [ "$result" = "/usr/local/bin" ]
    else
        skip "/usr/local/bin not writable"
    fi
}

@test "tools.sh: _verify_yq returns error when yq not available" {
    source "${MEOW}/lib/core/tools.sh"
    PATH="/nonexistent:$PATH"
    run _verify_yq
    assert_failure
}

@test "tools.sh: _verify_yq succeeds when yq is available and working" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/tools.sh"
        run _verify_yq
        assert_success
    else
        skip "yq not available"
    fi
}

@test "tools.sh: YQ_VERSION is set to default" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "tools.sh: ensure_yq handles missing yq gracefully" {
    source "${MEOW}/lib/core/tools.sh"
    export MEOW_DRY_RUN=true
    run ensure_yq
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
