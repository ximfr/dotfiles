#!/bin/bash

# Spotify status script for Waybar
# This script gets the current Spotify track information

# Check if playerctl is available
if ! command -v playerctl &> /dev/null; then
    echo "Install playerctl"
    exit 1
fi

# Get player status
status=$(playerctl -p spotify status 2>/dev/null)

# If Spotify is not running or no status
if [[ $? != 0 || -z "$status" ]]; then
    echo "Not running"
    exit 0
fi

# Get track information
artist=$(playerctl -p spotify metadata artist 2>/dev/null)
title=$(playerctl -p spotify metadata title 2>/dev/null)

# If we can't get track info
if [[ -z "$artist" || -z "$title" ]]; then
    case $status in
        "Playing") echo "Playing" ;;
        "Paused") echo "Paused" ;;
        *) echo "Spotify" ;;
    esac
    exit 0
fi

# Format the output based on status
case $status in
    "Playing")
        # Truncate long strings to fit in the bar
        if [[ ${#artist} -gt 15 ]]; then
            artist="${artist:0:12}..."
        fi
        if [[ ${#title} -gt 20 ]]; then
            title="${title:0:17}..."
        fi
        echo "$artist - $title"
        ;;
    "Paused")
        # Show paused status with truncated info
        if [[ ${#artist} -gt 12 ]]; then
            artist="${artist:0:9}..."
        fi
        if [[ ${#title} -gt 15 ]]; then
            title="${title:0:12}..."
        fi
        echo " $artist - $title"
        ;;
    *)
        echo "Spotify"
        ;;
esac
