#!/usr/bin/env bash

TEST_ROOT="${BATS_TEST_DIRNAME}"
while [ "${TEST_ROOT}" != "/" ] && [ "$(basename "${TEST_ROOT}")" != "test" ]; do
    TEST_ROOT="$(dirname "${TEST_ROOT}")"
done

load "${TEST_ROOT}/libs/bats-support/load"
load "${TEST_ROOT}/libs/bats-assert/load"

export MEOW="$(dirname "${TEST_ROOT}")"
export MEOW_VERBOSE=false
export MEOW_DRY_RUN=false

setup_test_env() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"
}

teardown_test_env() {
    if [ -n "${TEST_TEMP_DIR:-}" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

mock_command() {
    local cmd_name="$1"
    local mock_output="$2"
    local mock_exit_code="${3:-0}"
    
    local mock_dir="$TEST_TEMP_DIR/mock_bin"
    mkdir -p "$mock_dir"
    
    cat > "$mock_dir/$cmd_name" <<EOF
#!/usr/bin/env bash
echo "$mock_output"
exit $mock_exit_code
EOF
    chmod +x "$mock_dir/$cmd_name"
    export PATH="$mock_dir:$PATH"
}

skip_if_not_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        skip "This test requires macOS"
    fi
}

skip_if_not_linux() {
    if [ "$(uname -s)" != "Linux" ]; then
        skip "This test requires Linux"
    fi
}

copy_fixture_components() {
    local components_dir="${1:-$MEOW_COMPONENTS_DIR}"
    local fixtures_dir="${TEST_ROOT}/fixtures/components"
    
    if [ ! -d "$fixtures_dir" ]; then
        echo "Fixture directory not found: $fixtures_dir" >&2
        return 1
    fi
    
    mkdir -p "$components_dir"
    
    for component in "$@"; do
        if [ "$component" = "$components_dir" ]; then
            continue
        fi
        if [ -d "$fixtures_dir/$component" ]; then
            cp -r "$fixtures_dir/$component" "$components_dir/"
        fi
    done
}

copy_fixture_presets() {
    local presets_dir="${1:-$MEOW_PRESETS_DIR}"
    local fixtures_dir="${TEST_ROOT}/fixtures/presets"
    
    if [ ! -d "$fixtures_dir" ]; then
        echo "Fixture directory not found: $fixtures_dir" >&2
        return 1
    fi
    
    mkdir -p "$presets_dir"
    
    for preset in "$@"; do
        if [ "$preset" = "$presets_dir" ]; then
            continue
        fi
        if [ -d "$fixtures_dir/$preset" ]; then
            cp -r "$fixtures_dir/$preset" "$presets_dir/"
        fi
    done
}
