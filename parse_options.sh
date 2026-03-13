#!/usr/bin/bash

# TODO: Add more descriptive doc strings if neccessary
# TODO: Handle both output and status code of a handle_variants function

set -euo pipefail

declare -r INVALID_OPTIONS=1
declare -r INVALID_SHORT_OPT=2
declare -r INVALID_LONG_OPT=3
declare -r INVALID_INTEGER=4
declare -r INVALID_ARGUMENT=5
declare -r WRONG_POS_OPT=6
declare -r NO_REQUIRED_OPT=7
declare -r NO_VALID_VARIANT=8
declare -r INVALID_REQUIRED=9

# Options:
#  -s, --short_option [string]
#  -l, --long_option [string]
#  -p, --position [int]
#  -a, --argument ["true"|"optional"]
#  -r, --required ["true"]
# Returns: OptionObject
# Description: Returns a string of colon separated options (OptionObject) in the following format: 
#  "long_option:short_option:position:argument:required"
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
    elif [[ -n "${argument:=}" && -z "$(echo "$argument" | grep -oE "^(true|optional)$")" ]]; then
        return $INVALID_ARGUMENT
    elif [[ -n "${required:=}" && -z "$(echo "$required" | grep -o "^true$")" ]]; then
        return $INVALID_REQUIRED
    fi

    echo "$long_option:$short_option:$position:$argument:$required"
}

# Parameters:
#  $@ -> OptionObject
# Returns: VariantObject
# Description: Takes OptionObjects as its parameters, returns a string of newline separated OptionObjects which in turn are separated by a space:
#  required_OptionObjects_space_separated\n
#  positional_OptionObjects_space_separated\n
#  $@\n
function set_option_variant () {
    #TODO: Fix positional arguments
    # "long_option:short_option:position:argument:required"
    local option

    local -a positional_options=()
    local position

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
    # TODO: Add more descriptive doc string
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
            (optional)
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
#  $1 -> Either required or positional options from a VariantObject
#  $2 -> Options without possible arguments (only options) "[short|long]_option\n...". I.E. "-h\n--verbose\n"
#  $3 -> [any] - A flag which indicates that the function should check for either required options (if nothing passed) or positional ones
function handle_options () {
    local -a only_options
    mapfile -t only_options <<< "$2"

    local option
    local long_option
    local short_option
    local position
    local required

    for option in $1; do
        IFS=: read -r long_option short_option position _ required <<< "$option"

        [[ "$required" != "true" ]] || [[ -n "$(echo "$2" | grep -oP "(-$short_option|--$long_option)")" ]] || return $NO_REQUIRED_OPT

        [[ -z "$position" ]] || getopt -l "$long_option" -o "$short_option" -- "${only_options[$position]}" &>/dev/null || return $WRONG_POS_OPT
    done
}

# Parameters:
#  $1 -> Script unformatted options count
#  ${@:1:$1} -> Script unformatted options
#  $@ -> VariantObjects
# Returns: getopt options
# Description: Takes VariantObjects as its parameters. If a VariantObject satisfies script options then handle_options function checks required options persistense as well as positional options position. If no VariantObject satisfies the script options, the function exits with NO_VALID_VARIANT
# Error codes:
#  
function handle_variants () {
    local -a script_options=("${@:2:$1}")
    shift $(( $1 + 1 ))

    local -a getopt_args
    local formatted_options 
    local only_options

    local variant
    local required_options
    local positional_options

    for variant in "$@"; do
        # "long_options_getopt_argument short_options_getopt_argument"
        # I.E. "help,verbose::, hv::"
        mapfile -t getopt_args <<< "$(translate_variant "$variant")"
        formatted_options="$(getopt -l "${getopt_args[0]}" -o "${getopt_args[1]}" -- "${script_options[@]}" 2>/dev/null)" || continue

        mapfile -t variant <<< "$variant"
        required_options="${variant[0]}"
        positional_options="${variant[1]}"

        # "[short|long]_option\n..."
        # I.E. -h\n--verbose\n
        only_options="$(echo "$formatted_options" | grep -oP '(^|\s)\K(-[a-zA-Z0-9]|--[a-zA-Z0-9][a-zA-Z0-9-]*(?==|\s|$))')"

        handle_options "$required_options" "${only_options[*]}" || return $?
        handle_options "$positional_options" "${only_options[*]}" true || return $?

        echo "$formatted_options"
        return 0
    done
    return $NO_VALID_VARIANT
}

function main () {
    opt1=$(create_option --long_option="help" --short_option="h" --position=0 --required="true")
    opt2=$(create_option --short_option="v" --long_option="verbose" --argument="optional")
    opt3=$(create_option --short_option="o" --long_option="output" --argument="true")

    var1=$(set_option_variant "$opt1" "$opt2")
    var2=$(set_option_variant "$opt1" "$opt3")

    handle_variants $# "$@" "$var1" "$var2" || echo "exit status: $?" && exit 0

    echo "Variants were handled successfully"
}

main "$@"




