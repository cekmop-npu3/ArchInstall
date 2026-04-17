#!/usr/bin/bash

declare _RAN_DIRECTLY=100

declare _script_name=$(basename -- "$0")

function _usage () {
    cat <<EOF
Usage:
 source ./$_script_name

Exit codes:
 $_script_name returns $_RAN_DIRECTLY if it's ran directly. Only intended to be sourced
EOF
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || { _usage ; exit $_RAN_DIRECTLY; }

[[ "${BASH_SOURCE[1]}" != "$0" ]] || { _usage ; exit $_RAN_DIRECTLY; }

unset -f _usage
unset _RAN_DIRECTLY
unset _script_name

