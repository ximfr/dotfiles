#!/bin/bash

chosen=$(echo -e "󰐥 Shutdown\n󰐥 Reboot\n󰐥 Suspend\n󰗼 Logout" | rofi -dmenu -i -p "Power:")

case "$chosen" in
    "󰐥 Shutdown")
        systemctl poweroff
        ;;
    "󰐥 Reboot")
        systemctl reboot
        ;;
    "󰐥 Suspend")
        systemctl suspend
        ;;
    "󰗼 Logout")
        hyprctl dispatch exit
        ;;
esac
