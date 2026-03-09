#!/usr/bin/bash

source ./utils.sh

declare -r INVALID_USERNAME=1
declare -r INVALID_PASSWORD=2

function usage () {
    cat <<-EOF
Usage:
 $scriptName [-i|--interactive]
 $scriptName [options]

Options:
 -u, --username <username>                A user login name
 -p, --password <pass>                    If the password given is "-", reads from PASSWORD env variable

 -h, --help                               Display this help

Exit codes:
 INVALID_USERNAME=1    
 INVALID_PASSWORD=2                       Password is empty or passwords don't match
EOF
}

function evalOpts () {
    local opts=$(getopt -l "username:,password:,help,interactive" -o "u:p:hi")
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
            (-u|--username)
                username="$2"
            ;;
            (-p|--password)
                password="$2"
            ;;
        esac
        shift 2
    done
    handleParams "$@"
}

function inputUsername () {
    read -rp "Enter your username: " username
}

function inputPassword () {
    read -rsp "Enter your password: " password
    echo
    read -rsp "Retype your password: " verifyPass
    echo
}

function checkUsername () {
    if [[ -z "$(echo "$username" | grep -oP "^[a-zA-Z_][a-zA-Z0-9_-]{0,30}$")" ]]; then
        return $INVALID_USERNAME
    fi
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

function addUser () {
    local script="
    useradd -m $username
    passwd $username
    usermod -aG wheel $username
    echo \"%wheel ALL=(ALL:ALL) ALL\" > /etc/sudoers.d/10-wheel
    chmod 0440 /etc/sudoers.d/10-wheel
    "
    if inISO; then
        arch-chroot /mnt <<-EOF
$script
EOF
    else
        exec "$script"
    fi
}

function main () {
    local notInteractive=0
    evalOpts "$@" || notInteractive=$?

    verify $notInteractive inputUsername checkUsername
    verify $notInteractive inputPassword checkPassword

    addUser
}

main "$@"

