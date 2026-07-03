#!/usr/bin/bash

set -euo pipefail

readonly INVALID_USERNAME=1
readonly INVALID_PASSWORD=2
readonly ADDUSER_INVALID_OPTIONS=3
readonly NO_FILESYSTEM=4
readonly AU_ROOT_DIR_INVALID=5

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $AU_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $AU_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

declare -i is_interactive=1

function usage () {
    cat <<-EOF
Usage:
 $script_name [-i|--interactive]
 $script_name [options]

Options:
 -u, --username <username>                Username to use as login
 -p, --password <pass>                    If the password given is "-", reads from PASSWORD env variable

 -h, --help                               Display this help

Exit codes:
 INVALID_USERNAME=1    
 INVALID_PASSWORD=2                       Password is empty or passwords don't match
 ADDUSER_INVALID_OPTIONS=3                Invalid options passed to $script_name
 NO_FILESYSTEM=4                          Filesystem is not mounted
 AU_ROOT_DIR_INVALID=5                    Invalid ROOT_DIR environment variable
EOF
    exit 0
}

function set_username () { username="${1:-}"; }
function set_password () { password="${1:-}"; }
function toggle_interactive () { is_interactive=0; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3 opt4
    create_option --long-option="username" --short-option="u" --argument="true" --callback=set_username --required opt1
    create_option --long-option="password" --short-option="p" --argument="true" --callback=set_password --required opt2
    create_option --long-option="help" --short-option="h" --early --callback=usage opt3
    create_option --long-option="interactive" --short-option="i" --early --callback=toggle_interactive opt4

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2 opt3
    set_usage usage2 opt3 opt4

    declare -A response
    handle_usages response script_options usage1 usage2 || { echo "Invalid options passed to $script_name"; return $ADDUSER_INVALID_OPTIONS; }

    invoke_callbacks response
}

function input_username () {
    read -rp "Enter your username: " username
}

function input_password () {
    read -rsp "Enter your password: " password
    echo
    read -rsp "Retype your password: " verify_pass
    echo
}

function check_username () {
    if [[ -z "$(echo "${username:-}" | grep -oP "^[a-zA-Z_][a-zA-Z0-9_-]{0,30}$")" ]]; then
        return $INVALID_USERNAME
    fi
}

function check_password () {
    if [[ -n "$(echo "${password:-}" | grep -oP "^-$")" ]]; then 
        password="${PASSWORD-}"
    fi
    if [[ -z "${password:-}" ]]; then
        echo "Password cannot be empty"
        return $INVALID_PASSWORD
    elif [[ "${verify_pass+set}" && "$password" != "${verify_pass-}" ]]; then
        echo "Passwords don't match"
        return $INVALID_PASSWORD
    fi
}

function add_user () {
    commands="
useradd -m $username
printf \"%s:%s\" $username $password | chpasswd
usermod -aG wheel,video,render,input $username
echo \"%wheel ALL=(ALL:ALL) ALL\" > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
"
    if is_running_in_iso; then
        { { findmnt -R /mnt &>/dev/null && [[ -e "/mnt/etc/arch-release" ]]; } || { echo "Filesystem is not mounted"; return $NO_FILESYSTEM; }; } && arch-chroot /mnt &>/dev/null <<< "$commands"
    else
        bash -c "$commands"
    fi
}

function main () {
    eval_script_options "$@" || return $?

    verify $is_interactive input_username check_username || return $?
    verify $is_interactive input_password check_password || return $?

    add_user
}

main "$@"
