#!/usr/bin/bash

readonly HP_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $HP_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $HP_ROOT_DIR_INVALID; }

function delete () {
    flatpak uninstall -y --delete-data net.christianbeier.Gromit-MPX || true
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/hypr/packages.txt --delete <<< "$PASSWORD" || return $?
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/hypr/packages.txt <<< "$PASSWORD" || return $?
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub net.christianbeier.Gromit-MPX
}

source "$ROOT_DIR/scripts/utils/setup.sh"
