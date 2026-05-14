#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/system/add_user_test.sh" "$@"

out="$(run_script scripts/system/add_user.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "add_user help is reachable"

finish
