#!/usr/bin/bash

set -euo pipefail

readonly NO_ARG=1
readonly UNKNOWN_KEYWORD=2
readonly INVALID_USERNAME=3
readonly INVALID_CONFIG_DIR=4
readonly INVALID_CONFIG_FILE=5
readonly INVALID_ACTION=6
readonly INVALID_CONFIG_ARGS=7
readonly INVALID_SYMLINK=8

function resolveArgs () {
    # TODO: Use getopts
    while [[ $# -gt 0 ]]; do
	case $1 in
	    (username|configPath|configFile|action)
		local -n ref=$1
		if [[ -z ${2:-} ]]; then
		    echo "\"$1\" keyword followed by no value"
		    exit $NO_ARG
		fi
		ref=$2
		checkArg $1
		shift 2
	    ;;
	    (*)
		echo "Unknow keyword \"$1\" passed"
		exit $UNKNOWN_KEYWORD
	    ;;
	esac
    done
}

function checkArg () {
    case $1 in
	(username)
	    if ! id ${username:="root"} &>/dev/null; then
		echo "User \"$username\" does not exist"
		exit $INVALID_USERNAME
	    fi
	;;
	(configPath)
	    if ! [[ -d ${configPath:="./.config"} ]]; then
		echo "Configuration directory \"$configPath\"is not found"
		exit $INVALID_CONFIG_DIR
	    fi
	;;
	(configFile)
	    if ! [[ -e "$configPath/${configFile:=".__LINK__"}" ]]; then
		echo "Configuration file \"$configFile\" is not found"
		exit $INVALID_CONFIG_FILE
	    fi
	(action)
	    if [[ "$action" != "create" && "$action" != "delete" ]]; then
		echo "\"action\" parameter must be either create or delete, not $action"
		exit $INVALID_ACTION
	    fi
	;;
    esac
}

function expandConfigFile () {
    local subs=( $(grep -oP "\$\w+(?=[ /]|$)" $configPath/$configFile) )
    local sub=
    for sub in ${subs[@]}; do
	local -n ref=$sub
	sed -i "s/$sub/$ref/" $configPath/$configFile
    done
}

function parseConfig () {
    exec 2>> "./errors.log"
    resolveArgs $@
    expandConfigFile
    mapfile -t targets < "$configPath/$configFile"
    local target=
    local -i lineCount=0
    for args in ${targets[@]}; do
	case $action in
	    (create)
		if ! ln -sf "$args"; then
		    echo "Invalid args at line: $lineCount"
		    exit $INVALID_CONFIG_ARGS
		fi
	    ;;
	    (delete)
		if ! unlink $(grep -oP "(?=\w+\s+)\w+" "$args"); then
		    echo "Invalid symlink at line: $lineCount"
		    exit $INVALID_SYMLINK
		fi
	    ;;
	esac
	(( lineCount++ ))
    done
}

parseConfig $@

