#!/usr/bin/bash

set -euo pipefail

source ./utils.sh

declare -r NO_FILESYSTEM=1

declare -r scriptName=$(basename "$0")

function usage () {
    cat <<EOF
Usage:
 $scriptName [options]

Options:
 -h, --help                 Show this help

Error codes:
 NO_FILESYSTEM=1            Filesystem is not mounted or installed
 PARAM_SPECIFIED=101        Unknown param is specified
EOF
}

function evalOpts () {
    local opts="$(getopt -l "help" -o "h" -- "$@")"
    eval set -- "$opts"

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    handleParams "$@"
}

function checkFilesystem () {
    if ! findmnt -R /mnt &>/dev/null || ! arch-chroot /mnt &>/dev/null; then
        echo "Filesystem is not mounted or installed"
        exit $NO_FILESYSTEM
    fi
}

function installDependencies () {
    local dependencies="grub efibootmgr"
    if [[ -n "${lvm:-}" ]]; then
        dependencies+=" lvm2"
    fi
    if [[ -n "${luksUUID:-}" ]]; then
        dependencies+=" cryptsetup"
    fi
    pacstrap -K /mnt "$dependencies"
}

function resolveCryptedPartition () {
    cryptPath="$(findmnt -o SOURCE -n /mnt)"
    local cryptList="$(lsblk -o NAME,TYPE -snl "$cryptPath")"
    cryptName="$(echo "$cryptList" | grep -oP "\w+(?=\s+crypt)")"
    if [[ -n "$cryptName" ]]; then
        luksUUID="$(blkid -s UUID -o value /dev/"$(echo "$cryptList" | grep -oP "\w+(?=\s+part)")")"
    fi
    lvm="$(echo "$cryptList" | grep -oP "\w+(?=\s+lvm)")"
}

function generateInitramfs () {
    local hooks="base systemd autodetect microcode modconf kms keyboard sd-vconsole block "
    if [[ -n "${luksUUID:-}" ]]; then
        hooks+="sd-encrypt "
    fi
    if [[ -n "${lvm:-}" ]]; then
        hooks+="lvm2 "
    fi
    hooks+="filesystems fsck"
    arch-chroot /mnt <<-EOF
    sed -i 's/^[[:space:]]*HOOKS.*/HOOKS=($hooks)/' /etc/mkinitcpio.conf
    mkinitcpio -P
EOF
}

function configureGrub () {
    arch-chroot /mnt <<-EOF
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
EOF
    if [[ -n "${luksUUID:-}" ]]; then
        arch-chroot /mnt <<-EOF
        sed -i 's/^[[:space:]]*GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="rd.luks.name=$luksUUID=$cryptName root=$cryptPath"/' /etc/default/grub
EOF
    fi
    arch-chroot /mnt <<-EOF
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
}

function main () {
    evalOpts "$@"

    checkFilesystem

    declare fds="$(getAvailableDescriptors)"
    toggleOutput $fds

    genfstab -U /mnt > /mnt/etc/fstab
    resolveCryptedPartition 
    installDependencies
    generateInitramfs
    configureGrub

    toggleOutput $fds
}

main "$@"

