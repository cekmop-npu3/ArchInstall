#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/install/system_configuration_test.sh" "$@"

out="$(run_script scripts/install/system_configuration.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "system_configuration help is reachable"

run_script scripts/install/system_configuration.sh --timezone Invalid/Zone --hostname test >/tmp/syscfg-test.log 2>&1 || code=$?
code=${code:-0}
if [[ "$code" == "3" || "$code" == "4" ]]; then
  pass "system_configuration returns known failure code outside expected env/usage"
else
  fail "system_configuration unexpected status: $code"
fi

finish
