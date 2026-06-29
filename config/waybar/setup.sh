#!/usr/bin/bash

readonly WB_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || echo "ROOT_DIR env variable is not set" && return $WB_ROOT_DIR_INVALID

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || echo "ROOT_DIR is invalid" && return $WB_ROOT_DIR_INVALID

function delete () {
    $ROOT_DIR/scripts/system/install_packages.sh --file packages.txt --delete <<< $PASSWORD || return $?
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file packages.txt <<< $PASSWORD || return $?
}

source "$ROOT_DIR/scripts/utils/setup.sh"

