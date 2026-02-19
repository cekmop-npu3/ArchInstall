#!/bin/bash


echo <<'EOF'
           _                                                  _____ 
   ___ ___| | ___ __ ___   ___  _ __        _ __  _ __  _   _|___ / 
  / __/ _ \ |/ / '_ ` _ \ / _ \| '_ \ _____| '_ \| '_ \| | | | |_ \ 
 | (_|  __/   <| | | | | | (_) | |_) |_____| | | | |_) | |_| |___) |
  \___\___|_|\_\_| |_| |_|\___/| .__/      |_| |_| .__/ \__,_|____/ 
                               |_|               |_|                
EOF

set -euo pipefail

currentDisk=
swapSize="16G"
rootSize="64G"
minDiskSize=107374182400 # 100GiB

luksContainer="cryptlvm"
luksPartitionUUID=
volumeGroup="vg0"

locale="Europe/Minsk"
hostname="cekmop-npu3"
username="cekmop-npu3"


function chooseDisk () {
    local disks=( $(lsblk --nodeps --noheadings --output NAME) EXIT )
    local diskName=

    echo "Enter your disk name: "
    select diskName in ${disks[@]}; do
	if [[ $diskName == "EXIT" ]]; then
	    return 1
	fi
        if [[ $(lsblk --bytes --nodeps --noheadings --output SIZE /dev/$diskName) -ge $minDiskSize ]]; then
	    currentDisk="/dev/$diskName"
    	    return 0 
        fi
        echo "Disk size must be at least $(($minDiskSize / 1073741824)) GiB"
        echo "Enter your disk name: "
    done
}

function diskPartition () {
    # TODO: Handle MBR, let a user choose desired partition style

    # Creates two partitions:
    # 	1. EFI System (1 GiB)
    #  	2. Linux LVM (100%FREE)
	
    wipefs -a "$currentDisk" &&
    fdisk "$currentDisk" <<< $'g\nn\n1\n\n+1G\nt\n1\n1\nn\n2\n\n\nt\n2\n31\nw\n'
}

function luksSetup () {
    # $1 -> rootPartition
   	
    cryptsetup luksFormat --batch-mode $1 &&
    cryptsetup open $1 $luksContainer &&
    pvcreate /dev/mapper/$luksContainer &&
    vgcreate $volumeGroup /dev/mapper/$luksContainer &&
    lvcreate -L $swapSize -n swap $volumeGroup &&
    lvcreate -L $rootSize -n root $volumeGroup &&
    lvcreate -l 100%FREE -n home $volumeGroup
}

function preparePartitions () {
    local rootPartition=$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+2$)")
    if [[ -z "$rootPartition" ]]; then
	return 1
    fi

    if ! luksSetup "$rootPartition"; then
	return 2
    fi
    luksPartitionUUID=$(blkid -s UUID -o value "$rootPartition")
    if [[ -z "$luksPartitionUUID" ]]; then
	return 3
    fi
    mkfs.ext4 /dev/$volumeGroup/root &&
    mkfs.ext4 /dev/$volumeGroup/home &&
    mkswap /dev/$volumeGroup/swap &&
    mount /dev/$volumeGroup/root /mnt && 
    mount --mkdir /dev/$volumeGroup/home /mnt/home &&
    swapon /dev/$volumeGroup/swap

    local bootPartition=$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+1$)")
    if [[ -z "$bootPartition" ]]; then
	return 1
    fi

    # TODO: Format MBR partition accordingly
    mkfs.fat -F32 $bootPartition &&
    mount --mkdir $bootPartition /mnt/boot
}

function populateBashFiles () {
    install -d -m 755 -o $username -g $username /mnt/home/$username

    install -m 644 -o $username -g $username /dev/stdin \
        /mnt/home/$username/.bash_profile <<-'EOF'
    if uwsm check may-start; then
	exec uwsm start hyprland.desktop
    fi
    EOF

    install -m 644 -o $username -g $username /dev/stdin \
        /mnt/home/$username/.bashrc <<-'EOF'
    export MANPAGER="nvim -c 'Man!' -"
    EOF
}

function installPackages () {
    pacstrap -K /mnt base base-devel linux linux-firmware intel-ucode git openssh grub efibootmgr lvm2 cryptsetup

    arch-chroot /mnt <<-'EOF'
    pacman --noconfirm -S man-db man-pages sudo neovim vim nano ninja clang rust go python python-pip gdb make cmake pkg-config
    pacman --noconfirm -S networkmanager network-manager-applet bluez bluez-utils blueman
    pacman --noconfirm -S pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber sof-firmware
    pacman --noconfirm -S mesa mesa-utils vulkan-intel xorg-xwayland
    pacman --noconfirm -S wayland wayland-protocols xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils uwsm libnewt
    pacman --noconfirm -S hyprland alacritty hyprpaper copyq rofi hyprlock nautilus brightnessctl hyprshot
    EOF
}

function cloneRepositories () {
    arch-chroot /mnt su - $username -c "
        mkdir -p ~/.config/nvim/pack/plugins/start &&
        git clone https://github.com/lewis6991/gitsigns.nvim.git ~/.config/nvim/pack/plugins/start/gitsigns.nvim &&
        git clone https://github.com/rebelot/kanagawa.nvim.git ~/.config/nvim/pack/plugins/start/kanagawa.nvim &&
        git clone https://github.com/iamcco/markdown-preview.nvim.git ~/.config/nvim/pack/plugins/start/markdown-preview.nvim &&
        git clone https://github.com/LuaLS/lua-language-server ~/lua-language-server &&
        cd ~/lua-language-server &&
        chmod +x make.sh &&
        ./make.sh
    "
}

function copyConfigDirectories () {
    arch-chroot /mnt su - "$username" -c "mkdir -p ~/.config"
    cp -a ./config/. /mnt/home/$username/.config/
    arch-chroot /mnt chown -R "$username:$username" "/home/$username/.config"
}

function enableServices () {
    # Still have to manually enable pipewire and wireplumber after installation
    # su - $username -c "systemctl --user enable pipewire wireplumber"
    arch-chroot /mnt <<-EOF
    systemctl enable NetworkManager
    systemctl enable bluetooth
    systemctl enable sshd
    EOF
}

function bootConfiguration () {
    arch-chroot /mnt <<-EOF
    sed -i 's/^[[:space:]]*HOOKS.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
    mkinitcpio -P
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    sed -i 's/^[[:space:]]*GRUB_CMDLINE_LINUX.*/GRUB_CMDLINE_LINUX="rd.luks.name=$luksPartitionUUID=cryptlvm root=/dev/mapper/$volumeGroup-root"/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    EOF
}

function systemConfiguration () {
    genfstab -U /mnt > /mnt/etc/fstab
    arch-chroot /mnt <<-EOF
    ln -sf /usr/share/zoneinfo/$locale /etc/localtime
    hwclock --systohc
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "$hostname" > /etc/hostname
    cat > /etc/hosts <<-EOF2
    127.0.0.1   localhost
    ::1         localhost
    127.0.1.1   $hostname.localdomain $hostname
    EOF2
    EOF
}

function userConfiguration () {
    arch-chroot /mnt <<-EOF
    passwd
    useradd -m $username
    passwd $username
    usermod -aG wheel $username
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
    chmod 0440 /etc/sudoers.d/10-wheel
    EOF
}

function main () {
    exec 2>> "./errors.log"

    if ! chooseDisk; then
        echo "Disk to format has not been chosen"
        echo "Terminating the script"
        exit 1
    fi
    if ! diskPartition; then
        echo "Unable to create partitions"
        echo "Terminating the script"
        exit 2
    fi
    if ! preparePartitions; then
	echo "Unable to format or mount partitions"
	echo "Terminating the script"
	exit 3
    fi

    installPackages
    systemConfiguration
    bootConfiguration
    userConfiguration
    populateBashFiles
    cloneRepositories
    copyConfigDirectories
    enableServices

    source ./create_symlinks.sh

    echo "Installation complete"
    echo "The system will reboot now"

    umount -R /mnt && reboot
}


main

