#!/bin/bash

set -euo pipefail

readonly MM_ROOT_DIR_INVALID=1
readonly M_AUTH_ERROR=2

declare PASSWORD=""
read -t 0 && read -r PASSWORD

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $MM_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $MM_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

function usage () {
    cat <<-EOF
Usage: $script_name [OPTIONS]

Generate an Arch Linux mirror list with reflector.

Options:
  -h, --help  Display this help and exit

On an installed system, provide the sudo password on standard input when needed.

Exit status:
  0  Success
  1  ROOT_DIR is unset or invalid
  2  Authentication failed
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

function install_dependencies () {
    if ! command -v reflector &>/dev/null; then
        $ROOT_DIR/scripts/system/install_packages.sh reflector <<< "$PASSWORD" || return $?
    fi
}

function update_mirrorlist () {
    if is_running_in_iso && findmnt -R /mnt &>/dev/null && [[ -e "/mnt/etc/arch-release" ]]; then
        reflector \
            --country Netherlands,Germany,France,Belgium \
            --protocol https \
            --age 24 \
            --sort rate \
            --latest 20 \
            --save "/mnt/etc/pacman.d/mirrorlist"
    else
        sudo --stdin reflector \
            --country Netherlands,Germany,France,Belgium \
            --protocol https \
            --age 24 \
            --sort rate \
            --latest 20 \
            --save "/etc/pacman.d/mirrorlist" 2>/dev/null <<< "$PASSWORD" || return $M_AUTH_ERROR
    fi
}

function main() {
    eval_script_options "$@" || return $?
    install_dependencies || return $?
    update_mirrorlist || return $?
}

main "$@"
