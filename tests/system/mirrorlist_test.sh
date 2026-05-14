#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/system/mirrorlist_test.sh" "$@"

out="$(run_script scripts/system/mirrorlist.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "mirrorlist help"

finish
