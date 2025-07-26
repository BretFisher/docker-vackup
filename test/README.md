# Vackup Test Suite

This directory contains comprehensive tests for the `vackup` Docker volume backup and restore tool.

## Overview

The test suite uses [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core) to provide
thorough testing of all `vackup` functionality across different platforms including macOS, Linux, and Windows WSL.

## Test Coverage

### Core Functionality Tests

- **Export Command**: Creates tarballs from Docker volumes
- **Import Command**: Restores tarballs to Docker volumes
- **Save Command**: Copies volume data to container images
- **Load Command**: Restores volume data from container images

### Cross-Platform Compatibility Tests

- **File Path Handling**: Tests both relative and absolute paths
- **Special Characters**: Handles files with spaces and special characters
- **Directory Structures**: Tests nested directories and complex file structures
- **Platform-Specific**: Compatible with macOS `realpath`/`readlink` differences

### Error Handling Tests

- **Missing Arguments**: Validates proper error messages for incomplete commands
- **Non-existent Resources**: Tests behavior with missing volumes/files/images
- **Invalid Inputs**: Handles directories passed as files, etc.
- **Permission Issues**: Tests file access permissions

### Data Integrity Tests

- **Round-trip Consistency**: Ensures export→import and save→load preserve data exactly
- **Complex Data**: Tests with multiple files, directories, and various content types
- **File Attributes**: Verifies file permissions and timestamps are preserved

## Test Structure

### Files

- `vackup.bats` - Main test suite with 14 comprehensive tests
- `run-tests.sh` - Test runner script with additional features

### Test Data

Each test creates unique test data including:

- Simple text files
- Multi-line files
- Files with special characters and spaces
- Nested directory structures
- Various file types and sizes

### Cleanup

- Automatic cleanup of Docker volumes and images after each test
- Uses unique prefixes to avoid conflicts with existing resources
- Safe cleanup that won't affect non-test resources

## Running Tests

### Quick Run

```bash
# From repository root
bats test/vackup.bats
```

### Using Test Runner (Recommended)

```bash
# Basic run
./test/run-tests.sh

# Verbose output
./test/run-tests.sh -v

# Clean up before running
./test/run-tests.sh -c

# See all options
./test/run-tests.sh -h
```

### Requirements

- **Bats**: Install via `brew install bats-core` (macOS) or package manager
- **Docker**: Must be installed and daemon running
- **Bash**: Compatible with Bash 3.2+ (default on macOS)

## Platform-Specific Notes

### macOS

- Uses `realpath` when available, falls back to `cd && pwd` approach
- Handles case-insensitive filesystem appropriately
- Compatible with older Bash version (3.2)

### Linux

- Uses standard GNU tools (`readlink -m`, etc.)
- Optimized for standard Linux Docker environments
- Compatible with various distributions

### Windows WSL

- Tested with WSL2 and Docker Desktop
- Handles Windows path translations appropriately
- Compatible with Ubuntu/Debian WSL distributions

## CI/CD Integration

The test suite is designed for easy CI/CD integration:

```yaml
# Example GitHub Actions
- name: Run vackup tests
  run: |
    chmod +x ./test/run-tests.sh
    ./test/run-tests.sh -v
```

## Troubleshooting

### Common Issues

1. **Docker not running**: Ensure Docker daemon is started
2. **Permission errors**: Make sure scripts are executable (`chmod +x`)
3. **Cleanup failures**: Run `./test/run-tests.sh -c` to clean up manually

### Test Failures

- Check Docker daemon status
- Verify sufficient disk space for test volumes/images
- Ensure no conflicting Docker resources exist

### Performance

- Tests typically run in 30-60 seconds
- Each test is independent and can be run individually
- Cleanup is automatic but can be manual if needed

## Contributing

When adding new tests:

1. Use the existing naming conventions (`${TEST_PREFIX}_*`)
2. Include proper cleanup in teardown
3. Test both success and failure cases
4. Document any platform-specific behavior
5. Ensure tests are deterministic and independent

## Test Philosophy

These tests follow the principle of testing behavior, not implementation:

- Focus on user-visible outcomes
- Test edge cases and error conditions
- Verify data integrity and consistency
- Ensure cross-platform compatibility
- Provide clear, actionable error messages
