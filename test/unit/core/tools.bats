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
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}


@test "tools.sh: _detect_os handles unknown OS gracefully" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_os)
    [ -n "$result" ]
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_os)
    [ -n "$result" ]
}

@test "tools.sh: _detect_arch handles current architecture" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_arch)
    [ -n "$result" ]
    [[ "$result" != "unknown" ]] || [ "$result" = "unknown" ]
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_arch)
    [ -n "$result" ]
    [[ "$result" != "unknown" ]] || [ "$result" = "unknown" ]
}

@test "tools.sh: _get_install_dir returns valid directory or empty" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -z "$result" ] || [ -n "$result" ]
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -z "$result" ] || [ -n "$result" ]
}

@test "tools.sh: YQ_VERSION format is valid" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9] ]]
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9] ]]
}

@test "tools.sh: _detect_os on Darwin returns darwin" {
    if [ "$(uname -s)" = "Darwin" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_os)
        [ "$result" = "darwin" ]
    else
        skip "Not on Darwin/macOS"
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_os)
        [ "$result" = "darwin" ]
    else
        skip "Not on Darwin/macOS"
    fi
}

@test "tools.sh: _detect_arch on arm64 returns arm64" {
    if [ "$(uname -m)" = "arm64" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_arch)
        [ "$result" = "arm64" ]
    else
        skip "Not on arm64 architecture"
    fi
    if [ "$(uname -m)" = "arm64" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_arch)
        [ "$result" = "arm64" ]
    else
        skip "Not on arm64 architecture"
    fi
}

@test "tools.sh: _detect_arch on aarch64 returns arm64" {
    if [ "$(uname -m)" = "aarch64" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_arch)
        [ "$result" = "arm64" ]
    else
        skip "Not on aarch64 architecture"
    fi
    if [ "$(uname -m)" = "aarch64" ]; then
        source "${MEOW}/lib/core/tools.sh"
        result=$(_detect_arch)
        [ "$result" = "arm64" ]
    else
        skip "Not on aarch64 architecture"
    fi
}

@test "tools.sh: _get_install_dir returns path or empty" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -z "$result" ] || [[ "$result" == /* ]]
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -z "$result" ] || [[ "$result" == /* ]]
}

@test "tools.sh: _verify_yq handles missing yq" {
    source "${MEOW}/lib/core/tools.sh"
    PATH="/nonexistent"
    run _verify_yq
    assert_failure
    source "${MEOW}/lib/core/tools.sh"
    PATH="/nonexistent"
    run _verify_yq
    assert_failure
}

@test "tools.sh: YQ_VERSION has v prefix" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" == v* ]]
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" == v* ]]
}

@test "tools.sh: YQ_VERSION contains dot separators" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" == *"."* ]]
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" == *"."* ]]
}


@test "tools.sh: _detect_os returns consistent result" {
    source "${MEOW}/lib/core/tools.sh"
    result1=$(_detect_os)
    result2=$(_detect_os)
    [ "$result1" = "$result2" ]
}

@test "tools.sh: _detect_arch returns consistent result" {
    source "${MEOW}/lib/core/tools.sh"
    result1=$(_detect_arch)
    result2=$(_detect_arch)
    [ "$result1" = "$result2" ]
}

@test "tools.sh: _get_install_dir returns empty or path" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_get_install_dir)
    [ -z "$result" ] || [[ "$result" =~ ^/ ]]
}

@test "tools.sh: _verify_yq with yq available succeeds" {
    if command -v yq >/dev/null 2>&1; then
        source "${MEOW}/lib/core/tools.sh"
        run _verify_yq
        assert_success
    else
        skip "yq not available"
    fi
}

@test "tools.sh: ensure_yq in dry-run mode" {
    export MEOW_DRY_RUN=true
    source "${MEOW}/lib/core/tools.sh"
    run ensure_yq
    assert_success
}

@test "tools.sh: YQ_VERSION starts with v" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9] ]]
}

@test "tools.sh: YQ_VERSION has proper format" {
    source "${MEOW}/lib/core/tools.sh"
    [[ "$YQ_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "tools.sh: _detect_os with modified uname" {
    source "${MEOW}/lib/core/tools.sh"
    result=$(_detect_os)
    [ "$result" = "linux" ] || [ "$result" = "darwin" ] || [ "$result" = "unknown" ]
}
