#!/usr/bin/bash

set -eus pipefail

source "${INSTALL_DIR:-}/utils.sh"

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

    eval_script_options "$@" || return $?

    declare -A descriptor_array
    get_available_descriptors descriptor_array

    toggle_output descriptor_array
    clone_repositories
    populate_bash_files
    enable_services
    toggle_output descriptor_array
}

main "$@"
