#!/usr/bin/bash

function main () {
    local menu="  Shutdown\n  Reboot\n  Lock\n  Logout"

    local choice="$(echo -e "$menu" | rofi -dmenu -theme-str 'element { children: [ element-text ]; }')"

    case $choice in 
        ("  Shutdown")
            poweroff
        ;;
        ("  Reboot")
            reboot
        ;;
        ("  Lock")
            hyprlock --config $HOME/.config/hypr/hyprlock.conf --quiet
        ;;
        ("  Logout")
            hyprctl dispatch exit
        ;;
    esac
}

main

