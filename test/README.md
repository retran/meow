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
test/libs/bats/bin/bats test/unit/core/*.bats     # Core library tests
test/libs/bats/bin/bats test/unit/env/*.bats      # Environment tests
test/libs/bats/bin/bats test/unit/motd/*.bats     # MOTD tests
test/libs/bats/bin/bats test/unit/symlinks/*.bats # Symlinks tests
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
├── env/            # Tests for lib/env/*.sh (1 file, 28 tests)
├── motd/           # Tests for lib/motd/*.sh (1 file, 17 tests)
└── symlinks/       # Tests for lib/symlinks/*.sh (1 file, 23 tests)
```

**Total: 321 tests** covering 94 functions across 12 core library files (average 3.4 tests per function).

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

Current test coverage focuses on comprehensive testing of core functionality:

- **Core libraries** (lib/core/): 7 files with 79 comprehensive tests
  - bash.sh (11 tests), colors.sh (14 tests), defs.sh (9 tests), 
  - dry_run.sh (11 tests), platform.sh (15 tests), ui.sh (17 tests), yaml.sh (2 tests)
- **Environment** (lib/env/): 1 file with 5 tests
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
