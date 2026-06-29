#!/usr/bin/bash

set -euo pipefail

readonly PASSWORD=$(</dev/stdin)

readonly INVALID_OPTIONS=1
readonly PACMAN_ERROR=2
readonly ST_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || echo "ROOT_DIR env variable is not set" && return $ST_ROOT_DIR_INVALID

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || echo "ROOT_DIR is invalid" && return $ST_ROOT_DIR_INVALID

source "$ROOT_DIR/scripts/utils/make_sourced"
source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -d, --delete                To uninstall all of the dependencies
 -h, --help                  Show this help

Error codes:
 INVALID_OPTIONS=1           Invalid options passed to $script_name
 PACMAN_ERROR=2              Error during package installation
 ST_ROOT_DIR_INVALID=3       Invalid ROOT_DIR environment variable
EOF
    exit 0
}

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    local callback=:
    if declare -F delete >/dev/null 2>&1; then
        callback=delete
    fi
    create_option --long-option="delete" --short-option="d" --callback=$callback opt2

    declare -A usage1
    set_usage usage1 opt1 opt2

    declare -A response
    handle_usages response script_options usage1 || echo "Invalid options passed to $script_name" && return $INVALID_OPTIONS

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

