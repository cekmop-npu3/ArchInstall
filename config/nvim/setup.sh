#!/usr/bin/bash

readonly NV_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $NV_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $NV_ROOT_DIR_INVALID; }

function delete () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/nvim/packages.txt --delete <<< $PASSWORD || return $?
    rm -rf ~/neovim
    rm -rf ~/lua-language-server
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/nvim/packages.txt <<< $PASSWORD || return $?
    sudo npm i -g bash-language-server <<< $PASSWORD || return $?

    git clone --branch release-0.12 https://github.com/neovim/neovim.git ~/neovim
    (
        cd ~/neovim
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install <<< $PASSWORD
    )

    git clone https://github.com/LuaLS/lua-language-server ~/lua-language-server
    chmod +x ~/lua-language-server/make.sh
    (
        cd ~/lua-language-server
        ./make.sh
    )
}

source "$ROOT_DIR/scripts/utils/packages.sh"

