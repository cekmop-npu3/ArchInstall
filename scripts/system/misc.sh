#!/usr/bin/bash

set -euo pipefail

source "${SCRIPTS_DIR:-}/utils/utils.sh"
source "${SCRIPTS_DIR:-}/utils/parse_options.sh"

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
    cat >> ~/.bashrc <<< "alias update-mirrorlist='$SCRIPTS_DIR/system/mirrorlist.sh'"
    cat >> ~/.bashrc <<-'EOF'
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

function enable_services () {
    systemctl --user enable pipewire wireplumber --now
    sudo systemctl enable NetworkManager bluetooth --now
}

function main () {
    ! is_running_in_iso || return $?

    eval_script_options "$@" || return $?

    clone_repositories
    populate_bash_files
    enable_services
}

main "$@"
