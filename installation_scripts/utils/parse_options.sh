#!/usr/bin/bash

source "${INSTALL_DIR:-}/utils/make_sourced.sh"

readonly INVALID_OPTIONS=1
readonly INVALID_SHORT_OPT=2
readonly INVALID_LONG_OPT=3
readonly INVALID_INTEGER=4
readonly INVALID_ARGUMENT=5
readonly WRONG_POS_OPT=6
readonly NO_REQUIRED_OPT=7
readonly NO_VALID_USAGE=8
readonly INVALID_REQUIRED=9
readonly GETOPT_ERROR=10
readonly INVALID_CALLBACK=11
readonly INVALID_COMBINATION=12
readonly INVALID_ARRAY_REF=13
readonly INVALID_VAR_NAME=14

# Parameters:
#  $1 -> array(declare -A|-a)
#  $2 -> is_associative [bool] - Default false
function _is_array () {
    local array_name="$1"
    local is_associative="${2:-false}"
    if [[ $is_associative != true && $is_associative != false ]]; then
        return $INVALID_OPTIONS
    fi

    local variable=$(declare -p "$array_name" 2>/dev/null) || return $INVALID_VAR_NAME
    if $is_associative; then
        [[ "$variable" =~ "declare -A" ]] || return $INVALID_ARRAY_REF
    else
        [[ "$variable" =~ "declare -a" ]] || return $INVALID_ARRAY_REF
    fi
}

# Usage:
#  create_option [options] option_array(declare -A)  
# Options:
#  -s, --short-option [string]
#  -l, --long-option [string]
#  -p, --position [unsigned int]
#  -a, --argument ["true"|"optional"]
#       When argument is "true" or "optional", a callback must be provided
#  -r, --required 
#  -c, --callback [string] 
#       A callback function that receives argument in $1 parameter
#  -e, --early 
#       Bypasses all validation and invokes callback immediately
function create_option () {
    local opts
    opts="$(getopt -o "s:l:p:a:rc:e" -l "short-option:,long-option:,position:,argument:,required,callback:,early" -- "$@" 2>/dev/null)" || return $GETOPT_ERROR
    eval set -- "$opts"

    local short_option long_option position argument required callback early
    while [[ $1 != "--" ]]; do
        case $1 in
            (-s|--short-option) short_option="$2"; shift 2 ;;
            (-l|--long-option) long_option="$2"; shift 2 ;;
            (-p|--position) position="$2"; shift 2 ;;
            (-a|--argument) argument="$2"; shift 2 ;;
            (-r|--required) required="true"; shift 1 ;;
            (-c|--callback) callback="$2"; shift 2 ;;
            (-e|--early) early="true"; shift 1 ;;
        esac
    done

    if [[ -z "${short_option:-}" && -z "${long_option:-}" ]]; then
        return $INVALID_OPTIONS
    elif [[ -n "${short_option:=}" && -z "$(echo "$short_option" | grep -oP "^[a-zA-Z0-9]$")" ]]; then
        return $INVALID_SHORT_OPT
    elif [[ -n "${long_option:=}" && -z "$(echo "$long_option" | grep -oP "^[a-zA-Z0-9][a-zA-Z0-9-]*$")" ]]; then
        return $INVALID_LONG_OPT
    elif [[ -n "${position:=}" && -z "$(echo "$position" | grep -oP "^\d+$")" ]]; then
        return $INVALID_INTEGER
    elif [[ -n "${callback:=}" ]] && ! declare -f "$callback" &>/dev/null; then
        return $INVALID_CALLBACK
    elif [[ -n "${argument:=}" ]] && { [[ -z "$(echo "$argument" | grep -oE "^(true|optional)$")" ]] || [[ -z "$callback" ]]; }; then
        return $INVALID_ARGUMENT
    elif [[ -n "${early:=}" ]] && { [[ -z "$callback" ]] || [[ -n "${required:-}" ]] || [[ -n "${position}" ]]; }; then
        return $INVALID_COMBINATION
    fi
    shift 1

    _is_array "${1:-}" true || return $?
    local -n array_ref="$1"
    array_ref=(
        ["short_option"]="$short_option"
        ["long_option"]="$long_option"
        ["argument"]="$argument"
        ["position"]="$position"
        ["required"]="${required:-}"
        ["callback"]="$callback"
        ["early"]="$early"
    )

    case "$argument" in
        ("true")
            [[ -z "$short_option" ]] || array_ref["getopt_o"]="$short_option:"
            [[ -z "$long_option" ]] || array_ref["getopt_l"]="$long_option:,"
        ;;
        ("optional") 
            [[ -z "$short_option" ]] || array_ref["getopt_o"]="$short_option::"
            [[ -z "$long_option" ]] || array_ref["getopt_l"]="$long_option::,"
        ;;
        (*) 
            [[ -z "$short_option" ]] || array_ref["getopt_o"]="$short_option"
            [[ -z "$long_option" ]] || array_ref["getopt_l"]="$long_option,"
        ;;
    esac
}

# Parameters:
#  $1 -> usage_array(declare -A)
#  Each ${@:1} -> option_array(declare -A) from create_option
function set_usage () {
    _is_array "$1" true || return $?
    local -n usage_array="$1"
    shift 1

    local getopt_l=""
    local getopt_o=""

    local -a option_arrays=("$@")
    local option_array_name


    for option_array_name in "${option_arrays[@]}"; do
        _is_array "${option_array_name}" true || return $?
        local -n option_array="$option_array_name"

        getopt_l+="${option_array["getopt_l"]}"
        getopt_o+="${option_array["getopt_o"]}"
    done

    usage_array=(
        ["option_array_names"]="${option_arrays[@]}"
        ["getopt_l"]="$getopt_l"
        ["getopt_o"]="$getopt_o"
    )
}

# Parameters:
#  $1 -> only_options(declare -a)
#  $2 -> formatted_options
#  $3 -> usage_array(declare -A) from set_usage
function _filter_only_options () {
    local -n _only_options="$1"
    local formatted_options="$2"

    local -n usage_array="$3"
    IFS=' ' read -r -a option_array_names <<< "${usage_array['option_array_names']}"
    local option_array_name

    eval set -- "$formatted_options"

    while [[ $# -gt 0 && "$1" != "--" ]]; do
        for option_array_name in "${option_array_names[@]}"; do
            local -n option_array="$option_array_name"
            if [[ "$1" == "-${option_array['short_option']}" || "$1" == "--${option_array['long_option']}" ]]; then
                _only_options+=("$1")
                { [[ -n "${option_array['argument']}" ]] && shift 2; } || shift 1 
            fi
        done
    done
}

# Parameters:
#  $1 -> only_options(declare -a) from _filter_only_options
#  $2 -> usage_array(declare -A) from set_usage
function _handle_options () {
    local -n _only_options="$1"

    local -n usage_array="$2"
    local -a option_array_names
    IFS=' ' read -r -a option_array_names <<< "${usage_array['option_array_names']}"
    local option_array_name

    local -a position_matches

    for option_array_name in "${option_array_names[@]}"; do
        local -n option_array="$option_array_name"
        [[ "${option_array['required']}" != "true" ]] || [[ -n "$(echo "${_only_options[*]}" | grep -oP "(-${option_array['short_option']}|--${option_array['long_option']})")" ]] || return $NO_REQUIRED_OPT

        if [[ -n "${option_array['position']}" ]]; then
            mapfile -t position_matches <<< "$(echo "${_only_options[*]}" | grep -oP "(-${option_array['short_option']}|--${option_array['long_option']})")"
            { [[ ${#position_matches[@]} -lt 2 ]] && getopt -l "${option_array['long_option']}" -o "${option_array['short_option']}" -- "${_only_options[${option_array['position']}]}" &>/dev/null; } || return $WRONG_POS_OPT
        fi
    done
}

# Parameters:
#  $1 -> response_array(declare -A)
#  $2 -> script_options_array(declare -a)
#  Each ${@:2} -> usage_array(declare -A) from set_usage
function handle_usages () {
    _is_array "$1" true || return $?
    _is_array "$2" || return $?
    local -n response_array="$1"
    response_array["early_callback_status"]=0
    local -n script_options_array="$2"
    shift 2

    local -a usage_arrays=("$@")
    local usage_array_name

    local formatted_options
    local -a only_options
    for usage_array_name in "${usage_arrays[@]}"; do
        _is_array ${usage_array_name} true || return $?
        local -n usage_array="$usage_array_name"
        formatted_options="$(getopt -l "${usage_array["getopt_l"]}" -o "${usage_array["getopt_o"]}" -- "${script_options_array[@]}" 2>/dev/null)" || continue
        _filter_only_options only_options "$formatted_options" "$usage_array_name"

        response_array["formatted_options"]="$formatted_options"
        response_array["usage_array_name"]="$usage_array_name"

        response_array["early_mode"]=true
        invoke_callbacks "${!response_array}" || response_array["early_callback_status"]="$?" && ! (( ${response_array["early_callback_status"]} )) || return 0
        _handle_options only_options "$usage_array_name" || return $?
        response_array["early_mode"]=false

        return 0
    done
    return $NO_VALID_USAGE
}

# Parameters:
#  $1 -> response_array(declare -A) from handle_usages
function invoke_callbacks () {
    _is_array "$1" true
    local -n response_array="$1"

    local -i early_callback_status=${response_array['early_callback_status']}
    if (( early_callback_status )); then
        return $early_callback_status
    fi
    eval set -- "${response_array['formatted_options']}"

    local -n usage_array="${response_array['usage_array_name']}"
    IFS=' ' read -r -a option_array_names <<< "${usage_array['option_array_names']}"
    local option_array_name

    while [[ $# -gt 0 && "$1" != "--" ]]; do
        for option_array_name in "${option_array_names[@]}"; do
            local -n option_array="$option_array_name"
            if [[ -z "${option_array['callback']}" ]] || [[ "-${option_array['short_option']}" != "$1" && "--${option_array['long_option']}" != "$1" ]]; then
                continue
            fi
            if ${response_array['early_mode']}; then
                [[ -n "${option_array['early']}" ]] || continue
            else
                [[ -z "${option_array['early']}" ]] || continue
fi
            if [[ -n "${option_array['argument']}" ]]; then
                "${option_array['callback']}" "$2" || return $?
                shift 1
            else
                "${option_array['callback']}" || return $?
            fi
            break
        done
        shift 1
    done
}

