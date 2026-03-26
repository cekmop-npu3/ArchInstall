#!/usr/bin/bash

#TODO: Parse the file to install from

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

function check_filesystem () {
    if ! findmnt -R /mnt &>/dev/null; then
        echo "Filesystem is not mounted"
        return $NO_FILESYSTEM
    fi
}

function install_packages () {
    pacstrap -K /mnt base base-devel linux linux-firmware \
        intel-ucode git openssh grub efibootmgr lvm2 cryptsetup

    pacstrap -K /mnt \
        man-db man-pages sudo neovim vim nano \
        ninja clang rust go python python-pip nodejs yarn npm gdb make cmake pkg-config \
        networkmanager network-manager-applet bluez bluez-utils blueman \
        pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber sof-firmware \
        mesa mesa-utils vulkan-intel xorg-xwayland \
        wayland wayland-protocols xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils uwsm libnewt \
        hyprland alacritty hyprpaper copyq rofi hyprlock nautilus brightnessctl hyprshot
}

function update_mirrorlist () {
    local path="$1"
    reflector \
        --country Netherlands,Germany,France,Belgium \
        --protocol https \
        --age 12 \
        --sort rate \
        --latest 20 \
        --save "$path"
}

function main () {
    is_running_in_iso || return $?

    eval_script_options "$@"

    check_filesystem || return $?

    update_mirrorlist "/etc/pacman.d/mirrorlist"
    install_packages
    update_mirrorlist "/mnt/etc/pacman.d/mirrorlist"
}

main "$@"

