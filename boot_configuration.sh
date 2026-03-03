#!/usr/bin/bash


function generateInitramfs () {
    if (( ! $lvm )) && ((! $luks )); then
        arch-chroot /mnt <<-EOF
        sed -i 's/^[[:space:]]*HOOKS.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
        EOF
    elif (( ! $lvm )); then
        arch-chroot /mnt <<-EOF
        sed -i 's/^[[:space:]]*HOOKS.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
        EOF
    else
        arch-chroot /mnt <<-EOF
        sed -i 's/^[[:space:]]*HOOKS.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
        EOF
    fi
    arch-chroot /mnt <<< 'mkinitcpio -P'
}

function configureGrub () {
    if [[ -n $luksUUID ]]; then
        arch-chroot /mnt <<-EOF
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
        sed -i 's/^[[:space:]]*GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="rd.luks.name=$luksUUID=$rootName root=$rootPath"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
        EOF
    fi
}



