#!/usr/bin/bash

source "${SCRIPTS_DIR:-}/utils/utils.sh"
source "${SCRIPTS_DIR:-}/utils/parse_options.sh"

readonly INVALID_TIMEZONE=1
readonly INVALID_HOSTNAME=2
readonly INVALID_OPTIONS=3
readonly WRONG_ENV=4

declare -i is_interactive=1

function usage () {
    cat <<-EOF
Usage:
 $script_name [-i|--interactive]
 $script_name [options]

Options:
 -t, --timezone <Area/Location>
 -H, --hostname <hostname>

 -h, --help

Error codes:
 INVALID_TIMEZONE=1                Invalid timezone was specified, see timedatectl list-timezones
 INVALID_HOSTNAME=2
 INVALID_OPTIONS=3                 Invalid options passed to $scripts_name
 WRONG_ENV=4                       Script must be ran in live environment
EOF
    exit 0
}

# TODO: Add IgnorePkg = linux-lts linux-lts-headers in /etc/pacman.conf

function _set_timezone () { timezone="${1:-}"; }
function _set_hostname () { hostname="${1:-}"; }
function toggle_interactive () { is_interactive=0; }

function eval_script_options () {
    declare -a script_options=("$@")

    declare -A opt1 opt2 opt3 opt4
    create_option --long-option="timezone" --short-option="t" --argument="true" --callback=_set_timezone --required opt1
    create_option --long-option="hostname" --short-option="H" --argument="true" --callback=_set_hostname --required opt2
    create_option --long-option="help" --short-option="h" --early --callback=usage opt3
    create_option --long-option="interactive" --short-option="i" --callback=toggle_interactive opt4

    declare -A usage1 usage2
    set_usage usage1 opt1 opt2 opt3
    set_usage usage2 opt3 opt4

    declare -A response
    handle_usages response script_options usage1 usage2 || echo "Invalid options passed to $scripts_name" && return $INVALID_OPTIONS

    invoke_callbacks response
}

function input_timezone () {
    read -rp "Enter your timezone: " timezone
}

function input_hostname () {
    read -rp "Enter your hostname: " hostname
}

function check_timezone () {
    if [[ -z "$(timedatectl list-timezones | grep -oP "^$timezone$")" ]]; then
        echo "Invalid timezone was specified, see timedatectl list-timezones"
        return $INVALID_TIMEZONE
    fi
}

function check_hostname () {
    if [[ -z "$(echo "$hostname" | grep -oP "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$")" ]]; then
        return $INVALID_HOSTNAME
    fi
}

function set_timezone () {
    arch-chroot /mnt &>/dev/null <<-EOF
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
EOF
}

function generate_locales () {
    arch-chroot /mnt &>/dev/null <<-EOF
echo -e "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
EOF
}

function set_hostname () {
    arch-chroot /mnt &>/dev/null <<-EOF
echo "$hostname" > /etc/hostname
cat > /etc/hosts <<-EOF2
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
EOF2
EOF
}

function populate_vconsole () {
    arch-chroot /mnt &>/dev/null <<< "echo 'KEYMAP=\"us\"' > /etc/vconsole.conf"
}

function main () {
    is_running_in_iso || echo "$script_name must be running in live environment" && return $WRONG_ENV

    eval_script_options "$@" || return $?

    verify $is_interactive input_timezone check_timezone || return $?
    verify $is_interactive input_hostname check_hostname || return $?

    set_timezone
    generate_locales
    set_hostname
    populate_vconsole
}

main "$@"

