#!/usr/bin/bash

set -euo pipefail

source "${INSTALL_DIR:-}/utils/utils.sh"
source "${INSTALL_DIR:-}/utils/parse_options.sh"

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -h, --help                 Show this help
EOF
    exit 0
}

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1
    create_option --long-option="help" --short-option="h" --callback=usage opt1

    declare -A usage1
    set_usage usage1 opt1

    declare -A response
    handle_usages response script_options usage1 || return $?

    invoke_callbacks response
}

function populate_bash_files () {
    cat >> ~/.bash_profile <<-'EOF'
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi
EOF
    cat >> ~/.bashrc <<-'EOF'
alias update-mirrorlist="reflector --country Netherlands,Germany,France,Belgium --protocol https --age 24 --sort rate --latest 20 --save /etc/pacman.d/mirrorlist"
export MANPAGER="nvim -c 'Man!' -"
export PATH=$PATH:~/lua-language-server/bin
EOF
}

function clone_repositories () {
    git clone https://github.com/LuaLS/lua-language-server ~/lua-language-server
    chmod +x ~/lua-language-server/make.sh
    (
        cd ~/lua-language-server
        ./make.sh
    )

    git clone --branch release-0.12 https://github.com/neovim/neovim.git ~/neovim
    (
        cd ~/neovim
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install
    )

    git clone https://aur.archlinux.org/yay.git ~/yay
    (
        cd ~/yay
        makepkg --noconfirm -si
    )
}

function main () {
    ! is_running_in_iso || return $?

    eval_script_options "$@" || return $?

    clone_repositories
    populate_bash_files
}

main "$@"
