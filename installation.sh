#!/usr/bin/bash


cat <<'EOF'
           _                                                  _____ 
   ___ ___| | ___ __ ___   ___  _ __        _ __  _ __  _   _|___ / 
  / __/ _ \ |/ / '_ ` _ \ / _ \| '_ \ _____| '_ \| '_ \| | | | |_ \ 
 | (_|  __/   <| | | | | | (_) | |_) |_____| | | | |_) | |_| |___) |
  \___\___|_|\_\_| |_| |_|\___/| .__/      |_| |_| .__/ \__,_|____/ 
                               |_|               |_|                
EOF

set -euo pipefail

readonly INSUFFICIENT_DISK_SIZE=1
readonly INVALID_TIMEZONE=2
readonly INVALID_PARTITION=3
readonly INVALID_DISK_NAME=4
readonly INVALID_UEFI=5
readonly INVALID_USERNAME=6
readonly INVALID_HOSTNAME=7
readonly INVALID_ENCRYPTION=9
readonly INSUFFICIENT_ROOT_SIZE=10
readonly INVALID_NUMBER=11
readonly SYMLINK_ERROR=12
readonly PARAM_SPECIFIED=13

readonly INTERACTIVE_MODE=100

readonly scriptName=$(basename "$0")
readonly minDiskSize=100 
readonly minRootSize=64
readonly configPath="./config/.LINK"

function usage () {
    cat <<EOF
Usage:
 $scriptName [options]
 $scriptName [-i|--interactive]

Options:
 -u, --username <username>                    Username to use
 -d, --disk <disk>                            Disk to use
 -l, --localtime <timezone>                   Timezone in a format <Area/Location> 
 -H, --hostname <hostname>                    Hostname to use
 -s, --swap <swap_size>                       Swap size in GiB in a format <Integer>. Disabled by default
 -r, --root <root_size>                       Root size in GiB in a format <Integer>. Minimum 64 GiB
 -p, --partition <part_style>                 Either <GPT> or <MBR>
 -L, --lvm <volume_group>                     LVM volume group. Option enables LVM. Disabled by default
 -e, --encryption <container_name>            Enable LUKS encryption. Disabled by default

 -h, --help                                   Display this help
EOF
}

function errorExit () {
    # $1 -> Error message
    # $2 -> Exit code

    echo "$1"
    usage
    exit "$2"
}

function evalOpts () {
    local opts=$(getopt -l "help,username:,disk:,localtime:,hostname:,swap:,root:,partition:,encryption:,lvm:,interactive" -o "hu:d:l:H:s:r:p:e:L:i" -- "$@")
    eval set -- "$opts"

    if [[ "$1" == "--" && "$#" == 1 ]]; then
        usage
        exit 0
    fi

    if [[ "$1" == "-i" || "$1" == "--interactive" ]]; then
        return $INTERACTIVE_MODE
    fi

    while [[ $1 != "--" ]]; do
        case $1 in
            (-h|--help)
                usage
                exit 0
            ;;
            (-u|--username)
                username="$2"
            ;;
            (-H|--hostname)
                hostname="$2"
            ;;
            (-e|--encryption)
                luksContainer="$2"
            ;;
            (-L|--lvm)
                volumeGroup="$2"
            ;;
            (-d|--disk)
                if ! lsblk "/dev/$2"; then
                    errorExit "Invalid disk name" $INVALID_DISK_NAME
                elif [[ $(lsblk --bytes --nodeps --noheadings --output SIZE "/dev/$2") -lt $(( $minDiskSize * 1073741824 )) ]]; then
                    errorExit "Disk size must be at least $minDiskSize GiB" $INSUFFICIENT_DISK_SIZE
                fi
	            currentDisk="/dev/$2"
            ;;
            (-l|--localtime)
                if [[ -z "$(timedatectl list-timezones | grep -oP "^$2$")" ]]; then
                    errorExit "Timezone \"$2\" was not found" $INVALID_TIMEZONE
                fi
                timezone="$2" 
            ;;
            (-s|--swap)
                if [[ -z "$(echo "$2" | grep -oP '^\d+$')" ]]; then
                    errorExit "Swap size must be of Integer type" $INVALID_NUMBER
                fi
                swapSize="$2"
            ;;
            (-r|--root)
                if [[ -z "$(echo "$2" | grep -oP '^\d+$')" ]]; then
                    errorExit "Root size must be of Integer type" $INVALID_NUMBER
                elif [[ "$2" -lt "$minRootSize" ]]; then
                    errorExit "Root size must be at least $minRootSize GiB" $INSUFFICIENT_ROOT_SIZE
                fi
                rootSize="$2"
            ;;
            (-p|--partition)
                if [[ "$2" != "GPT" && "$2" != "MBR" ]]; then
                    errorExit "Partition style must be either \"GPT\" or \"MBR\", not $2" $INVALID_PARTITION
                elif [[ "$2" == "GPT" && ! -d "/sys/firmware/efi" ]]; then 
                    errorExit "UEFI is not detected" $INVALID_UEFI
                fi
                partition="$2"
            ;;
            (-i|--interactive)
                return $INTERACTIVE_MODE
            ;;
        esac
        shift 2
    done

    shift 1
    if [[ -n ${1:-} ]]; then
        errorExit "Unknown param \"$1\" specified" $PARAM_SPECIFIED
    fi
}

function checkVariables () {
    if [[ -z "${username:-}" ]]; then
        errorExit "Username was not specified" $INVALID_USERNAME
    elif [[ -z "${hostname:-}" ]]; then
        errorExit "Hostname was not specified" $INVALID_HOSTNAME
    elif [[ -z "${timezone:-}" ]]; then
        errorExit "Timezone was not specified" $INVALID_TIMEZONE
    elif [[ -z "${rootSize:-}" ]]; then
        errorExit "Root size was not specified" $INSUFFICIENT_ROOT_SIZE
    elif [[ -z "${partition:-}" ]]; then
        errorExit "Partition was not specified" $INVALID_PARTITION
    elif [[ -z "${currentDisk:-}" ]]; then
        errorExit "Disk was not specified" $INVALID_DISK_NAME
    elif [[ $(( $(( $rootSize + ${swapSize:-0} + 1 )) * 1073741824 )) -ge $(lsblk --bytes --nodeps --noheadings --output SIZE "$currentDisk") ]]; then
        errorExit "Not enough space on $currentDisk for current configuration" $INSUFFICIENT_DISK_SIZE
    fi
}

function setMiscVariables () {
    read -rp "Enter your username: " username
    read -rp "Enter your hostname: " hostname
    while true; do
        read -rp "Enter your timezone: " timezone 
        if [[ -n "$(timedatectl list-timezones | grep -oP "^$timezone$")" ]]; then
            break
        fi
    done
}

function chooseDisk () {
    local disks=( $(lsblk --nodeps --noheadings --output NAME) "EXIT" )
    local diskName=

    while true; do
        read -rp "Enter rootSize (Minimum $minRootSize GiB): " rootSize
        if [[ -z "$(echo "$rootSize" | grep -oP '^\d+$')" || $rootSize -lt $minRootSize ]]; then
            echo "Invalid root size"
            continue
        fi
        read -rp "Enter swapSize (default: 0): " swapSize
        if [[ -n "${swapSize:-}" && -z "$(echo "$swapSize" | grep -oP '^\d+$')" ]]; then
            echo "Invalid swap size"
            continue
        fi
        break
    done

    echo "Enter your disk name or EXIT to exit the script: "
    select diskName in ${disks[@]}; do
	    if [[ "$diskName" == "EXIT" ]]; then
	        exit 0
        elif [[ $(lsblk --bytes --nodeps --noheadings --output SIZE "/dev/$diskName") -ge $(( $minDiskSize * 1073741824 )) && $(( $(( $rootSize + ${swapSize:-0} + 1 )) * 1073741824 )) -lt $(lsblk --bytes --nodeps --noheadings --output SIZE "/dev/$diskName") ]]; then
	        currentDisk="/dev/$diskName"
    	    return 0 
        else
            echo "Disk size must be at least $minDiskSize GiB"
            local response=
            read -rp "Do you want to reenter root size and swap size, or choose different disk (yes/no): " response
            if [[ "${response,,}" == "yes" ]]; then
                chooseDisk
            fi
        fi
    done
}

function chooseMode () {
    local modes=( "LVM+LUKS" "LVM" "LUKS" "NONE" "EXIT" )
    local mode=

    echo "Enter your mode, or EXIT to exit the script: "
    select mode in "${modes[@]}"; do
        case $mode in
            ("LVM+LUKS")
                read -rp "Enter LVM volume group name: " volumeGroup
                read -rp "Enter LUKS container name: " luksContainer
                break
            ;;
            (LVM)
                read -rp "Enter LVM volume group name: " volumeGroup
                break
            ;;
            (LUKS)
                read -rp "Enter LUKS container name: " luksContainer
                break
            ;;
            (NONE)
                break
            ;;
            (EXIT)
                exit 0
            ;;
            (*)
                echo "Unknown option \"$mode\""
                echo "Enter your mode, or EXIT to exit the script: "
            ;;
        esac
    done
}

function choosePartitionStyle () {
    local partitions=( "GPT" "MBR" "EXIT" )
    local part=

    echo "Enter your partition style, or EXIT to exit the script: "
    select part in "${partitions[@]}"; do
        case $part in 
            (MBR)
                if [[ -d "/sys/firmware/efi" ]]; then
                    echo "UEFI is detected"
                    local response=
                    read -rp "Are you sure you want to continue with MBR? yes/no: " response
                    if [[ "${response,,}" == "no" ]]; then
                        continue
                    fi
                fi
                partition="MBR"
                break
            ;;
            (GPT)
                if [[ -d "/sys/firmware/efi" ]]; then
                    partition="GPT" 
                    break
                fi
                echo "UEFI is not detected"
            ;;
            (EXIT)
                exit 0
            ;;
            (*)
                echo "Unknown option \"$part\""
                echo "Enter your partition style, or EXIT to exit the script: "
            ;;
        esac
    done
}

function diskCleanup () {
    # Remove existing mapper names
    local mapperNames=
    local name=
    mapfile -t mapperNames < <(lsblk -ln -o PATH,PARTN $currentDisk | grep -oP "/dev/mapper/\K\w+")
    for name in "${mapperNames[@]}"; do
        cryptsetup close "$name" 2>/dev/null
    done

    # Deactivate existing volume groups on partitions of currentDisk
    local volumeGroups=
    local vg=
    mapfile -t volumeGroups < <(pvs --noheadings -o vg_name,pv_name | grep -oP "\S+(?=\s+$currentDisk\w+\s*$)")
    for vg in "${volumeGroups[@]}"; do
        vgchange -a n "$vg"
    done
}

function diskPartition () {
    if ! wipefs -a "$currentDisk"; then
        echo "Disk $currentDisk is busy, rebooting"
        reboot
    fi
    if [[ "$partition" == "GPT" ]]; then
        if [[ -n "${volumeGroup:-}" ]]; then
            # lvm (alias lvm)
            fdisk "$currentDisk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n\nt\n2\nlvm\nw\n'
        elif [[ -n "${swapSize:-}" ]]; then
            # root, home and swap (alias swap)
            fdisk "$currentDisk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n+'"${rootSize}"$'G\nn\n4\n\n+'"${swapSize}"$'G\nt\n4\nswap\nn\n3\n\n\nw\n'
        else
            # root, home
            fdisk "$currentDisk" <<< $'g\nn\n1\n\n+1G\nt\n1\nn\n2\n\n+'"${rootSize}"$'G\nn\n3\n\n\nw\n'
        fi
    else
        if [[ -n "${volumeGroup:-}" ]]; then
            # lvm (type 8e)
            fdisk "$currentDisk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n\nt\n2\nlvm\nw\n'
        elif [[ -n "${swapSize:-}" ]]; then
            # root, home and swap (alias swap)
            fdisk "$currentDisk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n+'"${rootSize}"$'G\nn\np\n4\n\n+'"${swapSize}"$'G\nt\n4\nswap\nn\np\n\n\nw\n'
        else
            # root, home
            fdisk "$currentDisk" <<< $'o\nn\np\n1\n\n+1G\na\nn\np\n2\n\n+'"${rootSize}"$'G\nn\np\n3\n\n\nw\n'
        fi
    fi
    partprobe "$currentDisk"
    udevadm settle
}

function luksSetup () {
    # $1 -> rootPartition
    local password=
    local confirm=
    while true; do
        read -s -rp "Enter LUKS passphrase: " password
        echo
        if [[ -z "$password" ]]; then
            echo "Password cannot be empty"
            continue
        fi
        read -s -rp "Confirm LUKS passphrase: " confirm
        echo
        if [[ "$password" != "$confirm" ]]; then
            echo "Passprases do not match"
            continue
        fi
        break
    done
    echo -n "$password" | cryptsetup luksFormat -q --key-file=- "$1"
    cryptsetup open $1 $luksContainer
    if [[ -z "${volumeGroup:-}" ]]; then
        local partitions=
        local partition=
        mapfile -t partitions < <(lsblk -ln -o PATH,PARTN $currentDisk | grep -oP "$currentDisk\w+(?=\s+[3-9]$)")
        local -a names
        names=( "crypthome" "cryptswap" )
        local -i index=0
        for partition in "${partitions[@]}"; do
            echo -n "$password" | cryptsetup luksFormat -q --key-file=- "$partition"
            cryptsetup open "$partition" "${names[$index]}"
            (( ++index ))
        done
    fi
}

function lvmSetup () {
    # $1 -> rootPartition
    if [[ -z "${luksContainer:-}" ]]; then
        pvcreate -f "$1"
        vgcreate "$volumeGroup" "$1"
    else
        pvcreate -f "/dev/mapper/$luksContainer"
        vgcreate $volumeGroup "/dev/mapper/$luksContainer"
    fi

    if [[ -n "${swapSize:-}" ]]; then
        lvcreate -L "${swapSize}G" -n swap $volumeGroup
    fi
    lvcreate -L "${rootSize}G" -n root $volumeGroup
    lvcreate -l 100%FREE -n home $volumeGroup
}

function formatPartitions () {
    # $1 -> bootPath
    # $2 -> rootPath
    # $3 -> homePath
    # $4 -> swapPath
    mkfs.ext4 "$2"
    mkfs.ext4 "$3"
    mount "$2" /mnt
    mount --mkdir "$3" /mnt/home
    if [[ -n "${4:-}" ]]; then
        mkswap "$4"
        swapon "$4"
    fi
    if [[ "$partition" == "GPT" ]]; then
        mkfs.fat -F32 $1
    else
        mkfs.ext4 $1
    fi
    mount --mkdir $1 /mnt/boot
}

function resolvePartitions () {
    local rootPartition="$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+2$)")"

    # Decrypt rootPartition if LVM is enabled, otherwise decrypt all of the partitions
    if [[ -n "${luksContainer:-}" ]]; then
        luksSetup $rootPartition
        luksPartitionUUID=$(blkid -s UUID -o value "$rootPartition") 
    fi

    # Create volume group for either luksContainer or rootPartition
    if [[ -n "${volumeGroup:-}" ]]; then 
        lvmSetup $rootPartition
    fi

    # Resolve pathes for LVM partitions or regular ones
    local bootPath=$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+1$)")
    if [[ -z "${volumeGroup:-}" ]]; then
        local rootPath="$rootPartition"
        local homePath=$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+3$)")
        if [[ -n "${swapSize:-}" ]]; then
            local swapPath="$(lsblk -ln -o PATH,PARTN $currentDisk | grep -Po "$currentDisk\w+(?=\s+4$)")"
        fi
    else
        local rootPath="/dev/${volumeGroup:-}/root"
        local homePath="/dev/${volumeGroup:-}/home"
        if [[ -n "${swapSize:-}" ]]; then
            local swapPath="/dev/${volumeGroup:-}/swap"
        fi
    fi

    formatPartitions $bootPath $rootPath $homePath "${swapPath:-}"
}

function main () {
    if evalOpts $@; then
        checkVariables
    else
        setMiscVariables
        chooseDisk
        chooseMode
        choosePartitionStyle
    fi
    diskCleanup
    diskPartition
    resolvePartitions
    exit 0

    # TODO: Install necessary packages and configure the system

    if ! ./symlinks.sh -u "$username" -p "$configPath" -a "create"; then
        echo "Installation incomplete"
        echo "Check the errors in "./errors.log""
        ./symlinks.sh -h
        exit $SYMLINK_ERROR
    fi

    echo "Installation complete"
    echo "The system will reboot now"
    umount -R /mnt
    reboot
}

main $@

