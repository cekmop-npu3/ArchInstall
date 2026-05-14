#!/usr/bin/bash

: "${ROOT_DIR:?ROOT_DIR is not set. Source setup.sh first}"
set -euo pipefail

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

readonly INVALID_CONFIG_PATH=1
readonly INVALID_ACTION=2
readonly MISSING_DEPENDENCY=3
readonly INVALID_CONFIG_FORMAT=4
readonly INVALID_TARGET=5
readonly NOT_ABSOLUTE_PATH=6
readonly INVALID_SYMLINK=7

declare -i is_interactive=1

function usage () {
    cat <<EOF
Usage:
 $script_name [-i|--interactive]
 $script_name [options] 

Options:
 -p, --config-path <path_to_config_file>  Path to config file with symlink targets in a format:
    JSON:
{
    "symlinks": [
        {
            "target": "target",
            "link": "link",
            "setup": "setup"
        }
    ]
}
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
    create_option --long-option="config-path" --short-option="p" --argument="true" --callback=set_config_path opt1
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
    else
        action="${action,,}"
    fi
}

function check_dependencies () {
    if ! command -v jq &>/dev/null; then
        return $MISSING_DEPENDENCY
    fi
}

function parse_config_file () {
    local -a symlinks
    mapfile -t symlinks < <(jq --tab --compact-output --exit-status '.["symlinks"][]' "$config_path") || return $INVALID_CONFIG_FORMAT

    local symlink
    local target link force
    for symlink in "${symlinks[@]}"; do
        target="$(echo "$symlink" | jq --tab --raw-output --exit-status '.["target"]')" || return $INVALID_TARGET
        [[ "$target" == "~"* ]] && target="${target/#\~/$HOME}"
        { [[ -n "$target" ]] && [[ "${target:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE_PATH
        if [[ "$action" == "create" ]] && ! [[ -e "$target" ]]; then
            return $NOT_ABSOLUTE_PATH
        fi
        link="$(echo "$symlink" | jq --tab --raw-output --exit-status '.["link"]')" || return $INVALID_SYMLINK
        [[ "$link" == "~"* ]] && link="${link/#\~/$HOME}"
        { [[ -n "$link" ]] && [[ "${link:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE_PATH
        setup_script="$(echo "$symlink" | jq --tab --raw-output '.["setup"]')"
        [[ "$setup_script" == "~"* ]] && setup_script="${setup_script/#\~/$HOME}"

        case "$action" in
            (create)
                mkdir -p "$(dirname "$link")"
                ln -sfn "$target" "$link" &>/dev/null || return $INVALID_SYMLINK
                if [[ "$setup_script" != "null" ]]; then
                    [[ -x "$setup_script" ]] || return $INVALID_SYMLINK
                    "$setup_script" || return $?
                fi
            ;;
            (delete)
                if [[ "$setup_script" != "null" ]]; then
                    [[ -x "$setup_script" ]] || return $INVALID_SYMLINK
                    "$setup_script" --delete || return $?
                fi
                { [[ -L "$link" ]] && unlink "$link" &>/dev/null; } || return $INVALID_SYMLINK
            ;;
        esac
    done
}

function main () {
    ! is_running_in_iso || return $?

    eval_script_options "$@" || return $?
    check_dependencies || return $?
    verify $is_interactive input_config_path check_config_path || return $?
    verify $is_interactive input_action check_action || return $?

    parse_config_file || return $?
}

main "$@"
