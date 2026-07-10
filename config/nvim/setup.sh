#!/usr/bin/bash

readonly NV_ROOT_DIR_INVALID=3

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; return $NV_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; return $NV_ROOT_DIR_INVALID; }

function delete () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/nvim/packages.txt --delete <<< "$PASSWORD" || return $?
    rm -rf ~/neovim || true
    rm -rf ~/lua-language-server || true
    exit 0
}

function install () {
    $ROOT_DIR/scripts/system/install_packages.sh --file $ROOT_DIR/config/nvim/packages.txt <<< "$PASSWORD" || return $?
    sudo --stdin npm i -g bash-language-server 2>/dev/null <<< "$PASSWORD" || return $?

    [[ -d "$HOME/neovim" ]] || { git clone --branch release-0.12 https://github.com/neovim/neovim.git ~/neovim ; ( cd ~/neovim; make CMAKE_BUILD_TYPE=RelWithDebInfo; sudo --stdin make install 2>/dev/null <<< "$PASSWORD"; ); }

    [[ -d "$HOME/lua-language-server" ]] || { git clone https://github.com/LuaLS/lua-language-server ~/lua-language-server ; ( cd ~/lua-language-server; chmod +x make.sh; ./make.sh; ); }
    uv tool install pyrefly
    cargo install neocmakelsp

    # TODO: Write to .zshrc export statements

}

source "$ROOT_DIR/scripts/utils/setup.sh"

