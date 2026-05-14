#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/system/install_packages_test.sh" "$@"

out="$(run_script scripts/system/install_packages.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "install_packages help is reachable"

finish
