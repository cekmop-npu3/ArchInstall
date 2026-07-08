#!/usr/bin/bash

set -euo pipefail

readonly NO_FILE=1
readonly INSTALLPKG_INVALID_OPTIONS=2
readonly NO_FILESYSTEM=3
readonly IP_ROOT_DIR_INVALID=4
readonly PACKAGE_ERROR=5
readonly AUTH_ERROR=6

declare PASSWORD=""
read -t 0 && read -r PASSWORD

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $IP_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $IP_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options] [packages] <<< \$PASSWORD

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
 AUTH_ERROR=6                       Invalid password 
EOF
    exit 0
}

function set_file () { file="${1:-}"; }
function on_delete () { delete=true; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    create_option --long-option="file" --short-option="f" --callback=set_file --argument="true" opt2
    create_option --long-option="delete" --short-option="d" --callback=on_delete opt3

    declare -A usage1
    set_usage usage1 opt1 opt2 opt3

    declare -A response
    handle_usages response script_options usage1 || { echo "Invalid options passed to $script_name"; return $INSTALLPKG_INVALID_OPTIONS; }

    invoke_callbacks response

    declare -ga operands
    local code
    get_operands response operands || { code=$? ; [[ -n "${file:-}" ]] || return $code; } 
}

function resolve_packages () {
    declare -ga packages
    if [[ -n "${file:-}" ]]; then
        local string="$(sed 's/#.*$//' "$file")"
        mapfile -t packages< <(echo "$string" | grep -oP "\S+")
    else
        packages=("${operands[@]}")
    fi
}

function delete_packages () {
    local package
    if is_running_in_iso; then
        echo "Cannot delete packages using pacstrap"
        return $INSTALLPKG_INVALID_OPTIONS
    else
        for package in "${packages[@]}"; do
            pacman -Qi "$package" &>/dev/null && { { [ "$(id -u)" -eq 0 ] && pacman --noconfirm --needed -Syu "$package"; } || sudo --stdin pacman --noconfirm --needed -Syu "$package" 2>/dev/null <<< "$PASSWORD" || { echo "Authentication error"; return $AUTH_ERROR; }; }
        done
    fi
}

function install_packages () {
    local package
    if is_running_in_iso; then
        findmnt -R /mnt &>/dev/null || { echo "Filesystem is not mounted"; return $NO_FILESYSTEM; }
        pacman --noconfirm --needed -Sy
        for package in "${packages[@]}"; do
            pacstrap -K /mnt "$package"
        done
    else
        { [ "$(id -u)" -eq 0 ] && pacman --noconfirm --needed -Sy; } || sudo --stdin pacman --noconfirm --needed -Sy 2>/dev/null <<< "$PASSWORD" || { echo "Authentication error"; return $PACKAGE_ERROR; }
        for package in "${packages[@]}"; do
            pacman -Si "$package" &>/dev/null && { { [ "$(id -u)" -eq 0 ] && pacman --noconfirm --needed -S "$package"; } || sudo --stdin pacman --noconfirm --needed -S "$package" 2>/dev/null <<< "$PASSWORD" || { echo "Authentication error"; return $AUTH_ERROR; }; }
        done
    fi
}

function main () {
    eval_script_options "$@" || return $?
    resolve_packages
    if [[ "${delete:-}" ]]; then
        delete_packages || return $?
    else
        install_packages || return $?
    fi
}

main "$@"
