#!/usr/bin/bash

set -euo pipefail

source ./utils.sh
source ./parse_options.sh

readonly INVALID_CONFIG_PATH=2
readonly INVALID_ACTION=3
readonly INVALID_CONFIG_ARGS=4
readonly NOT_ABSOLUTE=5
readonly INVALID_SYMLINK=6

declare -i is_interactive=1

function usage () {
    cat <<EOF
Usage:
 $script_name [-i|--interactive]
 $script_name [options] 
 Script is intended to be run in a mounted system

Options:
 -p, --config-path <path_to_config_file>  Path to config file with symlink targets in a format:
    absolute_target absolute_link 
 -a, --action <action>                    Whether to "create" or "delete" symlinks. Default is "create"

 -h, --help                               Display this help
EOF
    exit 0
}

function set_config_path () { config_path="${1:-}"; }
function set_action () { action="${1:-}"; }
function toggle_interactive () { is_interactive=0; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3 opt4
    create_option --long-option="config-path" --short-option="c" --argument="true" --callback=set_config_path opt1
    create_option --long-option="action" --short-option="a" --argument="true" --callback=set_action opt2
    create_option --long-option="help" --short-option="h" --early --callback=usage opt3
    create_option --long-option="interactive" --short-option="i" --early --callback=toggle_interactive opt4

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2 opt3
    set_usage usage2 opt3 opt4

    declare -A response
    handle_usages response script_options usage1 usage2 || return $?

    invoke_callbacks response
}

function input_config_path () {
    read -rp "Enter your config file path: " config_path
}

function input_action () {
    read -rp "Enter your action. Default is \"create\": " action
}

function check_config_path () {
    if [[ -z "$config_path" ]] || ! [[ -e "$config_path" ]]; then
        return $INVALID_CONFIG_PATH
    fi
}

function check_action () {
    if [[ -z "$action" ]]; then
        action="create"
    elif [[ "${action,,}" != "create" && "${action,,}" != "delete" ]]; then
        return $INVALID_ACTION
    fi
}

function parse_config_file () {
    local -a lines
    mapfile -t lines < "$config_path"
    local -i index=0

    local target link

    for (( ; index<${#lines}; index++ )); do
        IFS=' ' read -r target link <<< "${lines[$index]}"
        { [[ -n "$target" ]] && [[ "${target:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE
        { [[ -n "$link" ]] && [[ "${link:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE
        case "$action" in
            (create)
		        if ! ln -sf "$target" "$link" &>/dev/null; then
                    echo "Invalid path at line: $(( $index + 1 ))"
		            exit $INVALID_CONFIG_ARGS
		        fi
            ;;
            (delete)
		        if ! [[ -L "$link" ]] || ! unlink "$link" &>/dev/null; then
                    echo "Invalid symlink at line: $(( $index + 1 ))"
		            exit $INVALID_SYMLINK
		        fi
            ;;
        esac
    done
}

function main () {
    ! is_running_is_iso || return $?

    eval_script_options "$@" || return $?
    verify $is_interactive input_config_path check_config_path || return $?
    verify $is_interactive input_action check_action || return $?

    parse_config_file || return $?
}

main "$@"

