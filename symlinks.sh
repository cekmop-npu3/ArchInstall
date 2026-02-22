#!/bin/bash

set -euo pipefail

readonly INVALID_USERNAME=1
readonly INVALID_CONFIG_PATH=2
readonly INVALID_ACTION=3
readonly INVALID_CONFIG_ARGS=4
readonly INVALID_SYMLINK=5
readonly PARAM_SPECIFIED=6

readonly scriptName=$(basename "$0")

function usage () {
    # $1 -> Script name

    cat <<EOF
Usage:
 $scriptName [options] 

Options:
 -u, --username <username>                User to install config files to
 -p, --configPath <path_to_config_file>   Path to config file with symlink targets
 -a, --action <action>                    Whether to "create" or "delete" symlinks 

 -h, --help                               Display this help
EOF
    exit 0
}

function resolveOpts () {
    local newOpts=$(getopt -l "help,username:,configPath:,action:" -o "hu:p:a:" -- $@)
    eval set -- "$newOpts"
    
    if [[ "$1" == "--" && "$#" == 1 ]]; then
	    usage
    fi

    while [[ $1 != "--" ]]; do
	    case $1 in 
	        (-h|--help)
		        usage
	        ;;
	        (-u|--username)
		        if ! id "${2:-}" &>/dev/null; then
		            echo "User \"$2\" does not exist"
		            exit $INVALID_USERNAME
		        fi
		        username="$2"
	        ;;
	        (-p|--configPath)
		        if ! [[ -e "$2" ]]; then
		            echo "Configuration file \"$2\" is not found"
		            exit $INVALID_CONFIG_PATH
		        fi
		        configPath="$2"
	        ;;
	        (-a|--action)
		        if [[ ${2:="create"} != "create" && "$2" != "delete" ]]; then
		            echo "Action parameter must be either create or delete, not \"$2\""
		            exit $INVALID_ACTION
		        fi
		        action="$2"
	        ;;
	    esac
	    shift 2
    done

    shift 1
    if [[ -n ${1:-} ]]; then
	    echo "Unknown param \"$1\" specified"
	    exit $PARAM_SPECIFIED
    fi
}

function checkVariables () {
    if [[ -z ${username:-} ]]; then 
	    echo "Username was not specified"
	    exit $INVALID_USERNAME
    elif [[ -z ${configPath:-} ]]; then 
	    echo "Config path was not specified"
	    exit $INVALID_CONFIG_PATH
    elif [[ -z ${action:-} ]]; then 
	    echo "Action was not specified"
	    exit $INVALID_ACTION
    fi
}

function expandConfigFile () {
    local subs=( $(grep -oP '\$\K\w+(?=\s*|$|/)' "$configPath") )
    local sub=
    for sub in ${subs[@]}; do
	    local -n ref="$sub"
	    echo "$ref"
	    sed -i "s/\$$sub/$ref/" $configPath
    done
}

function parseConfig () {
    exec 2>> "./errors.log"

    resolveOpts $@
    checkVariables
    expandConfigFile

    mapfile -t targets < "$configPath"
    local args=
    local target=
    local link=
    local -i lineCount=0

    for args in "${targets[@]}"; do
	    target=$(echo "$args" | grep -oP '^\S+(?=\s+)')
	    link=$(echo "$args" | grep -oP '\s+\K.+$')

	    if ! [[ -e "$target" ]]; then
	        echo "Target is invalid"
	        exit $INVALID_CONFIG_ARGS
	    fi

	    case $action in
	        (create)
		        if ! ln -sf "$target" "$link"; then
		            echo "Invalid args at line: $lineCount"
		            exit $INVALID_CONFIG_ARGS
		        fi
	        ;;
	        (delete)
		        if ! unlink "$link"; then
		            echo "Invalid symlink at line: $lineCount"
		            exit $INVALID_SYMLINK
		        fi
	        ;;
	    esac
	    (( ++lineCount ))
    done
}

parseConfig $@
