#!/bin/bash

# directory of your themes
THEME_DIR="$HOME/.config/waybar/themes"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

# Rofi menu
choice=$(printf "Black\nWhite\nNord\nNeon" | rofi -dmenu -p "🎨 Choose theme:")

case "$choice" in
  Black)
    cp "$THEME_DIR/black.css" "$WAYBAR_STYLE"
    ;;
  Experimental)
    cp "$THEME_DIR/neon.css" "$WAYBAR_STYLE"
    ;;
  *)
    exit 0
    ;;
esac

# reload Waybar
pkill waybar && waybar &
notify-send "Waybar" "Theme changed to $choice"
