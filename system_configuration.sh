#!/usr/bin/bash

source ./utils.sh

declare -r INVALID_TIMEZONE=1
declare -r INVALID_HOSTNAME=2

function usage () {
    cat <<-EOF
Usage:
 $scriptName [-i|--interactive]
 $scriptName [options]

Options:
 -t, --timezone <Area/Location>
 -H, --hostname <hostname>

 -h, --help
EOF
}

function evalOpts () {
    local opts=$(getopt -l "timezone:,hostname:,help" -o "t:H:h" -- "$@")
    eval set -- "$opts"
    noOptions "$1" $#
    isNotInteractive $# "-i" "--interactive" $1 || return $?
    opts=$(getopt -l "username:,password:,help" -o "u:p:h")
    eval set -- "$opts"

    while [[ $1 != "--" ]]; do
        case $1 in
            (-h|--help)
                usage
                exit 0
            ;;
            (-t|--timezone)
                timezone="$2"
            ;;
            (-H|--hostname)
                hostname="$2"
            ;;
        esac
        shift 2
    done

    handleParams "$@"
}

function inputTimezone () {
    read -rp "Enter your timezone: " timezone
}

function inputHostname () {
    read -rp "Enter your hostname: " hostname
}

function checkTimezone () {
    if [[ -z "$(timedatectl list-timezones | grep -oP "^$timezone$")" ]]; then
        exit $INVALID_TIMEZONE
    fi
}

function checkHostname () {
    if [[ -z "$(echo "$hostname" | grep -oP "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$")" ]]; then
        exit $INVALID_HOSTNAME
    fi
}

function setTimezone () {
    arch-chroot /mnt &>/dev/null <<-EOF
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime
hwclock --systohc
EOF
}

function generateLocales () {
    arch-chroot /mnt &>/dev/null <<-EOF
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
EOF
}

function setHostname () {
    arch-chroot /mnt &>/dev/null <<-EOF
echo "$hostname" > /etc/hostname
cat > /etc/hosts <<-EOF2
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain $hostname
EOF2
EOF
}

function main () {
    inISO

    local notInteractive=0
    evalOpts "$@" || notInteractive=$?

    verify $notInteractive inputTimezone checkTimezone
    verify $notInteractive inputHostname checkHostname

    setTimezone
    generateLocales
    setHostname

}

main "$@"

