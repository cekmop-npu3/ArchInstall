#!/usr/bin/env bash
source "$ROOT_DIR/tests/test_lib.sh"
test_help "tests/utils/parse_options_test.sh" "$@"

cb_arg_value=""
cb_noarg_called=0

cb_with_arg() { cb_arg_value="${1:-}"; }
cb_noarg() { cb_noarg_called=1; }

declare -A opt
create_option --short-option='@@' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_SHORT_OPT" "${code:-0}" "invalid short option format"
unset code

create_option --long-option='bad$opt' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_LONG_OPT" "${code:-0}" "invalid long option format"
unset code

create_option --position='NaN' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_OPTIONS" "${code:-0}" "position without option is invalid options combination"
unset code

create_option --short-option='p' --position='NaN' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_INTEGER" "${code:-0}" "invalid --position value"
unset code

create_option --argument='true' --short-option='a' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_ARGUMENT" "${code:-0}" "argument=true requires callback"
unset code

create_option --argument='optional' --long-option='alpha' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_ARGUMENT" "${code:-0}" "argument=optional requires callback"
unset code

create_option --callback='definitely_missing_callback' --short-option='x' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_CALLBACK" "${code:-0}" "invalid callback name"
unset code

create_option --early --short-option='h' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_COMBINATION" "${code:-0}" "early requires callback"
unset code

create_option --early --short-option='h' --callback='cb_noarg' --required opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_COMBINATION" "${code:-0}" "early cannot be required"
unset code

create_option --early --short-option='h' --callback='cb_noarg' --position='0' opt >/dev/null 2>&1 || code=$?
assert_eq "$INVALID_COMBINATION" "${code:-0}" "early cannot have position"
unset code

declare -A opt_short
create_option --short-option='s' opt_short
assert_eq "0" "$?" "valid short-only option"

declare -A opt_long
create_option --long-option='long-only' opt_long
assert_eq "0" "$?" "valid long-only option"

declare -A opt_short_long
create_option --short-option='s' --long-option='short-long' opt_short_long
assert_eq "0" "$?" "valid short+long option"

declare -A opt_arg_true
create_option --short-option='a' --long-option='arg' --argument='true' --callback='cb_with_arg' opt_arg_true
assert_eq "0" "$?" "argument=true with callback"
assert_eq "a:" "${opt_arg_true[getopt_o]}" "argument=true short getopt format"
assert_eq "arg:," "${opt_arg_true[getopt_l]}" "argument=true long getopt format"

declare -A opt_arg_optional
create_option --short-option='o' --long-option='optarg' --argument='optional' --callback='cb_with_arg' opt_arg_optional
assert_eq "0" "$?" "argument=optional with callback"
assert_eq "o::" "${opt_arg_optional[getopt_o]}" "argument=optional short getopt format"
assert_eq "optarg::," "${opt_arg_optional[getopt_l]}" "argument=optional long getopt format"

declare -A opt_early
create_option --short-option='h' --long-option='help' --callback='cb_noarg' --early opt_early
assert_eq "0" "$?" "early option with callback"

declare -A opt_required
create_option --short-option='r' --long-option='required' --required opt_required
assert_eq "0" "$?" "required option declaration"

declare -A usage
set_usage usage opt_short_long opt_arg_true opt_early opt_required
assert_eq "0" "$?" "set_usage with mixed options"

declare -a argv_required_missing=("--arg" "value")
declare -A response
handle_usages response argv_required_missing usage >/dev/null 2>&1 || code=$?
assert_eq "$NO_REQUIRED_OPT" "${code:-0}" "handle_usages detects missing required option"
unset code

declare -a argv_valid=("-r" "--arg" "hello")
handle_usages response argv_valid usage
assert_eq "0" "$?" "handle_usages accepts valid required+arg usage"
invoke_callbacks response
assert_eq "hello" "$cb_arg_value" "callback receives required argument"

cb_noarg_called=0
declare -a argv_help=("--help")
handle_usages response argv_help usage >/dev/null 2>&1 || code=$?
assert_eq "$NO_REQUIRED_OPT" "${code:-0}" "early callback can coexist with required-option failure in current parser"
unset code
invoke_callbacks response
assert_eq "1" "$cb_noarg_called" "early callback invoked"

declare -A opt_pos0
create_option --short-option='x' --long-option='x-opt' --position='0' opt_pos0
declare -A opt_pos1
create_option --short-option='y' --long-option='y-opt' --position='1' opt_pos1
declare -A usage_pos
set_usage usage_pos opt_pos0 opt_pos1
declare -a argv_pos_valid=("-x" "-y")
handle_usages response argv_pos_valid usage_pos
assert_eq "0" "$?" "position-constrained options valid order"

declare -a argv_pos_invalid=("-y" "-x")
handle_usages response argv_pos_invalid usage_pos >/dev/null 2>&1 || code=$?
assert_eq "$WRONG_POS_OPT" "${code:-0}" "position-constrained options wrong order"
unset code

finish
