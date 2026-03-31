#!/usr/bin/bash

set -euo pipefail

source "${INSTALL_DIR:-}/utils/parse_options.sh"
source "${INSTALL_DIR:-}/utils/utils.sh"

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
    IFS=' ' read -r root_path root_uuid <<< "$(findmnt -o SOURCE,UUID -n /mnt)"
    root_name="$(basename -- "$root_path")"
    local root_tree="$(lsblk -o NAME,TYPE -nr "$root_path")"
    disk="/dev/$(echo "$root_tree" | awk '$2=="disk"{print $1}')"
    local partition="/dev/$(echo "$root_tree" | awk '$2=="part"{print $1}')"
    partition_style="$(lsblk -o PTTYPE --noheadings --nodeps "$disk")"
    lvm="$(echo "$root_tree" | awk '$2=="lvm"{print $1}')" || true
    luks_uuid="$(blkid -s UUID -o value "$partition")" || return 0
}

function configure_crypttab () {
    [[ -n "${luks_uuid:-}" ]] || return 0

    local mapper_name
    local crypt_device
    local crypt_uuid
    while read -r mapper_name; do
        [[ "${mapper_name:-}" != "$root_name" ]] || continue

        crypt_device="$(cryptsetup status "$mapper_name" | awk '/device:/ {print $2}')"
        crypt_uuid="$(blkid -s UUID -o value "$crypt_device")"

        echo "$mapper_name UUID=$crypt_uuid none luks" >> /mnt/etc/crypttab
    done < <(lsblk -nr -o NAME,TYPE | awk '$2=="crypt"{print $1}')
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
    if [[ "$partition_style" == "gpt" ]]; then
        arch-chroot /mnt <<< 'grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB'
    else
        arch-chroot /mnt <<< "grub-install --target=i386-pc $disk"
    fi
    arch-chroot /mnt <<< 'grub-mkconfig -o /boot/grub/grub.cfg'
    if [[ -n "${luks_uuid:-}" ]]; then
        arch-chroot /mnt <<-EOF
sed -i 's|^[#[:space:]]*GRUB_CMDLINE_LINUX=.*$|GRUB_CMDLINE_LINUX="rd.luks.name=$luks_uuid=$root_name root=UUID=$root_uuid"|' /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK=y$/GRUB_ENABLE_CRYPTODISK=y/' /etc/default/grub
EOF
    fi
    arch-chroot /mnt <<< 'grub-mkconfig -o /boot/grub/grub.cfg'
}

function main () {
    is_running_in_iso || return $?
    check_filesystem || return $?

    eval_script_options "$@" || return $?

    declare -A descriptor_array
    get_available_descriptors descriptor_array
    toggle_output descriptor_array

    genfstab -U /mnt > /mnt/etc/fstab
    resolve_crypted_partition
    configure_crypttab
    install_dependencies
    generate_initramfs
    configure_grub

    toggle_output descriptor_array
}

main "$@"
