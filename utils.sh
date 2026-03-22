#!/usr/bin/bash

source ./make_sourced.sh

readonly NOT_IN_ISO=100
readonly INVALID_FUNCTION=101

readonly script_name=$(basename "$0")

function is_running_in_iso () {
    if ! { command -v arch-chroot &>/dev/null && [[ -d /run/archiso ]]; }; then
        return $NOT_IN_ISO
    fi
}

# Parameters:
#  $1 -> func_name
function is_defined_function () {
    if ! declare -f "$1" &>/dev/null; then
        return $INVALID_FUNCTION
    fi
}

# Parameters:
#  $1 -> descriptor_array(declare -A)
function get_available_descriptors () {
    local -n descriptor_array="$1"

    local -a fds=( $(ls "/proc/$$/fd") )
    local -i stdout=0
    local -i stderr=1
    local -i fd

    for fd in "${fds[@]}"; do
        if (( fd > stderr )) || ! { { (( fd > stdout )) && (( stderr = fd + 1 )); } || ! (( stderr = fd + 2 )) || (( stdout = fd + 1 )); }; then
            break
        fi
    done
    descriptor_array=(
        ["stdout"]=stdout
        ["stderr"]=stderr
    )
}

# Parameters:
#  $1 -> descriptor_array(declare -A) from get_available_descriptors
function toggle_output () {
    local -n descriptor_array="$1"

    if [[ $(readlink "/proc/$$/fd/1") != "/dev/null" ]]; then
        eval "exec ${descriptor_array['stdout']}>&1"
        eval "exec ${descriptor_array['stderr']}>&2"
        exec &>/dev/null
    else
        eval "exec 1>&${descriptor_array['stdout']}"
        eval "exec 2>&${descriptor_array['stderr']}"
    fi
}

# Parameters:
#  $1 -> is_interactive [bool]
#  $2 -> input_func(declare -f)
#  $3 -> check_func(declare -f)
# Description:
#  If check_func returns non-zero status code
#  and the script is interactive - keeps calling input_func.
#  If the script is not interactive - returns check_func status code
function verify () {
    is_defined_function "$2" || return $?
    is_defined_function "$3" || return $?

    local is_interactive="$1"
    local input_func="$2"
    local check_func="$3"

    while true; do
        # If interactive then chooseFunc gets called
        (( is_interactive )) || $input_func
        # Save the status code of a checkFunc
        { $check_func && ! (( code = $? )); } || ! (( code = $? ))
        # If code != 0 then exit if not interactive
        { (( ! code )) && break; } || { (( ! is_interactive )) || return $code; }
    done
}



