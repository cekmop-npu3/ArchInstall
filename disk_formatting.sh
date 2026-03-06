#!/usr/bin/bash

# TODO: Delete all echo messages with errors; provide error codes section in help

set -euo pipefail

source ./utils.sh

declare -r INSUFFICIENT_DISK_SIZE=1
declare -r INVALID_PARTITION=2
declare -r INVALID_DISK_NAME=3
declare -r INVALID_UEFI=4
declare -r INSUFFICIENT_ROOT_SIZE=6
declare -r INVALID_NUMBER=7
declare -r INVALID_PASSWORD=8

declare -r scriptName=$(basename "$0")
declare -r defaultPartitionTable="GPT"
declare -r volumeGroup="vg"
declare -ar partitions=( "root" "home" "swap" )
declare -ar luksPartitions=( "cryptroot" "crypthome" "cryptswap" "cryptlvm" )

# Size in GiB
declare -ir minDiskSize=128 
declare -ir minRootSize=64
declare -ir minBootSize=1

function usage () {
    cat <<EOF
Usage:
 $scriptName [options]
 $scriptName [-i|--interactive]

Options:
 -d, --disk <disk>                            Disk to use "/dev/disk_name"
 -s, --swap <swap_size>                       Swap size in GiB in a format <Integer>. Disabled by default
 -r, --root <root_size>                       Root size in GiB in a format <Integer>. Default/Minimum $minRootSize GiB
 -p, --partition <part_table>                 Either <GPT> or <MBR>. Default $defaultPartitionTable
 -l, --lvm                                    Option enables LVM. Disabled by default
 -L, --luks <pass>                            Enables LUKS encryption. Disabled by default. If the password given is "-", reads from PASSWORD env variable

 -h, --help                                   Display this help

Exit codes:
 INSUFFICIENT_DISK_SIZE=1                     Not enough space on disk for current configuration
 INVALID_PARTITION=2                          Must be either "GPT" or "MBR"
 INVALID_DISK_NAME=3                          Disk name is invalid or not specified
 INVALID_UEFI=4                               UEFI is not detected
 INSUFFICIENT_ROOT_SIZE=6                     Root size must be at least $minRootSize GiB
 INVALID_NUMBER=7                             Nan was passed as a parameter
 INVALID_PASSWORD=8                           Password is empty or passwords don't match
EOF
}

function evalOpts () {
    local opts=$(getopt -l "help,disk:,swap:,root:,partition:,luks:,lvm,interactive" -o "hd:s:r:p:lL:i" -- "$@")
    eval set -- "$opts"
    noOptions "$1" $#
    isNotInteractive $# "-i" "--interactive" $1 || return $?
    opts=$(getopt -l "help,disk:,swap:,root:,partition:,luks:,lvm" -o "hd:s:r:p:lL:" -- "$@")
    eval set -- "$opts"

    while [[ $1 != "--" ]]; do
        case $1 in
            (-h|--help)
                usage
                exit 0
            ;;
            (-L|--luks)
                luks=0
                password="$2"
                shift 2
            ;;
            (-l|--lvm)
                lvm=0
                shift 1
            ;;
            (-d|--disk)
	            disk="$2"
                shift 2
            ;;
            (-s|--swap)
                swapSize="$2"
                shift 2
            ;;
            (-r|--root)
                rootSize="$2"
                shift 2
            ;;
            (-p|--partition)
                partition="$2"
                shift 2
            ;;
        esac
    done

    handleParams "$@"
}

function checkPassword () {
    if [[ -n "$(echo "${password:-}" | grep -oP "^-$")" ]]; then 
        password="${PASSWORD-}"
    fi
    if [[ -z "${password:-}" ]]; then
        echo "Password cannot be empty"
        return $INVALID_PASSWORD
    elif [[ "${verifyPass+set}" && "$password" != "${verifyPass-}" ]]; then
        echo "Passwords don't match"
        return $INVALID_PASSWORD
    fi
}

function checkRootSize () {
    if [[ -z "${rootSize:-}" ]]; then
        rootSize=$minRootSize
        return 0
    elif [[ -z "$(echo "$rootSize" | grep -oP '^\d+$')" ]]; then
        echo "Root size must be of Integer type" >&2
        return $INVALID_NUMBER
    elif [[ "$rootSize" -lt "$minRootSize" ]]; then
        echo "Root size must be at least $minRootSize GiB" >&2
        return $INSUFFICIENT_ROOT_SIZE
    fi
}

function checkSwapSize () {
    if [[ -z "${swapSize:-}" ]]; then
        return 0
    elif [[ -z "$(echo "$swapSize" | grep -oP '^\d+$')" ]]; then
        echo "Swap size must be of Integer type" >&2
        return $INVALID_NUMBER
    elif [[ -n "$(echo "$swapSize" | grep -oP '^0+')" ]]; then
        unset swapSize
    fi
}

function checkPartitionTable () {
    if [[ -z "${partition:-}" ]]; then
        partition=$defaultPartitionTable
        return 0
    elif [[ "$partition" != "GPT" && "$partition" != "MBR" ]]; then
        echo "Partition style must be either \"GPT\" or \"MBR\", not $partition" >&2
        return $INVALID_PARTITION
    elif [[ "$partition" == "GPT" && ! -d "/sys/firmware/efi" ]]; then 
        echo "UEFI is not detected" >&2
        return $INVALID_UEFI
    fi
}

function checkDisk () {
    if [[ -z "${disk:-}" || -z "$(echo "$disk" | grep -oP "/dev/\w+")" ]]; then
        echo "Disk name is invalid or not specified" >&2
        return $INVALID_DISK_NAME
    elif [[ $(( $(( $rootSize + ${swapSize:-0} + $minBootSize )) * 1073741824 )) -ge $(lsblk --bytes --nodeps --noheadings --output SIZE "$disk") ]]; then
        echo "Not enough space on $disk for current configuration" >&2
        return $INSUFFICIENT_DISK_SIZE
    fi
}

function inputPassword () {
    read -rsp "Enter your luks password: " password
    echo
    read -rsp "Retype your luks password: " verifyPass
    echo
}

function chooseRootSize () {
    read -rp "Enter root size (Default/Minimum $minRootSize GiB): " rootSize
}

function chooseDisk () {
    local disks=( $(lsblk --nodeps --noheadings --output NAME) "EXIT" )
    local diskName

    echo "Enter your disk name or EXIT to exit the script: "
    select diskName in ${disks[@]}; do
	    if [[ "$diskName" == "EXIT" ]]; then
	        exit 0
        fi
        disk="/dev/$diskName"
        break
    done
}

function chooseSwapSize () {
    read -rp "Enter swapSize (Default: 0): " swapSize
}

function chooseMode () {
    local modes=( "LVM+LUKS" "LVM" "LUKS" "NONE" "EXIT" )
    local mode=

    echo "Enter your mode, or EXIT to exit the script: "
    select mode in "${modes[@]}"; do
        case $mode in
            ("LVM+LUKS")
                lvm=0
                luks=0
            ;;
            (LVM)
                lvm=0
            ;;
            (LUKS)
                luks=0
            ;;
            (EXIT)
                exit 0
            ;;
        esac
        break
    done
}

function choosePartitionTable () {
    local partitionsTables=( "GPT" "MBR" "EXIT" )
    local part=

    echo "Enter your partition style, or EXIT to exit the script: "
    select part in "${partitionsTables[@]}"; do
        if [[ "$part" == "EXIT" ]]; then
            exit 0
        fi
        if [[ -n "${part:-}" ]]; then
            partition="$part"
        fi
        break
    done
}

function diskCleanup () {
    swapoff -a

    # Remove existing mapper names
    local mapperNames
    local name
    mapfile -t mapperNames < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "/dev/mapper/\K\S+")
    local i=
    for (( i="${#mapperNames[@]}" - 1; i>=0; i-- )); do 
        cryptsetup close "${mapperNames[i]}" 
    done

    # Deactivate existing volume groups on partitions of current disk
    local volumeGroups=
    local vg=
    mapfile -t volumeGroups < <(pvs --noheadings -o vg_name,pv_name | grep -oP "\S+(?=\s+$disk\w+\s*$)")
    for vg in "${volumeGroups[@]}"; do
        vgchange -a n "$vg"
    done
}

function diskPartition () {
    local script=""
    if (( ${lvm:-1} )) && [[ -n "$swapSize" ]]; then
        local total=$(( $(lsblk --bytes --nodeps --noheadings --output SIZE "$disk") / 1024 / 1024 / 1024 ))
        local homeSize=$(( total - rootSize - minBootSize - ${swapSize:-0} ))
    fi

    if [[ "$partition" == "GPT" ]]; then
        script+="label: gpt\n"
        script+="size=${minBootSize}G\n"
    else
        script+="label: dos\n"
        script+="size=${minBootSize}G, bootable\n"
    fi

    if (( ! ${lvm:-1} )); then
        # lvm
        script+="size=+, type=V\n"
    elif [[ -n "$swapSize" ]]; then
        # root, home, swap
        script+="size=${rootSize}G\n"
        script+="size=${homeSize}G\n"
        script+="size=+, type=swap\n"
    else
        # root, home 
        script+="size=${rootSize}G\n"
        script+="size=+\n"
    fi

    echo -e "$script" | sfdisk --lock --force --no-reread --no-tell-kernel --quiet --wipe always --wipe-partitions always "$disk"

    partprobe "$disk"
    udevadm settle
}

function luksSetup () {
    if (( ${lvm:-1} )); then
        local -a diskPartitions
        mapfile -t diskPartitions < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+[2-9]$)")
        local -i index
        for (( index=0; index<${#diskPartitions[@]}; ++index )); do
            echo "$password" | cryptsetup luksFormat -q --key-file=- "${diskPartitions[$index]}"
            echo "$password" | cryptsetup open -q --key-file=- "${diskPartitions[$index]}" "${luksPartitions[$index]}"
        done
    else
        local rootPartition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        echo "$password" | cryptsetup luksFormat -q --key-file=- "$rootPartition"
        echo "$password" | cryptsetup open -q --key-file=- $rootPartition "${luksPartitions[3]}"
    fi
}

function lvmSetup () {
    if (( ! ${luks:-1} )); then
        pvcreate -ff "/dev/mapper/${luksPartitions[3]}"
        vgcreate $volumeGroup -f "/dev/mapper/${luksPartitions[3]}"
    else
        local rootPartition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        pvcreate -ff "$rootPartition"
        vgcreate -f "$volumeGroup" "$rootPartition"
    fi

    if [[ -n "${swapSize:-}" ]]; then
        lvcreate --yes --wipesignatures y -L "${swapSize}G" -n ${partitions[2]} $volumeGroup
    fi
    lvcreate --yes --wipesignatures y -L "${rootSize}G" -n ${partitions[0]} $volumeGroup
    lvcreate --yes --wipesignatures y -l 100%FREE -n ${partitions[1]} $volumeGroup
}

function formatPartitions () {
    mkfs.ext4 -FF "$rootPath"
    mkfs.ext4 -FF "$homePath"
    mount "$rootPath" /mnt
    mount --mkdir "$homePath" /mnt/home
    if [[ -n "${swapPath:-}" ]]; then
        mkswap "$swapPath"
        swapon "$swapPath"
    fi
    if [[ "$partition" == "GPT" ]]; then
        mkfs.fat -F32 "$bootPath"
    else
        mkfs.ext4 -FF "$bootPath"
    fi
    mount --mkdir $bootPath /mnt/boot
}

function setPaths () {
    bootPath=$(lsblk -ln -o PATH,PARTN $disk | grep -Po "$disk\w+(?=\s+1$)")
    local arrayOfPaths="$1"
    mapfile -t arrayOfPaths <<< "$arrayOfPaths"
    rootPath="${arrayOfPaths[0]}"
    homePath="${arrayOfPaths[1]}"
    if [[ -n "${swapSize:-}" ]]; then
        swapPath="${arrayOfPaths[2]}"
    fi
}

function main () {
    local notInteractive=0
    evalOpts "$@" || notInteractive=$?

    verify $notInteractive chooseRootSize checkRootSize
    verify $notInteractive chooseSwapSize checkSwapSize
    verify $notInteractive chooseDisk checkDisk
    verify $notInteractive choosePartitionTable checkPartitionTable
    verify $notInteractive chooseMode :

    local fds="$(getAvailableDescriptors)"
    toggleOutput $fds

    umount -R /mnt || true

    diskCleanup
    diskPartition
    diskCleanup

    if (( ! ${luks:-1} )); then
        toggleOutput $fds
        verify $notInteractive inputPassword checkPassword
        toggleOutput $fds
        luksSetup 
        if (( ${lvm:-1} )); then
            setPaths "$(printf "/dev/mapper/%s\n" "${luksPartitions[@]}")"
        fi
    fi
    if (( ! ${lvm:-1} )); then 
        lvmSetup 
        setPaths "$(printf "/dev/$volumeGroup/%s\n" "${partitions[@]}")"
    elif (( ${luks:-1} )); then
        setPaths "$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+[2-9]$)")" 
    fi

    formatPartitions $bootPath $rootPath $homePath "${swapPath-}"

    toggleOutput $fds
}

main $@

