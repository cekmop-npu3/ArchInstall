#!/usr/bin/bash

set -euo pipefail

function detect_station() {
    local station

    station=$(iwctl device list 2>/dev/null | awk 'NR > 3 && $1 != "" && $1 !~ /^-/ { print $1; exit }')
    if [[ -z $station ]]; then
        print -u2 -- "Error: No wireless device found. Make sure your Wi-Fi adapter is available."
        return 1
    fi

    print -r -- "$station"
}

function list_networks() {
    print -- "Scanning for networks (this may take a few seconds)..."
    if ! iwctl station "$STATION" scan; then
        print -u2 -- "Error: Unable to scan with '$STATION'."
        return 1
    fi

    print -- "Available networks:"
    iwctl station "$STATION" get-networks || print -u2 -- "Error: Unable to list networks."
    print
    read -r 'reply?Press Enter to go back. '
}

function connect_network() {
    local ssid password

    print
    read -r 'ssid?Enter the SSID to connect (or press Enter to go back): '
    [[ -n $ssid ]] || return 0

    read -rs 'password?Enter the password (press Enter for an open network): '
    print

    print -- "Attempting to connect to '$ssid'..."
    if [[ -n $password ]]; then
        if iwctl --passphrase "$password" station "$STATION" connect "$ssid"; then
            print -- "Successfully connected to '$ssid'."
            return 0
        fi
    elif iwctl station "$STATION" connect "$ssid"; then
        print -- "Successfully connected to '$ssid' (open network)."
        return 0
    fi

    print -u2 -- "Error: Connection failed. Check the network name and password, then try again."
    return 1
}

function menu() {
    local choice

    while true; do
        print '1) List available networks'
        print '2) Connect to a network'
        print '3) Exit'
        if ! read -r 'choice?Choose an option: '; then
            print
            return 0
        fi

        case $choice in
            (1) list_networks ;;
            (2) connect_network ;;
            (3) return 0 ;;
            (*) print -u2 -- 'Please choose 1, 2, or 3.' ;;
        esac
    done
}

if ! command -v iwctl >/dev/null 2>&1; then
    print -u2 -- "Error: iwctl was not found. Install and start iwd."
    return 1
fi

STATION=$(detect_station) || return 1

menu

