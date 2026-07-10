#!/usr/bin/bash

declare _RAN_DIRECTLY=100

declare _script_name=$(basename -- "$0")

function _usage () {
    cat <<-EOF
Usage: source $_script_name

Load shared functions into the current shell. This file cannot be executed directly.

Exit status:
  0    Success
  $_RAN_DIRECTLY  File was executed instead of sourced
EOF
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || { _usage ; exit $_RAN_DIRECTLY; }

[[ "${BASH_SOURCE[1]}" != "$0" ]] || { _usage ; exit $_RAN_DIRECTLY; }

unset -f _usage
unset _RAN_DIRECTLY
unset _script_name
