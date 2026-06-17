#!/usr/bin/bash

set -euo pipefail

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

readonly HYPR_INVALID_OPTIONS=1
readonly PACMAN_ERROR=2
readonly ROOT_ERROR=3

declare -ar packages=(
    "zsh"
    "zsh-completions"
    "curl"
)

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -d, --delete                To uninstall all of the dependencies
 -h, --help                  Show this help

Error codes:
 HYPR_INVALID_OPTIONS=1      Invalid options passed to $script_name
 PACMAN_ERROR=2              Error during package installation
EOF
    exit 0
}

function delete () {
    pacman --noconfirm -Rnus ${packages[@]} || return $?
    exit 0
}

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2
    create_option --long-option="help" --short-option="h" --callback=usage --early opt1
    create_option --long-option="delete" --short-option="d" --callback=delete opt2

    declare -A usage1
    set_usage usage1 opt1 opt2

    declare -A response
    handle_usages response script_options usage1 || echo "Invalid options passed to $script_name" && return $HYPR_INVALID_OPTIONS

    invoke_callbacks response
}

function install () {
    sudo pacman --noconfirm --needed -Syu ${packages[@]} || return $?
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function main () {
    [ "$(id -u)" -neq 0 ] && echo "$script_name must be run as a root" && return $ROOT_ERROR
    ! is_running_in_iso || return $?

    eval_script_options "$@" || return $?

    install || echo "An error occured during installation" && return $PACMAN_ERROR  
}


