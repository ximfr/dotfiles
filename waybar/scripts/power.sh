#!/bin/bash

# Power menu script for Waybar
# This script creates a power menu that matches the theme

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    notify-send "Error" "rofi is not installed" -u critical
    exit 1
fi

# Define options
options="󰐥 Shutdown\n󰜉 Reboot\n󰤄 Suspend\n󰌾 Lock"

# Check if theme file exists, create it if it doesn't
THEME_FILE="$HOME/.config/rofi/power-menu.rasi"
if [[ ! -f "$THEME_FILE" ]]; then
    mkdir -p "$(dirname "$THEME_FILE")"
    cat > "$THEME_FILE" << 'THEME_EOF'
* {
    background-color: transparent;
    text-color: #cdd6f4;
    font: "JetBrainsMono Nerd Font 12";
}

window {
    location: northeast;
    anchor: northeast;
    width: 200px;
    x-offset: -12px;
    y-offset: 48px;
    background-color: rgba(69, 71, 90, 0.95);
    border: 1px solid rgba(137, 180, 250, 0.3);
    border-radius: 12px;
    padding: 0px;
}

mainbox {
    background-color: transparent;
    children: [ inputbar, listview ];
    spacing: 0px;
    padding: 8px;
}

inputbar {
    background-color: rgba(88, 91, 112, 0.8);
    text-color: #cdd6f4;
    border-radius: 8px;
    padding: 8px 12px;
    margin: 0px 0px 8px 0px;
    children: [ prompt, entry ];
}

prompt {
    background-color: transparent;
    text-color: #89b4fa;
    padding: 0px 8px 0px 0px;
}

entry {
    background-color: transparent;
    text-color: #cdd6f4;
    placeholder: "";
}

listview {
    background-color: transparent;
    padding: 0px;
    spacing: 4px;
    cycle: true;
    dynamic: true;
    layout: vertical;
}

element {
    background-color: transparent;
    text-color: #cdd6f4;
    border-radius: 8px;
    padding: 8px 12px;
    cursor: pointer;
}

element selected {
    background-color: rgba(137, 180, 250, 0.2);
    text-color: #89b4fa;
}

element-text {
    background-color: transparent;
    text-color: inherit;
    cursor: inherit;
}
THEME_EOF
fi

# Use rofi to display the menu
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Options" -theme "$THEME_FILE")

# Exit if no option was chosen (user pressed escape)
[[ -z "$chosen" ]] && exit 0

# Execute the chosen option
case $chosen in
    "󰐥 Shutdown")
        systemctl poweroff
        ;;
    "󰜉 Reboot") 
        systemctl reboot
        ;;
    "󰤄 Suspend")
        systemctl suspend
        ;;
    "󰌾 Lock")
        # Check for available lock screens, prioritize hyprlock for Hyprland
        if command -v hyprlock &> /dev/null; then
            hyprlock
        elif command -v swaylock &> /dev/null; then
            swaylock -f -c "45475a" --ring-color "89b4fa" --key-hl-color "f38ba8" --line-color "00000000" --inside-color "00000088" --separator-color "00000000"
        elif command -v i3lock &> /dev/null; then
            i3lock -c 45475a
        else
            notify-send "Error" "No lock screen found (hyprlock, swaylock, i3lock)" -u critical
        fi
        ;;
    *)
        # Handle unexpected input
        notify-send "Error" "Unknown option: $chosen" -u critical
        ;;
esac
