#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/utils/utils_test.sh" "$@"

SCRIPTS_DIR="$ROOT_DIR/scripts"
source "$ROOT_DIR/scripts/utils/utils.sh"

is_defined_function definitely_not_existing >/dev/null 2>&1 || code=$?
code=${code:-0}
assert_eq "101" "$code" "is_defined_function returns INVALID_FUNCTION"

if is_running_in_iso >/dev/null 2>&1; then
  pass "is_running_in_iso true in this environment"
else
  code=$?
  assert_eq "100" "$code" "is_running_in_iso returns NOT_IN_ISO outside archiso"
fi

finish
