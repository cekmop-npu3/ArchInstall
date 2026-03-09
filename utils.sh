#!/usr/bin/bash

declare RAN_DIRECTLY=1

declare -r INTERACTIVE_MODE=100
declare -r PARAM_SPECIFIED=101
declare -r NO_USAGE_FUNC=102

declare scriptName=$(basename "$0")

function usage () {
    cat <<EOF
Usage:
 source ./$scriptName.sh

Exit codes:
 $scriptName returns 1 if it's ran directly. Only intended to be sourced
EOF
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || { usage ; exit $RAN_DIRECTLY; }
unset -f usage
unset RAN_DIRECTLY

function inISO () {
    # Returns 0 if the script is running in iso environment 
    command -v arch-chroot &>/dev/null && [[ -d /run/archiso ]]
}

function noOptions () {
    local firstOpt="$1"
    local optCount=$2

    if [[ "$firstOpt" == "--" && "$optCount" == 1 ]]; then
        if ! declare -F usage; then
            echo "\"usage\" function was not implemented in the ${BASH_SOURCE[0]} script"
            exit $NO_USAGE_FUNC
        fi
        usage
        exit 0
    fi
}

function isNotInteractive () {
    local optCount=$1
    local shortOpt=$2
    local longOpt=$3
    local opt=$4

    if [[ "$opt" == "$shortOpt" || "$opt" == "$longOpt" ]] && [[ "$optCount" == 2 ]]; then
        return $INTERACTIVE_MODE
    fi
    return 0
}

function handleParams () {
    # $@ -> command line arguments of a script
    shift 1  # Skips "--" delimeter
    if [[ -n ${1:-} ]]; then
        echo "Unknown param \"$1\" specified" >&2
        exit $PARAM_SPECIFIED
    fi
}

function getAvailableDescriptors () {
    # Echoes the list of 2 available descriptors 
    # to save stdout and stderr to
    local -a fds=( $(ls "/proc/$$/fd") )
    local -i stdout=0
    local -i stderr=1
    local -i fd

    for fd in "${fds[@]}"; do
        if (( fd > stderr )) || ! { { (( fd > stdout )) && (( stderr = fd + 1 )); } || ! (( stderr = fd + 2 )) || (( stdout = fd + 1 )); }; then
            break
        fi
    done
    echo "$stdout $stderr"
}

function toggleOutput () {
    local -a fds=( "$@" )

    if [[ $(readlink "/proc/$$/fd/1") != "/dev/null" ]]; then
        eval "exec ${fds[0]}>&1"
        eval "exec ${fds[1]}>&2"
        exec &>/dev/null
    else
        eval "exec 1>&${fds[0]}"
        eval "exec 2>&${fds[1]}"
    fi
}

function verify () {
    # If checkFunc returns non-zero status code
    # and the script is interactive - keeps calling chooseFunc.
    # If the script is not interactive - exits
    local notInteractive="$1"
    local chooseFunc="$2"
    local checkFunc="$3"

    while true; do
        # If interactive then chooseFunc gets called
        (( ! notInteractive )) || $chooseFunc
        # Save the status code of a checkFunc
        { $checkFunc && ! (( code = $? )); } || ! (( code = $? ))
        # If code != 0 then exit if not interactive
        { (( ! code )) && break; } || { (( notInteractive )) || exit $code; }
    done
}



