#!/usr/bin/bash

set -euo pipefail

source ./utils.sh
source ./parse_options.sh

readonly NO_FILESYSTEM=1

function usage () {
    cat <<EOF
Usage:
 $script_name [options]

Options:
 -h, --help                 Show this help

Error codes:
 NO_FILESYSTEM=1            Filesystem is not mounted
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

function install_dependencies () {
    local dependencies="grub efibootmgr"
    if [[ -n "${lvm:-}" ]]; then
        dependencies+=" lvm2"
    fi
    if [[ -n "${luks_uuid:-}" ]]; then
        dependencies+=" cryptsetup"
    fi
    pacstrap -K /mnt $dependencies
}

function resolve_crypted_partition () {
    crypt_path="$(findmnt -o SOURCE -n /mnt)"
    local crypt_list="$(lsblk -o NAME,TYPE -snl "$crypt_path")"
    crypt_name="$(echo "$crypt_list" | grep -oP "\w+(?=\s+crypt)")"
    disk="/dev/$(echo "$crypt_list" | grep -oP "\w+(?=\s+disk)")"
    partition="$(lsblk -o PTTYPE --noheadings --nodeps "$disk")"
    if [[ -n "$crypt_name" ]]; then
        luks_uuid="$(blkid -s UUID -o value /dev/"$(echo "$crypt_list" | grep -oP "\w+(?=\s+part)")")"
    fi
    lvm="$(echo "$crypt_list" | grep -oP "\w+(?=\s+lvm)")"
}

function generate_initramfs () {
    local hooks="base systemd autodetect microcode modconf kms keyboard sd-vconsole block "
    if [[ -n "${luks_uuid:-}" ]]; then
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

function configure_grub () {
    if [[ "$partition" == "gpt" ]]; then
        arch-chroot /mnt <<< 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB'
    else
        arch-chroot /mnt <<< "grub-install --target=i386-pc $disk"
    fi
    arch-chroot /mnt <<< 'grub-mkconfig -o /boot/grub/grub.cfg'
    if [[ -n "${luks_uuid:-}" ]]; then
        arch-chroot /mnt <<-EOF
sed -i 's|^GRUB_CMDLINE_LINUX=""$|GRUB_CMDLINE_LINUX="rd.luks.name=$luks_uuid=$crypt_name root=$crypt_path"|' /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK=y$/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
EOF
    fi
    arch-chroot /mnt <<< 'grub-mkconfig -o /boot/grub/grub.cfg'
}

function main () {
    is_running_is_iso || return $?
    check_filesystem || return $?

    eval_script_options "$@" || return $?

    declare -A descriptor_array
    get_available_descriptors descriptor_array
    toggle_output descriptor_array

    genfstab -U /mnt > /mnt/etc/fstab
    resolve_crypted_partition 
    install_dependencies
    generate_initramfs
    configure_grub

    toggle_output descriptor_array
}

main "$@"

