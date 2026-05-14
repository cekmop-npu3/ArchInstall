#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/utils/make_sourced_test.sh" "$@"

out="$(bash "$ROOT_DIR/scripts/utils/make_sourced.sh" 2>&1 || true)"
assert_contains "$out" "Only intended to be sourced" "make_sourced refuses direct execution"

finish
