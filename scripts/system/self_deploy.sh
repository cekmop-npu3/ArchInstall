#!/usr/bin/bash

set -euo pipefail

readonly NO_FILESYSTEM=1
readonly INVALID_USERNAME=2
readonly SELFDEPLOY_INVALID_OPTIONS=3
readonly SD_ROOT_DIR_INVALID=4

declare PASSWORD=""
read -t 0 && read -r PASSWORD

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $SD_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $SD_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

declare -i is_interactive=1

function usage () {
    cat <<-EOF
Usage: $script_name [OPTIONS]
       $script_name --interactive

Copy this repository into a user's home directory with rsync.

Options:
  -u, --username NAME   Destination account (default: root)
  -i, --interactive     Prompt for the destination account
  -h, --help            Display this help and exit

Exit status:
  0  Success
  1  Target filesystem is not mounted
  2  Invalid username
  3  Invalid command-line options
  4  ROOT_DIR is unset or invalid
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
    handle_usages response script_options usage1 usage2 || { echo "Invalid options passed to $script_name"; return $SELFDEPLOY_INVALID_OPTIONS; }

    invoke_callbacks response
}

function input_username () {
    read -rp "Enter your username. Default is root: " username
}

function check_username () {
    if [[ -z "$username" ]]; then
        username="root"
    elif [[ -z "$(echo "$username" | grep -oP "^[a-zA-Z_][a-zA-Z0-9_-]{0,30}$")" ]]; then
        echo "Username $username doesn't exist"
        return $INVALID_USERNAME
    fi
}

function install_dependencies () {
    if ! command -v rsync &>/dev/null; then
        $ROOT_DIR/scripts/system/install_packages.sh rsync <<< "$PASSWORD" || return $?
    fi
}

function copy () {
    is_running_in_iso && { { findmnt -R /mnt &>/dev/null && [[ -e "/mnt/etc/arch-release" ]]; } || { echo "Filesystem is not mounted"; return $NO_FILESYSTEM; }; }

    local install_root="$ROOT_DIR"
    local target_uid=$(grep "^$username:" "$( ( is_running_in_iso && echo "/mnt/etc/passwd"; ) || echo "/etc/passwd" )" | cut -d: -f3)
    local target_gid=$(grep "^$username:" "$( ( is_running_in_iso && echo "/mnt/etc/group"; ) || echo "/etc/group" )" | cut -d: -f3)

    if [[ "$username" == "root" ]]; then
        if is_running_in_iso; then
            rsync -av --chown="$target_uid:$target_gid" "$install_root" "/mnt/root"
        else
            sudo --stdin rsync -av --chown="$target_uid:$target_gid" "$install_root" "/root" 2>/dev/null <<< "$PASSWORD"
        fi
    else
        rsync -av --chown="$target_uid:$target_gid" "$install_root" "$( ( is_running_in_iso && echo "/mnt/home/$username"; ) || echo "/home/$username" )" &>/dev/null
    fi
}

function main () {
    eval_script_options "$@" || return $?
    verify $is_interactive input_username check_username || return $?
    install_dependencies || return $?
    copy || return $?
}

main "$@"
