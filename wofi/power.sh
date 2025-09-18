#!/bin/bash

# Power menu script for wofi.
# This script presents a list of power management options in a wofi menu
# and executes the selected action.

# Define the icons and commands for each option
# Use Nerd Fonts for a consistent look.
options="󰗽 Logout\n󰍃 Reboot\n󰤄 Shutdown\n Lock"

# Launch wofi with the options
# The -d flag allows for dynamic output
# The -p flag sets a prompt
selected_option=$(echo -e "$options" | wofi --show dmenu -i -p "󰈇 Power Menu" | awk '{print $NF}')

# Execute the command based on the selected option
case "$selected_option" in
    "Logout")
        # Replace this with your actual logout command.
        # This one is for Hyprland/Wayland
        hyprctl dispatch exit
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    "Lock")
        # Replace this with your actual lock command.
        # This one is for Hyprlock
        hyprlock
        ;;
esac

