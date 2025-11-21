# Unit Tests for .meow

This directory contains unit tests for all library files in `lib/`.

## Test Framework

Tests are written using [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System), the industry standard for testing bash scripts.

### Dependencies

- **bats-core**: Main testing framework
- **bats-support**: Helper functions for tests
- **bats-assert**: Assertion library for readable tests

All dependencies are included as git clones in `test/libs/`.

## Running Tests

### Run All Tests

```bash
test/libs/bats/bin/bats test/unit/**/*.bats
```

### Run Tests by Directory

```bash
test/libs/bats/bin/bats test/unit/core/*.bats       # Core library tests
test/libs/bats/bin/bats test/unit/components/*.bats # Component tests
test/libs/bats/bin/bats test/unit/package/*.bats    # Package manager tests
test/libs/bats/bin/bats test/unit/presets/*.bats    # Preset tests
test/libs/bats/bin/bats test/unit/env/*.bats        # Environment tests
test/libs/bats/bin/bats test/unit/motd/*.bats       # MOTD tests
test/libs/bats/bin/bats test/unit/symlinks/*.bats   # Symlinks tests
```

### Using Taskfile

```bash
task test             # Run all tests (syntax + unit)
task test:unit        # Run unit tests only
task test:unit:core   # Run core library tests only
task test:unit:verbose # Run tests with verbose output
```

## Code Coverage

Code coverage can be generated using `kcov`:

```bash
task coverage:install  # Install kcov (requires sudo on Linux)
task coverage          # Run tests with coverage analysis
task coverage:report   # Open coverage report in browser
```

Coverage reports are generated in the `coverage/` directory.

## Test Structure

Tests focus on core functionality with comprehensive test coverage:

```
test/unit/
├── core/           # Tests for lib/core/*.sh (9 files, 245 tests)
├── components/     # Tests for lib/components/*.sh (2 files, 49 tests)
├── package/        # Tests for lib/package/*.sh (1 file, 22 tests)
├── presets/        # Tests for lib/presets/*.sh (1 file, 24 tests)
├── env/            # Tests for lib/env/*.sh (1 file, 28 tests)
├── motd/           # Tests for lib/motd/*.sh (1 file, 17 tests)
└── symlinks/       # Tests for lib/symlinks/*.sh (1 file, 23 tests)
```

**Total: 406 tests** covering 140+ functions across 16 library files (average 2.9 tests per function).

## Writing Tests

Each test file follows this structure:

```bash
#!/usr/bin/env bats

load '../../test_helper'

setup() {
    setup_test_env
}

teardown() {
    teardown_test_env
}

@test "description of what is being tested" {
    # Test code here
    source "${MEOW}/lib/path/to/file.sh"
    [ condition ]
}
```

### Test Helpers

The `test_helper.bash` file provides:

- `setup_test_env()`: Creates temporary test directory
- `teardown_test_env()`: Cleans up temporary files
- `mock_command()`: Creates mock commands for testing
- `skip_if_not_macos()`, `skip_if_not_linux()`: Platform-specific test skipping

### BATS Assertions

Common assertions used:

- `assert_success`: Command exited with status 0
- `assert_failure`: Command exited with non-zero status
- `assert_equal "expected" "actual"`: Values are equal
- `assert_output "text"`: Output contains text
- `refute_output "text"`: Output doesn't contain text
- `[ condition ]`: Basic bash test conditions

## Test Coverage

Current test coverage includes comprehensive behavioral testing:

- **Core libraries** (lib/core/): 9 files with 245 tests
  - bash.sh (27), colors.sh (31), defs.sh (21), dry_run.sh (32)
  - platform.sh (22), session.sh (5), tools.sh (28), ui.sh (69), yaml.sh (18)
- **Components** (lib/components/): 2 files with 49 tests
  - dependencies.bats (31): topological sorting, dependency resolution
  - core.bats (18): component installation, status tracking
- **Package managers** (lib/package/): 1 file with 22 tests
  - common.bats (22): cache management, package configuration
- **Presets** (lib/presets/): 1 file with 24 tests
  - presets.bats (24): preset management, inheritance, platform compatibility
- **Environment** (lib/env/): 1 file with 28 tests
  - env.bats (28): environment variables, XDG paths, UTF-8 settings
- **MOTD** (lib/motd/): 1 file with 17 tests
  - motd.bats (17): system info, greeting, stats generation
- **Symlinks** (lib/symlinks/): 1 file with 23 tests
  - symlinks.bats (23): path operations, backup management, idempotency

**Total: 406 tests** across 16 library files, covering dependency resolution, package management, preset handling, and all core functionality.
- **MOTD** (lib/motd/): 1 file with 5 tests
- **Symlinks** (lib/symlinks/): 1 file with 6 tests

Total: 95 unit tests covering 10 core library files with meaningful behavioral tests.

## Design Principles

Tests are designed to:

1. **Capture expected behavior**: Tests document how functions should work
2. **Be isolated**: Each test runs in its own environment
3. **Not require full system setup**: Mock external dependencies
4. **Be fast**: Most tests complete in milliseconds
5. **Be maintainable**: Clear names and simple assertions

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: |
    task test:syntax
    task test:unit
```

## Future Improvements

Potential enhancements:

- Integration tests for full component installation workflows
- Performance benchmarks for critical functions
- Mutation testing to verify test quality
- Automated test generation for new files
