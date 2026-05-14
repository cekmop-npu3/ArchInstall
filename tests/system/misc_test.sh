#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/system/misc_test.sh" "$@"

out="$(run_script scripts/system/misc.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "misc help"

finish
