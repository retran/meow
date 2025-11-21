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
test/libs/bats/bin/bats test/unit/core/*.bats    # Core library tests
test/libs/bats/bin/bats test/unit/package/*.bats # Package manager tests
test/libs/bats/bin/bats test/unit/components/*.bats # Component tests
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

Tests are organized to mirror the `lib/` directory structure:

```
test/unit/
├── components/      # Tests for lib/components/*.sh
├── core/           # Tests for lib/core/*.sh
├── env/            # Tests for lib/env/*.sh
├── motd/           # Tests for lib/motd/*.sh
├── package/        # Tests for lib/package/*.sh
├── presets/        # Tests for lib/presets/*.sh
└── symlinks/       # Tests for lib/symlinks/*.sh
```

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

Current test coverage includes:

- **Core libraries** (lib/core/): All 9 files with comprehensive tests
- **Components** (lib/components/): All 7 files with basic source tests
- **Package managers** (lib/package/): All 14 files with basic source tests
- **Other libraries**: env, motd, presets, symlinks - all tested

Total: 121 unit tests covering 35 library files.

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
