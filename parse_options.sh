#!/usr/bin/bash

source ./make_sourced.sh

readonly INVALID_OPTIONS=1
readonly INVALID_SHORT_OPT=2
readonly INVALID_LONG_OPT=3
readonly INVALID_INTEGER=4
readonly INVALID_ARGUMENT=5
readonly WRONG_POS_OPT=6
readonly NO_REQUIRED_OPT=7
readonly NO_VALID_VARIANT=8
readonly INVALID_REQUIRED=9
readonly GETOPT_ERROR=10
readonly INVALID_CALLBACK=11

# Options:
#  -s, --short_option [string]
#  -l, --long_option [string]
#  -p, --position [int]
#  -a, --argument ["true"|"optional"]
#  -r, --required ["true"]
#  -c, --callback [string] - takes argument as a parameter $1
# Returns: OptionObject
# Description: Returns a string of colon separated options (OptionObject) in the following format: 
#  "long_option:short_option:position:argument:required:callback"
function create_option () {
    local opts
    opts="$(getopt -o "s::l::p::a::r::c::" -l "short_option::,long_option::,position::,argument::,required::,callback::" -- "$@" 2>/dev/null)" || return $GETOPT_ERROR
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
            ;;
            (-c|--callback)
                local callback="$2"
            ;;
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
    elif [[ -n "${callback:=}" ]] && ! declare -f "$callback" &>/dev/null; then
        return $INVALID_CALLBACK
    fi

    echo "$long_option:$short_option:$position:$argument:$required:$callback"
}

# Parameters:
#  $@ -> OptionObject
# Returns: VariantObject
# Description: Takes OptionObjects as its parameters, returns a string of newline separated OptionObjects which in turn are separated by a space:
#  required_OptionObjects_space_separated\n
#  positional_OptionObjects_space_separated\n
#  $@\n
function set_option_variant () {
    local option

    local -a positional_options=()
    local position

    local -a required_options=()
    local required

    for option in "$@"; do
        IFS=: read -r _ _ position _ required _ <<< "$option"
        [[ -z "$position" ]] || positional_options+=("$option")
        [[ "$required" != "true" ]] || required_options+=("$option")
    done

    printf "%s\n%s\n%s\n" "${required_options[*]}" "${positional_options[*]}" "$*"
}

# Parameters:
#  $1 -> VariantObject
# Returns: getopt -l and -o arguments in the following format:
#  "long_options\nshort_options\n"
function _translate_variant () {
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
        IFS=: read -r long_option short_option _ argument _ _ <<< "$option"
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
function _handle_options () {
    local -a only_options
    mapfile -t only_options <<< "$2"

    local option
    local long_option
    local short_option
    local position
    local required

    for option in $1; do
        IFS=: read -r long_option short_option position _ required _ <<< "$option"

        [[ "$required" != "true" ]] || [[ -n "$(echo "$2" | grep -oP "(-$short_option|--$long_option)")" ]] || return $NO_REQUIRED_OPT

        [[ -z "$position" ]] || getopt -l "$long_option" -o "$short_option" -- "${only_options[$position]}" &>/dev/null || return $WRONG_POS_OPT
    done
}

# Parameters:
#  $1 -> Script unformatted options count. I.E. $#
#  ${@:1:$1} -> Script unformatted options. I.E. "$@"
#  $@ -> VariantObjects
# Returns: "getopt_string\nvariant_options\n"
# Description: Takes VariantObjects as its parameters. If a VariantObject satisfies script options then _handle_options function checks required options persistense as well as positional options position. If no VariantObject satisfies the script options, the function exits with NO_VALID_VARIANT
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
        mapfile -t getopt_args <<< "$(_translate_variant "$variant")"
        formatted_options="$(getopt -l "${getopt_args[0]}" -o "${getopt_args[1]}" -- "${script_options[@]}" 2>/dev/null)" || continue

        mapfile -t variant <<< "$variant"
        required_options="${variant[0]}"
        positional_options="${variant[1]}"

        # "[short|long]_option\n..."
        # I.E. -h\n--verbose\n
        only_options="$(echo "$formatted_options" | grep -oP '(^|\s)\K(-[a-zA-Z0-9]|--[a-zA-Z0-9][a-zA-Z0-9-]*(?==|\s|$))')"

        _handle_options "$required_options" "${only_options[*]}" || return $?
        _handle_options "$positional_options" "${only_options[*]}" true || return $?

        printf "%s\n%s\n" "$formatted_options" "${variant[2]}"
        return 0
    done
    return $NO_VALID_VARIANT
}

# Parameters:
#  $1 -> formatted options (getopt string)
#  $2 -> variant options
# Description: Takes the output of a handle_variants function and invokes callbacks for variant options that define its callbacks
function invoke_callbacks () {
    local formatted_options="$1"
    local -a variant_options
    IFS=" " read -r -a variant_options <<< "$2"
    shift 2

    local variant_option
    local long_option
    local short_option
    local argument
    local required
    local callback

    eval set -- "$formatted_options"

    for variant_option in "${variant_options[@]}"; do
        IFS=: read -r long_option short_option _ argument required callback <<< "$variant_option"
        if [[ -n "$callback" && -n "$(echo "$1" | grep -oP "(-$short_option|--$long_option)")" ]]; then
            "$callback" "$argument"
            shift 1 && { [[ -n "$argument" ]] && shift 1; }
        fi
    done
}

