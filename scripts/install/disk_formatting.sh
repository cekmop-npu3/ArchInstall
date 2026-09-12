#!/usr/bin/bash

set -euo pipefail

readonly INSUFFICIENT_DISK_SIZE=1
readonly INVALID_PARTITION=2
readonly INVALID_DISK_NAME=3
readonly INVALID_UEFI=4
readonly INSUFFICIENT_ROOT_SIZE=5
readonly INVALID_NUMBER=6
readonly INVALID_PASSWORD=7
readonly DF_INVALID_OPTIONS=8
readonly DF_ROOT_DIR_INVALID=9
readonly INSUFFICIENT_FREE_SPACE=10

[[ -n "${ROOT_DIR:-}" ]] || { echo "ROOT_DIR env variable is not set"; exit $DF_ROOT_DIR_INVALID; }

[[ -e "$ROOT_DIR/scripts/utils/parse_options.sh" ]] || { echo "ROOT_DIR is invalid"; exit $DF_ROOT_DIR_INVALID; }

source "$ROOT_DIR/scripts/utils/parse_options.sh"
source "$ROOT_DIR/scripts/utils/utils.sh"

readonly default_partition_table="GPT"
readonly volume_group="vg"
declare -ar partitions=( "root" "home" "swap" )
declare -ar luks_partitions=( "cryptroot" "crypthome" "cryptswap" "cryptlvm" )

declare -ir min_root_size=64
declare -ir min_home_size=1
declare -ir min_boot_size=1
declare -ir gibibyte=1073741824

declare -i is_interactive=1
declare -i use_unallocated_space=0
declare -a free_regions=()

function usage () {
    cat <<-EOF
Usage: $script_name [OPTIONS]
       $script_name --interactive

Partition, format, and mount an Arch Linux target filesystem at /mnt. In
interactive mode, choose whether to replace the whole disk or use its existing
unallocated space.

Options:
  -d, --disk DEVICE       Target block device, for example /dev/nvme0n1
  -s, --swap GIB          Swap size in GiB (default: disabled)
  -r, --root GIB          Root size in GiB (default: $min_root_size; minimum: $min_root_size)
  -p, --partition TABLE   Partition table: GPT or MBR (default: $default_partition_table)
  -u, --unallocated       Use the largest suitable unallocated GPT extent
  -l, --lvm               Enable LVM
  -L, --luks PASSWORD     Enable LUKS; use - to read PASSWORD from the environment
  -i, --interactive       Prompt for installation settings
  -h, --help              Display this help and exit

Exit status:
  0  Success
  1  Insufficient disk space
  2  Invalid partition table
  3  Invalid or missing disk device
  4  UEFI is unavailable for a GPT installation
  5  Root size is smaller than $min_root_size GiB
  6  A size is not a non-negative integer
  7  LUKS password is empty or confirmation does not match
  8  Invalid command-line options
  9  ROOT_DIR is unset or invalid
EOF
    exit 0
}

function set_disk () { disk="${1:-}"; }
function set_swap () { swap_size="${1:-}"; }
function set_root () { root_size="${1:-}"; }
function set_partition () { partition="${1:-}"; }
function set_unallocated () { use_unallocated_space=1; }
function set_lvm () { lvm=0; }
function set_luks () { luks=0; password="${1:-}"; }
function on_interactive () { is_interactive=0; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3 opt4 opt5 opt6 opt7 opt8 opt9
    create_option --short-option="d" --long-option="disk" --argument="true" --required --callback=set_disk opt1
    create_option --short-option="s" --long-option="swap" --argument="true" --callback=set_swap opt2
    create_option --short-option="r" --long-option="root" --argument="true" --callback=set_root opt3
    create_option --short-option="p" --long-option="partition" --argument="true" --callback=set_partition opt4
    create_option --short-option="u" --long-option="unallocated" --callback=set_unallocated opt5

    create_option --short-option="l" --long-option="lvm" --callback=set_lvm opt6
    create_option --short-option="L" --long-option="luks" --argument="true" --callback=set_luks opt7
    create_option --short-option="h" --long-option="help" --early --callback=usage opt8
    create_option --short-option="i" --long-option="interactive" --early --callback=on_interactive opt9

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2 opt3 opt4 opt5 opt6 opt7 opt8
    set_usage usage2 opt8 opt9

    declare -A response
    handle_usages response script_options usage1 usage2 || { echo "Invalid options passed to $script_name"; return $DF_INVALID_OPTIONS; }

    invoke_callbacks response
    if (( use_unallocated_space )) && [[ -n "${partition:-}" ]]; then
        echo "--partition cannot be used with --unallocated; unallocated-space installs require the existing GPT table" >&2
        return $DF_INVALID_OPTIONS
    fi
}

function check_password () {
    if [[ -n "$(echo "${password:-}" | grep -oP "^-$")" ]]; then 
        password="${PASSWORD-}"
    fi
    if [[ -z "${password:-}" ]]; then
        echo "Password cannot be empty"
        return $INVALID_PASSWORD
    elif [[ "${verify_pass+set}" && "$password" != "${verify_pass-}" ]]; then
        echo "Passwords don't match"
        return $INVALID_PASSWORD
    fi
}

function check_root_size () {
    if [[ -z "${root_size:-}" ]]; then
        root_size=$min_root_size
        return 0
    elif [[ -z "$(echo "$root_size" | grep -oP '^\d+$')" ]]; then
        echo "Root size must be of Integer type" >&2
        return $INVALID_NUMBER
    elif [[ "$root_size" -lt "$min_root_size" ]]; then
        echo "Root size must be at least $min_root_size GiB" >&2
        return $INSUFFICIENT_ROOT_SIZE
    fi
}

function check_swap_size () {
    if [[ -z "${swap_size:-}" ]]; then
        return 0
    elif [[ -z "$(echo "$swap_size" | grep -oP '^\d+$')" ]]; then
        echo "Swap size must be of Integer type" >&2
        return $INVALID_NUMBER
    elif [[ -n "$(echo "$swap_size" | grep -oP '^0+')" ]]; then
        unset swap_size
    fi
}

function check_partition_table () {
    if [[ -z "${partition:-}" ]]; then
        partition=$default_partition_table
        return 0
    elif [[ "$partition" != "GPT" && "$partition" != "MBR" ]]; then
        echo "Partition style must be either \"GPT\" or \"MBR\", not $partition" >&2
        return $INVALID_PARTITION
    elif [[ "$partition" == "GPT" && ! -d "/sys/firmware/efi" ]]; then 
        echo "UEFI is not detected" >&2
        return $INVALID_UEFI
    fi
}

function check_disk () {
    if [[ -z "${disk:-}" || -z "$(echo "$disk" | grep -oP "/dev/\w+")" ]]; then
        echo "Disk name is invalid or not specified" >&2
        return $INVALID_DISK_NAME
    elif (( use_unallocated_space )) && { [[ ! -b "$disk" ]] || [[ "$(lsblk -dn -o TYPE "$disk")" != disk ]]; }; then
        echo "Disk name is invalid or not specified" >&2
        return $INVALID_DISK_NAME
    elif (( use_unallocated_space )) && [[ ! -d /sys/firmware/efi ]]; then
        echo "UEFI is not detected; boot the live ISO in UEFI mode" >&2
        return $INVALID_UEFI
    elif (( use_unallocated_space )) && [[ "$(parted -m -s "$disk" print | awk -F: 'NR == 2 {print $6}')" != gpt ]]; then
        echo "$disk is not a GPT disk" >&2
        return $INVALID_PARTITION
    elif (( use_unallocated_space )); then
        sector_size="$(blockdev --getss "$disk")"
        (( gibibyte % sector_size == 0 )) || return $INVALID_DISK_NAME
        sectors_per_gib=$(( gibibyte / sector_size ))
    elif [[ $(( $(( $root_size + ${swap_size:-0} + $min_boot_size )) * 1073741824 )) -ge $(lsblk --bytes --nodeps --noheadings --output SIZE "$disk") ]]; then
        echo "Not enough space on $disk for current configuration" >&2
        return $INSUFFICIENT_DISK_SIZE
    fi
}

function discover_free_regions () {
    mapfile -t free_regions < <(parted -m -s "$disk" unit s print free | awk -F: '$5 ~ /^free/ { gsub(/s$/, "", $2); gsub(/s$/, "", $3); print $2 ":" $3 }')
    (( ${#free_regions[@]} > 0 )) || { echo "No unallocated extents found on $disk" >&2; return $INSUFFICIENT_FREE_SPACE; }
}

function choose_largest_free_extent () {
    local required=$(( (min_boot_size + root_size + min_home_size + ${swap_size:-0}) * sectors_per_gib ))
    local region start end size largest=-1
    for region in "${free_regions[@]}"; do
        IFS=: read -r start end <<< "$region"
        size=$(( end - start + 1 ))
        if (( size >= required && size > largest )); then
            free_start=$start
            free_end=$end
            largest=$size
        fi
    done
    (( largest >= 0 )) || { echo "No unallocated extent is large enough for this layout" >&2; return $INSUFFICIENT_FREE_SPACE; }
    echo "Using unallocated sector extent $free_start:$free_end"
}

function input_password () {
    read -rsp "Enter your luks password: " password
    echo
    read -rsp "Retype your luks password: " verify_pass
    echo
}

function choose_root_size () {
    read -rp "Enter root size (Default/Minimum $min_root_size GiB): " root_size
}

function choose_install_target () {
    local target
    echo "Choose an installation target:"
    select target in "Whole disk (erases the selected disk)" "Unallocated space (UEFI/GPT only)" "EXIT"; do
        case $target in
            ("Whole disk (erases the selected disk)") use_unallocated_space=0 ;;
            ("Unallocated space (UEFI/GPT only)") use_unallocated_space=1 ;;
            (EXIT) exit 0 ;;
            (*) continue ;;
        esac
        break
    done
}

function choose_disk () {
    local disks=( $(lsblk --nodeps --noheadings --output NAME) "EXIT" )
    local disk_name

    echo "Enter your disk name or EXIT to exit the script: "
    select disk_name in ${disks[@]}; do
	    if [[ "$disk_name" == "EXIT" ]]; then
	        exit 0
        fi
        disk="/dev/$disk_name"
        break
    done
}

function choose_swap_size () {
    read -rp "Enter swap_size (Default: 0): " swap_size
}

function choose_mode () {
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

function choose_partition_table () {
    local partition_tables=( "GPT" "MBR" "EXIT" )
    local part=

    echo "Enter your partition style, or EXIT to exit the script: "
    select part in "${partition_tables[@]}"; do
        if [[ "$part" == "EXIT" ]]; then
            exit 0
        fi
        if [[ -n "${part:-}" ]]; then
            partition="$part"
        fi
        break
    done
}

function disk_cleanup () {
    swapoff -a

    # Remove existing mapper names
    local mapper_names
    local name
    mapfile -t mapper_names < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "/dev/mapper/\K\S+")
    local i=
    for (( i="${#mapper_names[@]}" - 1; i>=0; i-- )); do 
        cryptsetup close "${mapper_names[i]}" 
    done

    # Deactivate existing volume groups on partitions of current disk
    local volume_groups=
    local vg=
    mapfile -t volume_groups < <(pvs --noheadings -o vg_name,pv_name | grep -oP "\S+(?=\s+$disk\w+\s*$)")
    for vg in "${volume_groups[@]}"; do
        vgchange -a n "$vg"
    done
}

function disk_partition () {
    (( ! use_unallocated_space )) || { unallocated_partition; return $?; }
    local script=""
    if (( ${lvm:-1} )) && [[ -n "$swap_size" ]]; then
        local total=$(( $(lsblk --bytes --nodeps --noheadings --output SIZE "$disk") / 1024 / 1024 / 1024 ))
        local home_size=$(( total - root_size - min_boot_size - ${swap_size:-0} ))
    fi

    if [[ "$partition" == "GPT" ]]; then
        script+="label: gpt\n"
        script+="size=${min_boot_size}G, type=U\n"
    else
        script+="label: dos\n"
        script+="size=${min_boot_size}G, bootable\n"
    fi

    if (( ! ${lvm:-1} )); then
        # lvm
        script+="size=+, type=V\n"
    elif [[ -n "$swap_size" ]]; then
        # root, home, swap
        script+="size=${root_size}G\n"
        script+="size=${home_size}G\n"
        script+="size=+, type=swap\n"
    else
        # root, home 
        script+="size=${root_size}G\n"
        script+="size=+\n"
    fi

    echo -e "$script" | sfdisk --lock --force --no-reread --no-tell-kernel --quiet --wipe always --wipe-partitions always "$disk"

    partprobe "$disk"
    udevadm settle
}

function get_partition_path () {
    local label="$1"
    local -a matches=()
    mapfile -t matches < <(lsblk -rno PATH,PARTLABEL "$disk" | awk -v label="$label" '$2 == label {print $1}')
    (( ${#matches[@]} == 1 )) || return $INVALID_PARTITION
    printf '%s\n' "${matches[0]}"
}

function unallocated_partition () {
    local boot_sectors=$(( min_boot_size * sectors_per_gib ))
    local root_sectors=$(( root_size * sectors_per_gib ))
    local swap_sectors=$(( ${swap_size:-0} * sectors_per_gib ))
    local boot_end=$(( free_start + boot_sectors - 1 ))
    local data_start=$(( boot_end + 1 ))
    local root_end=$(( data_start + root_sectors - 1 ))

    parted -s "$disk" unit s mkpart esp fat32 "${free_start}s" "${boot_end}s"
    partprobe "$disk"; udevadm settle
    boot_path="$(get_partition_path esp)" || return $?
    parted -s "$disk" set "$(lsblk -no PARTN "$boot_path")" esp on

    if (( ! ${lvm:-1} )); then
        parted -s "$disk" unit s mkpart lvm ext4 "${data_start}s" "${free_end}s"
        partprobe "$disk"; udevadm settle
        local lvm_path
        lvm_path="$(get_partition_path lvm)" || return $?
        parted -s "$disk" set "$(lsblk -no PARTN "$lvm_path")" lvm on
        return 0
    fi

    parted -s "$disk" unit s mkpart root ext4 "${data_start}s" "${root_end}s"
    local home_start=$(( root_end + 1 ))
    if [[ -n "${swap_size:-}" ]]; then
        local swap_start=$(( free_end - swap_sectors + 1 ))
        parted -s "$disk" unit s mkpart home ext4 "${home_start}s" "$(( swap_start - 1 ))s"
        parted -s "$disk" unit s mkpart swap linux-swap "${swap_start}s" "${free_end}s"
    else
        parted -s "$disk" unit s mkpart home ext4 "${home_start}s" "${free_end}s"
    fi
    partprobe "$disk"; udevadm settle
}

function luks_setup () {
    if (( ${lvm:-1} )); then
        local -a disk_partitions
        if (( use_unallocated_space )); then
            disk_partitions=("$(get_partition_path root)" "$(get_partition_path home)")
            [[ -z "${swap_size:-}" ]] || disk_partitions+=("$(get_partition_path swap)")
        else
            mapfile -t disk_partitions < <(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+[2-9]$)")
        fi
        local -i index
        for (( index=0; index<${#disk_partitions[@]}; ++index )); do
            printf "%s" "$password" | cryptsetup luksFormat -q --key-file=- "${disk_partitions[$index]}"
            printf "%s" "$password" | cryptsetup open -q --key-file=- "${disk_partitions[$index]}" "${luks_partitions[$index]}"
        done
    else
        local root_partition
        if (( use_unallocated_space )); then
            root_partition="$(get_partition_path lvm)" || return $?
        else
            root_partition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        fi
        printf "%s" "$password" | cryptsetup luksFormat -q --key-file=- "$root_partition"
        printf "%s" "$password" | cryptsetup open -q --key-file=- $root_partition "${luks_partitions[3]}"
    fi
}

function lvm_setup () {
    if (( ! ${luks:-1} )); then
        pvcreate -ff "/dev/mapper/${luks_partitions[3]}"
        vgcreate $volume_group -f "/dev/mapper/${luks_partitions[3]}"
    else
        local root_partition
        if (( use_unallocated_space )); then
            root_partition="$(get_partition_path lvm)" || return $?
        else
            root_partition=$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+2$)")
        fi
        pvcreate -ff "$root_partition"
        vgcreate -f "$volume_group" "$root_partition"
    fi

    if [[ -n "${swap_size:-}" ]]; then
        lvcreate --yes --wipesignatures y -L "${swap_size}G" -n ${partitions[2]} $volume_group
    fi
    lvcreate --yes --wipesignatures y -L "${root_size}G" -n ${partitions[0]} $volume_group
    lvcreate --yes --wipesignatures y -l 100%FREE -n ${partitions[1]} $volume_group
}

function format_partitions () {
    mkfs.ext4 -FF "$root_path"
    mkfs.ext4 -FF "$home_path"
    mount "$root_path" /mnt
    mount --mkdir "$home_path" /mnt/home
    if [[ -n "${swap_path:-}" ]]; then
        mkswap "$swap_path"
        swapon "$swap_path"
    fi
    if (( use_unallocated_space )) || [[ "$partition" == "GPT" ]]; then
        mkfs.fat -F32 "$boot_path"
        mount --mkdir -t vfat "$boot_path" /mnt/boot
    else
        mkfs.ext4 -FF "$boot_path"
        mount --mkdir -t ext4 "$boot_path" /mnt/boot
    fi
}

function set_paths () {
    if (( use_unallocated_space )); then
        boot_path="$(get_partition_path esp)" || return $?
    else
        boot_path=$(lsblk -ln -o PATH,PARTN $disk | grep -Po "$disk\w+(?=\s+1$)")
    fi
    local array_of_paths="$1"
    mapfile -t array_of_paths <<< "$array_of_paths"
    root_path="${array_of_paths[0]}"
    home_path="${array_of_paths[1]}"
    if [[ -n "${swap_size:-}" ]]; then
        swap_path="${array_of_paths[2]}"
    fi
}

function main () {
    eval_script_options "$@" || return $?
    is_running_in_iso || return $?

    verify $is_interactive choose_install_target : || return $?
    verify $is_interactive choose_root_size check_root_size || return $?
    verify $is_interactive choose_swap_size check_swap_size || return $?
    verify $is_interactive choose_disk check_disk || return $?
    if (( use_unallocated_space )); then
        discover_free_regions || return $?
        choose_largest_free_extent || return $?
    else
        verify $is_interactive choose_partition_table check_partition_table || return $?
    fi
    verify $is_interactive choose_mode : || return $?

    declare -A descriptor_array
    get_available_descriptors descriptor_array
    toggle_output descriptor_array

    umount -R /mnt || true

    disk_cleanup
    disk_partition
    disk_cleanup

    if (( ! ${luks:-1} )); then
        toggle_output descriptor_array
        verify $is_interactive input_password check_password || return $?
        toggle_output descriptor_array
        luks_setup 
        if (( ${lvm:-1} )); then
            set_paths "$(printf "/dev/mapper/%s\n" "${luks_partitions[@]}")"
        fi
    fi
    if (( ! ${lvm:-1} )); then 
        lvm_setup 
        set_paths "$(printf "/dev/$volume_group/%s\n" "${partitions[@]}")"
    elif (( ${luks:-1} )); then
        if (( use_unallocated_space )); then
            set_paths "$(get_partition_path root)
$(get_partition_path home)
${swap_size:+$(get_partition_path swap)}"
        else
            set_paths "$(lsblk -ln -o PATH,PARTN $disk | grep -oP "$disk\w+(?=\s+[2-9]$)")"
        fi
    fi

    format_partitions $boot_path $root_path $home_path "${swap_path-}"

    toggle_output descriptor_array
}

main "$@"

