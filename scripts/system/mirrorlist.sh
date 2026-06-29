#!/bin/bash

set -euo pipefail

readonly NO_FILESYSTEM=1
readonly MM_ROOT_DIR_INVALID=2

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $MM_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $MM_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -h, --help                 Show this help

Error codes:
 NO_FILESYSTEM=1            Filesystem is not mounted
 IP_ROOT_DIR_INVALID=2      Invalid ROOT_DIR environment variable
EOF
    exit 0
}

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1

    declare -A usage1
    set_usage usage1 opt1

    declare -A response
    handle_usages response script_options usage1 || return $?

    invoke_callbacks response
}

function update_mirrorlist () {
    # TODO: Return error code on failed is_running_in_iso call
    is_running_in_iso && ( findmnt -R /mnt &>/dev/null || echo "Filesystem is not mounted" && return $NO_FILESYSTEM; )
    reflector \
        --country Netherlands,Germany,France,Belgium \
        --protocol https \
        --age 24 \
        --sort rate \
        --latest 20 \
        --save "$( ( is_running_in_iso && echo "/mnt/etc/pacman.d/mirrorlist"; ) || echo "/etc/pacman.d/mirrorlist" )"
}

function main() {
    eval_script_options "$@" || return $?
    update_mirrorlist
}

main "$@"
