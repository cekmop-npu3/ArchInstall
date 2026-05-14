#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/install/boot_configuration_test.sh" "$@"

out="$(run_script scripts/install/boot_configuration.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "boot_configuration help is reachable"

run_script scripts/install/boot_configuration.sh >/tmp/bootcfg-test.log 2>&1 || code2=$?
code2=${code2:-0}
assert_eq "1" "$code2" "boot_configuration fails without mounted filesystem"

finish
