# Tests

This directory contains shell-based tests for project scripts.

## Structure

- `install/` tests for `scripts/install/*`
- `system/` tests for `scripts/system/*`
- `utils/` tests for `scripts/utils/*`
- `setup_test.sh` test for root `setup.sh`
- `test_lib.sh` shared test helpers
- `run_tests.sh` test runner

## Run all tests

```bash
bash tests/run_tests.sh
```

## Optional integration test (virtual disk)

`install/disk_formatting_test.sh` includes an integration test using a loopback disk image.

To enable it:

```bash
sudo ALLOW_DISK_INTEGRATION_TEST=1 bash tests/run_tests.sh
```

If not enabled (or not root), it is skipped safely.
