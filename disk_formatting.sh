#!/usr/bin/bash

# TODO: Redirect stdout/stderr of some commands in /dev/null
#       Provide an option for a passphrase in non-interactive mode 

set -euo pipefail

declare -r INSUFFICIENT_DISK_SIZE=1
declare -r INVALID_PARTITION=2
declare -r INVALID_DISK_NAME=3
declare -r INVALID_UEFI=4
declare -r INVALID_ENCRYPTION=5
declare -r INSUFFICIENT_ROOT_SIZE=6
declare -r INVALID_NUMBER=7
declare -r PARAM_SPECIFIED=8
declare -r INVALID_PASSWORD=9

declare -r INTERACTIVE_MODE=10

declare -r scriptName=$(basename "$0")
declare -r defaultPartitionTable="GPT"
declare -r volumeGroup="vg"
declare -ar partitions=( "root" "home" "swap" )

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
 -d, --disk <disk>                            Disk to use
 -s, --swap <swap_size>                       Swap size in GiB in a format <Integer>. Disabled by default
 -r, --root <root_size>                       Root size in GiB in a format <Integer>. Default/Minimum $minRootSize GiB
 -p, --partition <part_table>                 Either <GPT> or <MBR>. Default $defaultPartitionTable
 -l, --lvm                                    Option enables LVM. Disabled by default
 -L, --luks <pass>                            Enables LUKS encryption. Disabled by default. If the password given is "-", reads from PASSWORD env variable

 -h, --help                                   Display this help
EOF
}

function evalOpts () {
    local opts=$(getopt -l "help,disk:,swap:,root:,partition:,luks:,lvm,interactive" -o "hd:s:r:p:lL:i" -- "$@")
    eval set -- "$opts"

    if [[ "$1" == "--" && "$#" == 1 ]]; then
        usage
        exit 0
    fi

    if [[ "$1" == "-i" || "$1" == "--interactive" ]] && [[ "$#" == 2 ]]; then
        return 100
    else
        opts=$(getopt -l "help,disk:,swap:,root:,partition:,luks:,lvm" -o "hd:s:r:p:lL:" -- "$@")
        eval set -- "$opts"
    fi

    while [[ $1 != "--" ]]; do
        case $1 in
            (-h|--help)
                usage
                exit 0
            ;;
            (-l|--luks)
                set luks
                password="$2"
                shift 2
            ;;
            (-L|--lvm)
                set lvm
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

    shift 1
    if [[ -n ${1:-} ]]; then
        echo "Unknown param \"$1\" specified" >&2
        return $PARAM_SPECIFIED
    fi
}

function checkPassword () {
    if [[ -n "$(echo "${password:-}" | grep -oP "^-$")" ]]; then 
        password=$PASSWORD
    fi
    if [[ -z "${password:-}" ]]; then
        echo "Password was not specified"
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
    elif [[ $(( $(( $rootSize + ${swapSize:-0} + 1 )) * 1073741824 )) -ge $(lsblk --bytes --nodeps --noheadings --output SIZE "$disk") ]]; then
        echo "Not enough space on $disk for current configuration" >&2
        return $INSUFFICIENT_DISK_SIZE
    fi
}

function inputPassword () {
    read -rsp "Enter your luks password: " password
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
        disk="$diskName"
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
                set lvm
                set luks
            ;;
            (LVM)
                set lvm
            ;;
            (LUKS)
                set luks
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
    local mapperNames=
    local name=
    mapfile -t mapperNames < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "/dev/mapper/\K\S+")
    local i=
    for (( i="${#mapperNames[@]}" - 1; i>=0; i-- )); do 
        cryptsetup close "${mapperNames[i]}" 2>/dev/null
    done

    # Deactivate existing volume groups on partitions of currentDisk
    local volumeGroups=
    local vg=
    mapfile -t volumeGroups < <(pvs --noheadings -o vg_name,pv_name | grep -oP "\S+(?=\s+$disk\w+\s*$)")
    for vg in "${volumeGroups[@]}"; do
        vgchange -a n "$vg"
    done
}

function diskPartition () {
    wipefs -a "$disk"

    if [[ "$partition" == "GPT" ]]; then
        if [[ -v lvm ]]; then
            # lvm (alias lvm)
            fdisk "$disk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n\nt\n2\nlvm\nw\n'
        elif [[ -n "${swapSize-}" ]]; then
            # root, home and swap (alias swap)
            fdisk "$disk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n+'"${rootSize}"$'G\nn\n4\n\n+'"${swapSize}"$'G\nt\n4\nswap\nn\n3\n\n\nw\n'
        else
            # root, home
            fdisk "$disk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n+'"${rootSize}"$'G\nn\n3\n\n\nw\n'
        fi
    else
        if [[ -v lvm ]]; then
            # lvm (alias lvm)
            fdisk "$disk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n\nt\n2\nlvm\nw\n'
        elif [[ -n "${swapSize-}" ]]; then
            # TODO Change swap type
            # root, home and swap (alias swap)
            fdisk "$disk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n+'"${rootSize}"$'G\nn\np\n4\n\n+'"${swapSize}"$'G\nt\n4\nswap\nn\np\n\n\nw\n'
        else
            # root, home
            fdisk "$disk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n+'"${rootSize}"$'G\nn\np\n3\n\n\nw\n'
        fi
    fi
    partprobe "$disk"
    udevadm settle
}

function luksSetup () {
    local rootPartition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
    luksPartitionUUID=$(blkid -s UUID -o value $rootPartition) 
    echo "$password" | cryptsetup luksFormat -q --key-file=- "$rootPartition"
    echo "$password" | cryptsetup open -q --key-file=- $rootPartition "${partitions[0]}"
    if ! [[ -v lvm ]]; then
        local diskPartitions=
        local part=
        mapfile -t part < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+[3-9]$)")
        local -i index=1
        for part in "${diskPartitions[@]}"; do
            echo "$password" | cryptsetup luksFormat -q --key-file=- "$part"
            echo "$password" | cryptsetup open -q --key-file=- "$part" "${partitions[$index]}"
            (( ++index ))
        done
    fi
}

function lvmSetup () {
    if [[ -v luks ]]
        pvcreate -f "/dev/mapper/${partitions[0]}"
        vgcreate $volumeGroup -f "/dev/mapper/${partitions[0]}"
    else
        local rootPartition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        pvcreate -f "$rootPartition"
        vgcreate -f "$volumeGroup" "$rootPartition"

    fi

    if [[ -n "${swapSize:-}" ]]; then
        lvcreate -L "${swapSize}G" -n swap $volumeGroup
    fi
    lvcreate -L "${rootSize}G" -n root $volumeGroup
    lvcreate -l 100%FREE -n home $volumeGroup
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

function setPathes () {
    bootPath=$(lsblk -ln -o PATH,PARTN $disk | grep -Po "$disk\w+(?=\s+1$)")
    if [[ -v lvm ]]; then
        rootPath="/dev/${volumeGroup-}/${partitions[0]}"
        homePath="/dev/${volumeGroup-}/${partitions[1]}"
        if [[ -n "${swapSize:-}" ]]; then
            swapPath="/dev/${volumeGroup:-}/${partitions[2]}"
        fi
    elif [[ -v luks ]]; then
        rootPath="/dev/mapper/${partitions[0]}"
        homePath="/dev/mapper/${partitions[1]}"
        if [[ -n "${swapSize:-}" ]]; then
            swapPath="/dev/mapper/${partitions[2]}"
        fi
    else
        rootPath=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        homePath=$(lsblk -ln -o PATH,PARTN $disk | grep -Po "$disk\w+(?=\s+3$)")
        if [[ -n "${swapSize:-}" ]]; then
            swapPath="$(lsblk -ln -o PATH,PARTN $disk | grep -Po "$disk\w+(?=\s+4$)")"
        fi
    fi
}

function verify () {
    # If checkFunc returns non-zero status code
    # and the script is interactive - keeps calling chooseFunc.
    # If the script is not interactive - exits
    local notInteractive="$1"
    local chooseFunc="$2"
    local checkFunc="$3"
    while true; do
        # If interactive then chooseFunc gets called
        (( ! notInteractive )) || $chooseFunc
        # Save the status code of a checkFunc
        { $checkFunc && ! (( code = $? )); } || ! (( code = $? ))
        # If code != 0 then exit if not interactive
        { (( ! code )) && break; } || { (( notInteractive )) || exit $code; }
    done
}

function main () {
    local notInteractive=0
    evalOpts "$@" || notInteractive=$?

    verify $notInteractive chooseRootSize checkRootSize
    verify $notInteractive chooseSwapSize checkSwapSize
    verify $notInteractive chooseDisk checkDisk
    verify $notInteractive choosePartitionTable checkPartitionTable
    (( ! notInteractive )) || chooseMode
    (( ${luks-1} )) || verify $notInteractive inputPassword checkPassword

    if [[ -v luks ]]; then
        luksSetup 
    elif [[ -v lvm ]]; then 
        lvmSetup 
    fi
    setPathes
    formatPartitions $bootPath $rootPath $homePath "${swapPath:-}"
}

main $@

