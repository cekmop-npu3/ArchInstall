#!/usr/bin/bash

set -euo pipefail

source "${INSTALL_DIR:-}/utils/utils.sh"
source "${INSTALL_DIR:-}/utils/parse_options.sh"

readonly NO_FILESYSTEM=1

declare -i is_interactive=1

function usage () {
    cat <<-EOF
Usage:
 $script_name [-i|--interactive]
 $script_name [options]

Options:
 -u, --username <username>                User account on a mounted system to copy the directory to

 -h, --help                               Display this help

Exit codes:
 INVALID_USERNAME=1    
EOF
    exit 0
}

function set_username () { username="${1:-}"; }
function toggle_interactive () { is_interactive=0; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3
    create_option --long-option="username" --short-option="u" --argument="true" --callback=set_username opt1
    create_option --long-option="help" --short-option="h" --early --callback=usage opt2
    create_option --long-option="interactive" --short-option="i" --early --callback=toggle_interactive opt3

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2
    set_usage usage2 opt3 opt2

    declare -A response
    handle_usages response script_options usage1 usage2 || return $?

    invoke_callbacks response
}

function input_username () {
    read -rp "Enter your username. Default is root: " username
}

function check_username () {
    if [[ -z "$username" ]]; then
        username="root"
    elif [[ -z "$(echo "$username" | grep -oP "^[a-zA-Z_][a-zA-Z0-9_-]{0,30}$")" ]]; then
        return $INVALID_USERNAME
    fi
}

function check_filesystem () {
    if ! findmnt -R /mnt &>/dev/null; then
        echo "Filesystem is not mounted"
        return $NO_FILESYSTEM
    fi
}

function copy () {
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    local target_uid=$(grep "^$username:" "/mnt/etc/passwd" | cut -d: -f3)
    local target_gid=$(grep "^$username:" "/mnt/etc/group" | cut -d: -f3)
    rsync -av --chown="$target_uid:$target_gid" "$script_dir" "/mnt/home/$username/"

}

function main () {
    is_running_in_iso || return $?
    check_filesystem || return $?

    eval_script_options "$@" || return $?
    verify $is_interactive input_username check_username || return $?

    copy
}

main "$@"
