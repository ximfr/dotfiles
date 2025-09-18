#!/bin/bash

# This script creates a simple GUI menu to control Spotify using playerctl and wofi.
# It is designed to be launched by clicking the Waybar module.

# Use wofi to display the menu options.
# The `dmenu` mode creates a clean, vertical list.
# The options are separated by newlines.
CHOICE=$(echo -e "Play/Pause\nStop\nNext Track\nPrevious Track\nRepeat\nShuffle" | wofi --show dmenu --prompt "Spotify Controls")

# Based on the user's choice, execute the corresponding playerctl command.
case "$CHOICE" in
    "Play/Pause")
        playerctl play-pause
        ;;
    "Stop")
        playerctl stop
        ;;
    "Next Track")
        playerctl next
        ;;
    "Previous Track")
        playerctl previous
        ;;
    "Repeat")
        # playerctl cycles through different repeat modes (none, track, all)
        playerctl repeat
        ;;
    "Shuffle")
        # playerctl toggles shuffle on or off
        playerctl shuffle
        ;;
    *)
        # Do nothing if the user cancels the menu (e.g., by pressing Esc)
        exit 0
        ;;
esac
