#!/usr/bin/env bats

load '../../test_helper'

# Helper: emit bash env-setup lines that wire all MEOW path constants to
# a fake root, bypassing the readonly declarations in defs.sh.
_fake_meow_env() {
    local root="$1"
    cat <<ENV
export _LIB_DEFS_SOURCED=1
export MEOW_COMPONENTS_DIR="${root}/components"
export MEOW_PRESETS_DIR="${root}/presets"
export MEOW_INSTALLED_COMPONENTS_DIR="${root}/.installed/components"
export MEOW_INSTALLED_PRESETS_DIR="${root}/.installed/presets"
export MEOW_MANUALLY_INSTALLED_COMPONENTS_DIR="${root}/.installed/components-manual"
export MEOW_DOWNLOADS_DIR="${root}/.downloads"
ENV
}

# Helper: build a minimal fake MEOW data tree at $root (no lib files needed).
_make_fake_data_tree() {
    local root="$1"
    mkdir -p \
        "${root}/components" \
        "${root}/presets" \
        "${root}/.installed/components" \
        "${root}/.installed/components-manual" \
        "${root}/.installed/presets" \
        "${root}/.downloads"
}

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

# ---------------------------------------------------------------------------
# doctor_check_environment
# ---------------------------------------------------------------------------

@test "doctor: check_environment succeeds when MEOW is set to a real directory" {
    source "${MEOW}/lib/doctor/doctor.sh"
    run doctor_check_environment
    assert_success
}

@test "doctor: check_environment errors when MEOW is unset" {
    source "${MEOW}/lib/doctor/doctor.sh"
    # Manipulate within same shell — MEOW is writable here (not readonly)
    local saved="$MEOW"
    MEOW=""
    run doctor_check_environment
    MEOW="$saved"
    assert_failure
}

@test "doctor: check_environment errors when MEOW points to missing directory" {
    source "${MEOW}/lib/doctor/doctor.sh"
    local saved="$MEOW"
    MEOW="/this/does/not/exist/$$"
    run doctor_check_environment
    MEOW="$saved"
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_tools
# ---------------------------------------------------------------------------

@test "doctor: check_tools succeeds when required tools are available" {
    if ! command -v yq >/dev/null 2>&1; then
        skip "yq not available in test environment"
    fi
    if ! command -v git >/dev/null 2>&1; then
        skip "git not available in test environment"
    fi
    source "${MEOW}/lib/doctor/doctor.sh"
    run doctor_check_tools
    assert_success
}

@test "doctor: check_tools reports error when yq is missing" {
    # Run in a subprocess so PATH manipulation is isolated.
    local mock_dir="${TEST_TEMP_DIR}/mock_no_yq"
    mkdir -p "$mock_dir"
    # Provide git and curl so only yq is absent
    for cmd in git curl; do
        printf '#!/usr/bin/env bash\nexit 0\n' > "${mock_dir}/${cmd}"
        chmod +x "${mock_dir}/${cmd}"
    done

    run bash -c "
        export MEOW='${MEOW}'
        export PATH='${mock_dir}'
        $(_fake_meow_env "${TEST_TEMP_DIR}/fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_tools
    "
    assert_failure
}

@test "doctor: check_tools reports error when git is missing" {
    local mock_dir="${TEST_TEMP_DIR}/mock_no_git"
    mkdir -p "$mock_dir"
    # Provide yq stub but not git
    printf '#!/usr/bin/env bash\necho "yq version 4.0.0"\nexit 0\n' > "${mock_dir}/yq"
    chmod +x "${mock_dir}/yq"

    run bash -c "
        export MEOW='${MEOW}'
        export PATH='${mock_dir}'
        $(_fake_meow_env "${TEST_TEMP_DIR}/fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_tools
    "
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_installed_tracking
# ---------------------------------------------------------------------------

@test "doctor: check_installed_tracking passes when no components installed" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_installed_tracking
    "
    assert_success
}

@test "doctor: check_installed_tracking passes with valid symlink" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"
    mkdir -p "${fake}/components/mycomp"
    ln -s "${fake}/components/mycomp" "${fake}/.installed/components/mycomp"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_installed_tracking
    "
    assert_success
}

@test "doctor: check_installed_tracking errors on broken symlink" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"
    ln -s "/this/does/not/exist/$$" "${fake}/.installed/components/ghost"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_installed_tracking
    "
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_component_dependencies
# ---------------------------------------------------------------------------

@test "doctor: check_component_dependencies passes when no components installed" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_component_dependencies
    "
    assert_success
}

@test "doctor: check_component_dependencies passes when deps are satisfied" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    mkdir -p "${fake}/components/dep-a"
    printf 'description: dep\n' > "${fake}/components/dep-a/component.yaml"
    ln -s "${fake}/components/dep-a" "${fake}/.installed/components/dep-a"

    mkdir -p "${fake}/components/consumer"
    printf 'description: consumer\ndepends_on:\n  - dep-a\n' \
        > "${fake}/components/consumer/component.yaml"
    ln -s "${fake}/components/consumer" "${fake}/.installed/components/consumer"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_component_dependencies
    "
    assert_success
}

@test "doctor: check_component_dependencies errors when dep is missing" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    mkdir -p "${fake}/components/consumer"
    printf 'description: consumer\ndepends_on:\n  - missing-dep\n' \
        > "${fake}/components/consumer/component.yaml"
    ln -s "${fake}/components/consumer" "${fake}/.installed/components/consumer"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_component_dependencies
    "
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_dotfile_symlinks
# ---------------------------------------------------------------------------

@test "doctor: check_dotfile_symlinks passes when no symlink configs exist" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    mkdir -p "${fake}/components/simple"
    printf 'description: simple\n' > "${fake}/components/simple/component.yaml"
    ln -s "${fake}/components/simple" "${fake}/.installed/components/simple"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_dotfile_symlinks
    "
    assert_success
}

@test "doctor: check_dotfile_symlinks passes when symlink is healthy" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    mkdir -p "${TEST_TEMP_DIR}/src"
    printf 'config\n' > "${TEST_TEMP_DIR}/src/cfg.conf"

    mkdir -p "${fake}/components/linked/symlinks"
    printf 'description: linked\n' > "${fake}/components/linked/component.yaml"
    ln -s "${fake}/components/linked" "${fake}/.installed/components/linked"

    local tgt="${HOME}/.testcfg_$$"
    ln -s "${TEST_TEMP_DIR}/src/cfg.conf" "$tgt"

    printf -- '- source: "%s"\n  target: "%s"\n' \
        "${TEST_TEMP_DIR}/src/cfg.conf" "$tgt" \
        > "${fake}/components/linked/symlinks/cfg.yaml"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_dotfile_symlinks
    "
    assert_success
}

@test "doctor: check_dotfile_symlinks errors on broken dotfile symlink" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    mkdir -p "${fake}/components/broken/symlinks"
    printf 'description: broken\n' > "${fake}/components/broken/component.yaml"
    ln -s "${fake}/components/broken" "${fake}/.installed/components/broken"

    local broken_link="${HOME}/.broken_link_$$"
    ln -s "/does/not/exist/$$" "$broken_link"

    printf -- '- source: "/does/not/exist/$$"\n  target: "%s"\n' \
        "$broken_link" \
        > "${fake}/components/broken/symlinks/broken.yaml"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_dotfile_symlinks
    "
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_preset_tracking
# ---------------------------------------------------------------------------

@test "doctor: check_preset_tracking passes when no presets installed" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_preset_tracking
    "
    assert_success
}

@test "doctor: check_preset_tracking passes with valid preset symlink" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"
    mkdir -p "${fake}/presets/mypreset"
    ln -s "${fake}/presets/mypreset" "${fake}/.installed/presets/mypreset"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_preset_tracking
    "
    assert_success
}

@test "doctor: check_preset_tracking errors on broken preset symlink" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"
    ln -s "/this/does/not/exist/$$" "${fake}/.installed/presets/ghost"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_preset_tracking
    "
    assert_failure
}

# ---------------------------------------------------------------------------
# doctor_check_packages
# ---------------------------------------------------------------------------

# Helper: create a minimal fake tree with one component that tracks a package
_make_pkg_tree() {
    local root="$1" manager="$2" pkg="$3"
    mkdir -p "${root}/components/mypkg/packages"
    printf '%s\n' "$pkg" > "${root}/components/mypkg/packages/${manager}.list"
    mkdir -p "${root}/.installed/components" "${root}/.installed/presets" \
             "${root}/.installed/components-manual" "${root}/.downloads" \
             "${root}/presets"
}

@test "doctor: check_packages passes when no package managers available" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    # Stub every package manager to be absent
    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        # Override command -v to always fail
        command() { return 1; }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_success
}

@test "doctor: check_packages passes when npm installed matches tracked" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_pkg_tree "$fake" "npm" "mypackage"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        # Stub npm to report mypackage installed
        npm() {
            if [[ \"\$*\" == *'list'* ]]; then
                printf '%s/node_modules/mypackage\n' '/usr/lib'
            fi
        }
        export -f npm
        command() {
            case \"\$2\" in
                npm) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_success
}

@test "doctor: check_packages warns when npm package installed but untracked" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"
    # No npm.list — nothing tracked

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        npm() {
            if [[ \"\$*\" == *'list'* ]]; then
                printf '%s/node_modules/orphan-pkg\n' '/usr/lib'
            fi
        }
        export -f npm
        command() {
            case \"\$2\" in
                npm) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_failure
    assert_output --partial "orphan-pkg"
}

@test "doctor: check_packages warns when npm package tracked but not installed" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_pkg_tree "$fake" "npm" "missing-pkg"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        npm() {
            # Return nothing — no globals installed
            if [[ \"\$*\" == *'list'* ]]; then
                true
            fi
        }
        export -f npm
        command() {
            case \"\$2\" in
                npm) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_failure
    assert_output --partial "missing-pkg"
}

@test "doctor: check_packages passes when pipx installed matches tracked" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_pkg_tree "$fake" "pipx" "mytool"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        pipx() {
            if [[ \"\$*\" == *'list'* ]]; then
                printf 'mytool 1.0\n'
            fi
        }
        export -f pipx
        command() {
            case \"\$2\" in
                pipx) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_success
}

@test "doctor: check_packages warns when pipx package installed but untracked" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        pipx() {
            if [[ \"\$*\" == *'list'* ]]; then
                printf 'ghost-tool 0.1\n'
            fi
        }
        export -f pipx
        command() {
            case \"\$2\" in
                pipx) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_failure
    assert_output --partial "ghost-tool"
}

@test "doctor: check_packages warns when mise tool installed but untracked" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_fake_data_tree "$fake"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        mise() {
            if [[ \"\$*\" == *'ls'* ]]; then
                printf 'mystery-tool\n'
            fi
        }
        export -f mise
        command() {
            case \"\$2\" in
                mise) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_failure
    assert_output --partial "mystery-tool"
}

@test "doctor: check_packages passes when mise tool matches tracked entry" {
    local fake="${TEST_TEMP_DIR}/fake"
    _make_pkg_tree "$fake" "mise" "mytool@latest"

    run bash -c "
        export MEOW='${MEOW}'
        $(_fake_meow_env "$fake")
        IS_MACOS=false
        mise() {
            if [[ \"\$*\" == *'ls'* ]]; then
                printf 'mytool\n'
            fi
        }
        export -f mise
        command() {
            case \"\$2\" in
                mise) return 0 ;;
                *) return 1 ;;
            esac
        }
        export -f command
        source '${MEOW}/lib/doctor/doctor.sh'
        doctor_check_packages
    "
    assert_success
}

# ---------------------------------------------------------------------------
# doctor_run – integration smoke test against the real installation
# ---------------------------------------------------------------------------

@test "doctor: doctor_run completes without crashing" {
    source "${MEOW}/lib/doctor/doctor.sh"
    reset_summary_counters
    run doctor_run
    # Must exit 0 or 1 only — not crash (exit code 2–126, 127+)
    [ "$status" -le 1 ]
}
