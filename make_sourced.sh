#!/usr/bin/bash

declare RAN_DIRECTLY=1

declare script_name=$(basename "$0")

function usage () {
    cat <<EOF
Usage:
 source ./$script_name

Exit codes:
 $script_name returns 1 if it's ran directly. Only intended to be sourced
EOF
}

[[ "${BASH_SOURCE[0]}" != "$0" ]] || { usage ; exit $RAN_DIRECTLY; }

[[ "${BASH_SOURCE[1]}" != "$0" ]] || { usage ; exit $RAN_DIRECTLY; }

unset -f usage
unset RAN_DIRECTLY
unset script_name

