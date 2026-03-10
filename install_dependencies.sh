#!/usr/bin/bash

#TODO: Add interactive mode

set -euo pipefail

source ./utils.sh

function checkFilesystem () {
    if ! findmnt -R /mnt &>/dev/null; then
        echo "Filesystem is not mounted"
        exit $NO_FILESYSTEM
    fi
}

function installPackages () {
    pacstrap -K /mnt base base-devel linux linux-firmware \
        intel-ucode git openssh grub efibootmgr lvm2 cryptsetup

    pacstrap -K /mnt \
        man-db man-pages sudo neovim vim nano \
        ninja clang rust go python python-pip gdb make cmake pkg-config \
        networkmanager network-manager-applet bluez bluez-utils blueman \
        pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber sof-firmware \
        mesa mesa-utils vulkan-intel xorg-xwayland \
        wayland wayland-protocols xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils uwsm libnewt \
        hyprland alacritty hyprpaper copyq rofi hyprlock nautilus brightnessctl hyprshot
}

function main () {
    inISO
    checkFilesystem

    installPackages
}

main

