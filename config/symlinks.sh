#!/usr/bin/bash

set -euo pipefail

readonly INVALID_CONFIG_PATH=1
readonly INVALID_ACTION=2
readonly MISSING_DEPENDENCY=3
readonly INVALID_CONFIG_FORMAT=4
readonly INVALID_TARGET=5
readonly NOT_ABSOLUTE_PATH=6
readonly INVALID_SYMLINK=7
readonly SS_ROOT_DIR_INVALID=8
readonly INVALID_SETUP_SCRIPT=9

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $SS_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $SS_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/utils.sh"
source "$ROOT_DIR/scripts/utils/parse_options.sh"

declare -i is_interactive=1

function usage () {
    cat <<-EOF
Usage: $script_name [OPTIONS]
       $script_name --interactive

Create or delete the configuration symlinks described by a JSON manifest.

Options:
  -p, --config-path FILE   Read symlink definitions from FILE
  -a, --action ACTION      Action to perform: create or delete (default: create)
  -i, --interactive        Prompt for the manifest, action, and sudo password
  -h, --help               Display this help and exit

Manifest format:
  {"symlinks":[{"target":"/source","link":"/destination","setup":"/setup.sh"}]}

Exit status:
  0  Success
  1  Invalid or missing manifest path
  2  Invalid action
  3  Missing dependency
  4  Invalid manifest format
  5  Invalid target
  6  Target or link is not an absolute path after expansion
  7  Symlink operation failed
  8  ROOT_DIR is unset or invalid
  9  Invalid or non-executable setup script
EOF
    exit 0
}

function set_config_path () { config_path="${1:-}"; }
function set_action () { action="${1:-}"; }
function toggle_interactive () { is_interactive=0; }
function set_password () { password="${1:-}"; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3 opt4 opt5
    create_option --long-option="config-path" --short-option="p" --argument="true" --callback=set_config_path opt1
    create_option --long-option="action" --short-option="a" --argument="true" --callback=set_action opt2
    create_option --long-option="help" --short-option="h" --early --callback=usage opt3
    create_option --long-option="password" --short-option="p" --argument="true" --callback=set_password --required opt5
    create_option --long-option="interactive" --short-option="i" --early --callback=toggle_interactive opt4

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2 opt3 opt5
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

function input_password () {
    read -rsp "Enter your sudo password: " password
    echo
}

function check_password () {
    if [[ -n "$(echo "${password:-}" | grep -oP "^-$")" ]]; then 
        password="${PASSWORD-}"
    fi
    if [[ -z "${password:-}" ]]; then
        echo "Password cannot be empty"
        return $INVALID_PASSWORD
    fi
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

function install_dependencies () {
    if ! command -v jq &>/dev/null; then
        $ROOT_DIR/scripts/system/install_packages.sh jq <<< "$password" || return $?
    fi
}

function parse_config_file () {
    local -a symlinks
    mapfile -t symlinks < <(jq --tab --compact-output --exit-status '.["symlinks"][]' "$config_path") || return $INVALID_CONFIG_FORMAT

    local symlink
    local target link force
    local -a failed_setups=()

    for symlink in "${symlinks[@]}"; do
        target="$(echo "$symlink" | jq --tab --raw-output --exit-status '.["target"]')" || return $INVALID_TARGET
        target="$(eval echo "$target")"
        { [[ -n "$target" ]] && [[ "${target:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE_PATH
        if [[ "$action" == "create" ]] && ! [[ -e "$target" ]]; then
            return $NOT_ABSOLUTE_PATH
        fi
        link="$(echo "$symlink" | jq --tab --raw-output --exit-status '.["link"]')" || return $INVALID_SYMLINK
        link="$(eval echo "$link")"
        { [[ -n "$link" ]] && [[ "${link:0:1}" == "/" ]]; } || return $NOT_ABSOLUTE_PATH
        setup_script="$(echo "$symlink" | jq --tab --raw-output '.["setup"]')"
        setup_script="$(eval echo "$setup_script")"

        case "$action" in
            (create)
                mkdir -p "$(dirname "$link")"
                ln -sfn "$target" "$link" &>/dev/null || return $INVALID_SYMLINK
                if [[ "$setup_script" != "null" ]]; then
                    [[ -x "$setup_script" ]] || return $INVALID_SETUP_SCRIPT
                    "$setup_script" <<< "$password" || failed_setups+="$target"
                fi
            ;;
            (delete)
                { [[ -L "$link" ]] && unlink "$link" &>/dev/null; } || return $INVALID_SYMLINK
                if [[ "$setup_script" != "null" ]]; then
                    [[ -x "$setup_script" ]] || return $INVALID_SETUP_SCRIPT
                    "$setup_script" --delete <<< "$password" || failed_setups+="$target"
                fi
            ;;
        esac
    done

    if [[ ${#failed_setups[@]} -ne 0 ]]; then
        local failed_target
        echo "Setup failed for the following targets:"
        for failed_target in "${failed_setups[@]}"; do
            echo "$failed_target"
        done
    fi
}

function main () {
    ! is_running_in_iso || return $?

    eval_script_options "$@" || return $?
    verify $is_interactive input_config_path check_config_path || return $?
    verify $is_interactive input_action check_action || return $?
    verify $is_interactive input_password check_password || return $?

    install_dependencies || return $?
    parse_config_file || return $?
}

main "$@"
