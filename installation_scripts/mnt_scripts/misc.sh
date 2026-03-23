#!/usr/bin/bash

set -eus pipefail

source "${INSTALL_DIR:-}/utils.sh"

function enable_services () {
    systemctl --user enable pipewire wireplumber
    systemctl enable NetworkManager
    systemctl enable bluetooth
    systemctl enable sshd
}
function populate_bash_files () {
    ~/.bash_profile <<-'EOF'
if uwsm check may-start; then
	exec uwsm start hyprland.desktop
fi
EOF
    ~/.bashrc <<-'EOF'
export MANPAGER="nvim -c 'Man!' -"
export PATH=$PATH:~/lua-language-server/bin
EOF
}
function clone_repositoriees () {
    git clone https://github.com/LuaLS/lua-language-server ~/lua-language-server
    chmod +x ~/lua-language-server/make.sh
    ~/lua-language-server/make.sh
}

function main () {
    ! is_running_in_iso || return $?

    declare -A descriptor_array
    get_available_descriptors descriptor_array

    toggle_output descriptor_array
    clone_repositories
    populate_bash_files
    enable_services
    toggle_output descriptor_array
}
