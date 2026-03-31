#!/usr/bin/bash

set -euo pipefail

source "${INSTALL_DIR:-}/utils/utils.sh"
source "${INSTALL_DIR:-}/utils/parse_options.sh"

readonly NO_FILE=1

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -f, --file <file>          A file to parse dependencies from
 -h, --help                 Show this help
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
    handle_usages response script_options usage1 || return $?

    invoke_callbacks response
}

function check_filesystem () {
    if ! findmnt -R /mnt &>/dev/null; then
        echo "Filesystem is not mounted"
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
    is_running_in_iso || return $?

    eval_script_options "$@"
    [[ -e "${file:-}" ]] || return $NO_FILE

    check_filesystem || return $?

    update_mirrorlist "/etc/pacman.d/mirrorlist"
    install_packages
    update_mirrorlist "/mnt/etc/pacman.d/mirrorlist"
}

main "$@"

