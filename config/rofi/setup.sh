#!/usr/bin/bash

readonly RF_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $RF_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $RF_ROOT_DIR_INVALID; }

function delete () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/rofi/packages.txt --delete <<< $PASSWORD || return $?
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/rofi/packages.txt <<< $PASSWORD || return $?
}

source "$ROOT_DIR/scripts/utils/packages.sh"

