#!/usr/bin/bash

set -euo pipefail

declare -r INVALID_OPTIONS=1
declare -r INVALID_SHORT_OPT=2
declare -r INVALID_LONG_OPT=3
declare -r INVALID_INTEGER=4
declare -r INVALID_ARGUMENT=5
declare -r WRONG_POS_OPT=6
declare -r NO_REQUIRED_OPT=7
declare -r NO_VALID_VARIANT=8

# Options:
#  -s, --short_option [string]
#  -l, --long_option [string]
#  -p, --position [int]
#  -a, --argument [bool]
#  -r, --required [any]
# Returns: Option object
function create_option () {
    local opts="$(getopt -o "s::l::p::a::r::" -l "short_option::,long_option::,position::,argument::,required::" -- "$@")"
    eval set -- "$opts"

    while [[ $1 != "--" ]]; do
        case $1 in
            (-s|--short_option)
                local short_option="$2"
            ;;
            (-l|--long_option)
                local long_option="$2"
            ;;
            (-p|--position)
                local position="$2"
            ;;
            (-a|--argument)
                local argument="$2"
            ;;
            (-r|--required)
                local required="$2"
        esac
        shift 2
    done

    if [[ -z "${short_option:-}" && -z "${long_option:-}" ]]; then
        return $INVALID_OPTIONS
    elif [[ -n "${short_option:=}" && -z "$(echo "$short_option" | grep -oP "^[a-zA-Z0-9]$")" ]]; then
        return $INVALID_SHORT_OPT
    elif [[ -n "${long_option:=}" && -z "$(echo "$long_option" | grep -oP "^[a-zA-Z0-9][a-zA-Z0-9-]*$")" ]]; then
        return $INVALID_LONG_OPT
    elif [[ -n "${position:=}" && -z "$(echo "$position" | grep -oP "^\d+$")" ]]; then
        return $INVALID_INTEGER
    elif [[ -n "${argument:=}" && -z "$(echo "$argument" | grep -oE "^(true|false)$")" ]]; then
        return $INVALID_ARGUMENT
    fi

    echo "$long_option:$short_option:$position:$argument:${required:-}"
}

# Parameters:
#  $@ -> object Option from create_option
# Returns: object Variant
function set_option_variant () {
    local option

    local -a positional_options=()
    local -i position

    local -a required_options=()
    local required

    for option in "$@"; do
        IFS=: read -r _ _ position _ required <<< "$option"
        [[ -z "$position" ]] || positional_options+=("$option")
        [[ "$required" != "true" ]] || required_options+=("$option")
    done

    printf "%s\n%s\n%s\n" "${required_options[*]}" "${positional_options[*]}" "$*"
}

# Parameters:
#  $1 -> Variant
# Returns: getopt -l and -o arguments
function translate_variant () {
    local long_options=""
    local short_options=""

    local variant="$1"
    mapfile -t variant <<< "$variant"

    local -a options
    IFS=" " read -r -a options <<< "${variant[2]}"

    local option
    local long_option
    local short_option
    local argument

    for option in "${options[@]}"; do
        IFS=: read -r long_option short_option _ argument _ <<< "$option"
        case $argument in
            (true)
                [[ -z "$long_option" ]] || long_options+="$long_option:,"
                [[ -z "$short_option" ]] || short_options+="$short_option:"
            ;;
            (false)
                [[ -z "$long_option" ]] || long_options+="$long_option::,"
                [[ -z "$short_option" ]] || short_options+="$short_option::"
            ;;
            (*)
                [[ -z "$long_option" ]] || long_options+="$long_option,"
                [[ -z "$short_option" ]] || short_options+="$short_option"
            ;;
        esac
    done

    printf "%s\n%s\n" "$long_options" "$short_options"
}

# Parameters:
#  $1 -> options
#  $2 -> script_options
#  $3 -> is_positional
function handle_options () {
    local option
    local long_option
    local short_option
    local -i position

    for option in "${1[@]}"; do
        IFS=: read -r long_option short_option position _ _ <<< "$option"
         [[ -n "$(echo "$2" | grep -oP "($short_option|$long_option)")" ]] || ! { [[ -z "${3:-}" ]] || return 0; } || return $NO_REQUIRED_OPT
        if ! getopt -l "$long_option" -o "$short_option" -- "${2[$position]}"; then
            return $WRONG_POS_OPT
        fi
    done
}

# Parameters:
#  $1 -> script options
#  $@ -> Variant object
function handle_variants () {
    local script_options="$1"
    shift 1

    local variant
    local -a getopt_args
    local required_options
    local positional_options

    for variant in "$@"; do
        mapfile -t getopt_args <<< "$(translate_variant "$variant")"
        echo "${getopt_args[0]}"
        echo "${getopt_args[1]}"
        echo "${script_options[@]}"
        script_options=$(getopt -l "${getopt_args[0]}" -o "${getopt_args[1]}" -- "${script_options[@]}")
        echo "$script_options"
        exit 0
        mapfile -t variant <<< "$variant"
        required_options="${variant[0]}"
        positional_options="${variant[1]}"

        if handle_options "$required_options" "$(echo "$script_options" | grep -oP '\s-{1,2}[a-zA-Z0-9][a-zA-Z0-9-]*(?=\s)')" true && handle_options "$positional_options" "$(echo "$script_options" | grep -oP '\s-{1,2}[a-zA-Z0-9][a-zA-Z0-9-]*(?=\s)')"; then
            echo "$script_options"
            return 0
        fi
    done
    return $NO_VALID_VARIANT
}

function main () {
    opt1=$(create_option --long_option="help" --short_option="h" --position=1 --required=true)
    opt2=$(create_option --short_option="v" --long_option="verbose" --argument=false)
    opt3=$(create_option --short_option="o" --long_option="output" --argument=true)

    var1=$(set_option_variant "$opt1" "$opt2")
    var2=$(set_option_variant "$opt1" "$opt3")

    handle_variants "$*" "$var1" "$var2"
    echo "Variants were handled successfully"
}

main "$*"




