#!/usr/bin/bash

readonly PYPR_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $PYPR_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $PYPR_ROOT_DIR_INVALID; }

function delete () {
    uv tool uninstall pyprland || true
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/pypr/packages.txt --delete <<< "$PASSWORD" || return $?
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/pypr/packages.txt <<< "$PASSWORD" || return $?
    uv tool install pyprland
}

source "$ROOT_DIR/scripts/utils/setup.sh"
