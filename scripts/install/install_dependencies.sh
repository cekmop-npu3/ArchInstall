#!/usr/bin/bash

set -euo pipefail

source "${SCRIPTS_DIR:-}/utils/utils.sh"
source "${SCRIPTS_DIR:-}/utils/parse_options.sh"
source "${SCRIPTS_DIR:-}/system/mirrorlist.sh"

readonly NO_FILE=1
readonly INVALID_OPTIONS=2
readonly NO_FILESYSTEM=3

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -f, --file <file>          A file to parse dependencies from
 -h, --help                 Show this help

Error codes:
 NO_FILE=1                  File to install dependencies from is not found
 INVALID_OPTIONS=2          Invalid options passed to $scripts_name
 NO_FILESYSTEM=3            Filesystem is not mounted or $script_name is not running in live environment
EOF
    exit 0
}

function set_file () { file="${1:-}"; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    create_option --long-option="file" --short-option="f" --callback=set_file --required --argument="true" opt2

    declare -A usage1
    set_usage usage1 opt1 opt2

    declare -A response
    handle_usages response script_options usage1 || echo "Invalid options passed to $script_name" && return $INVALID_OPTIONS

    invoke_callbacks response
}

function check_filesystem () {
    if !is_running_in_iso || ! findmnt -R /mnt &>/dev/null; then
        echo "Filesystem is not mounted or doesn't exist under /mnt"
        return $NO_FILESYSTEM
    fi
}

function install_packages () {
    local string="$(sed 's/#.*$//' "$file")"
    local -a packages
    mapfile -t packages< <(echo "$string" | grep -oP "\S+")
    pacstrap -K /mnt "${packages[@]}"
}

function update_mirrorlist () {
    local path="$1"
    reflector \
        --country Netherlands,Germany,France,Belgium \
        --protocol https \
        --age 24 \
        --sort rate \
        --latest 20 \
        --save "$path"
}

function main () {
    check_filesystem || return $?

    eval_script_options "$@" || return $?
    [[ -e "${file:-}" ]] || echo "File to parse dependencies not found" && return $NO_FILE

    update_mirrorlist
    install_packages
}

main "$@"

