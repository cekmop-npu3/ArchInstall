#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT_DIR/setup.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL: %s\n' "$1"
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local name="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$name"
  else
    fail "$name (expected=$expected actual=$actual)"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local name="$3"
  if grep -Fq -- "$needle" <<<"$haystack"; then
    pass "$name"
  else
    fail "$name (missing: $needle)"
  fi
}

run_script() {
  local rel="$1"
  shift
  ROOT_DIR="$ROOT_DIR" SCRIPTS_DIR="$SCRIPTS_DIR" bash "$ROOT_DIR/$rel" "$@"
  return $?
}

finish() {
  printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
  [[ "$fail_count" -eq 0 ]]
}

_print_test_help() {
  cat <<EOF
Usage:
  bash $_test_help_file [--help]

Description:
  Runs this test file and prints PASS/FAIL summary.
EOF
  exit 0
}

test_help() {
  _test_help_file="$1"
  shift

  declare -a script_options=("$@")
  declare -A opt1 usage1 response
  create_option --long-option="help" --short-option="h" --early --callback=_print_test_help opt1 || return $?
  set_usage usage1 opt1 || return $?
  handle_usages response script_options usage1 >/dev/null 2>&1 || return 0
  invoke_callbacks response || return $?
}
