#!/usr/bin/bash

set -euo pipefail

declare PASSWORD=""
read -t 0 && read -r PASSWORD

readonly ST_INVALID_OPTIONS=1
readonly PACMAN_ERROR=2
readonly ST_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $ST_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $ST_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/make_sourced.sh"
source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<-EOF
Usage: $script_name [OPTIONS]

Install or remove dependencies for this configuration component.

Options:
  -d, --delete  Remove the component's dependencies
  -h, --help    Display this help and exit

Exit status:
  0  Success
  1  Invalid command-line options
  2  Package operation failed
  3  ROOT_DIR is unset or invalid
EOF
    exit 0
}

function delete_callback_wrapper () {
    local callback=:
    if declare -F delete >/dev/null 2>&1; then
        callback=delete
    fi
    $callback || return $PACMAN_ERROR
    exit 0
}

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    create_option --long-option="delete" --short-option="d" --callback=delete_callback_wrapper opt2

    declare -A usage1
    set_usage usage1 opt1 opt2

    declare -A response
    handle_usages response script_options usage1 || { echo "Invalid options passed to $script_name"; return $ST_INVALID_OPTIONS; }

    invoke_callbacks response
}

function main() {
    ! is_running_in_iso || return $?
    eval_script_options "$@" || return $?

    if declare -F install >/dev/null 2>&1; then
        install || return $PACMAN_ERROR
    fi
}

main "$@"
