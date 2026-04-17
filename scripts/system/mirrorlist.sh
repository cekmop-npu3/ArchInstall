#!/bin/bash

set -euo pipefail

source "${SCRIPTS_DIR:-}/utils/utils.sh"
source "${SCRIPTS_DIR:-}/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -h, --help                 Show this help
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
    reflector \
        --country Netherlands,Germany,France,Belgium \
        --protocol https \
        --age 24 \
        --sort rate \
        --latest 20 \
        --save "$( ( is_running_in_iso && echo "/etc/pacman.d/mirrorlist"; ) || echo "/mnt/etc/pacman.d/mirrorlist" )"
}

function main() {
    eval_script_options "$@" || return $?
    update_mirrorlist
}

main "$@"
