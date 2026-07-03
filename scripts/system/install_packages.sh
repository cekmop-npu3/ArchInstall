#!/usr/bin/bash

set -euo pipefail

readonly NO_FILE=1
readonly INSTALLPKG_INVALID_OPTIONS=2
readonly NO_FILESYSTEM=3
readonly IP_ROOT_DIR_INVALID=4
readonly PACKAGE_ERROR=5

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $IP_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $IP_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -f, --file <file>                  A file to parse dependencies from
 -d, --delete                       To delete packages listed in <file>
 -h, --help                         Show this help

Error codes:
 NO_FILE=1                          File to install dependencies from is not found
 INSTALLPKG_INVALID_OPTIONS=2       Invalid options passed to $script_name
 NO_FILESYSTEM=3                    Filesystem is not mounted
 IP_ROOT_DIR_INVALID=4              Invalid ROOT_DIR environment variable
 PACKAGE_ERROR=5                    Unknown error during package installation
EOF
    exit 0
}

function set_file () { file="${1:-}"; }
function on_delete () { delete=true; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    create_option --long-option="file" --short-option="f" --callback=set_file --required --argument="true" opt2
    create_option --long-option="delete" --short-option="d" --callback=on_delete opt3

    declare -A usage1
    set_usage usage1 opt1 opt2 opt3

    declare -A response
    handle_usages response script_options usage1 || { echo "Invalid options passed to $script_name"; return $INSTALLPKG_INVALID_OPTIONS; }

    invoke_callbacks response
}

function install_packages () {
    local string="$(sed 's/#.*$//' "$file")"
    local -a packages
    mapfile -t packages< <(echo "$string" | grep -oP "\S+")

    if is_running_in_iso; then
        if [[ "${delete:-}" ]]; then
            echo "Cannot delete packages using pacstrap"
            return $INSTALLPKG_INVALID_OPTIONS
        fi
        { findmnt -R /mnt &>/dev/null || { echo "Filesystem is not mounted"; return $NO_FILESYSTEM; }; } && { pacstrap -K /mnt "${packages[@]}" || { echo "Wrong package name"; return $PACKAGE_ERROR; }; }
    else
        if [[ "${delete:-}" ]]; then
            { [ "$(id -u)" -eq 0 ] && pacman -Runs "${packages[@]}"; } || sudo pacman -Runs "${packages[@]}" || { echo "Wrong package name"; return $PACKAGE_ERROR; }
        else
            { [ "$(id -u)" -eq 0 ] && pacman -Syu "${packages[@]}"; } || sudo pacman -Syu "${packages[@]}" || { echo "Wrong package name"; return $PACKAGE_ERROR; }
        fi
    fi
}

function main () {
    eval_script_options "$@" || return $?
    [[ -e "${file:-}" ]] || { echo "File to parse dependencies not found"; return $NO_FILE; }

    # Update mirrorlist
    "$ROOT_DIR/scripts/system/mirrorlist.sh" || return $?

    install_packages || return $?
}

main "$@"
