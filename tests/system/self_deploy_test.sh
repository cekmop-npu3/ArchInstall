#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/system/self_deploy_test.sh" "$@"

out="$(run_script scripts/system/self_deploy.sh --help 2>&1 || true)"
assert_contains "$out" "Usage:" "self_deploy help is reachable"

finish
