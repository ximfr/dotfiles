#!/bin/bash

player_status=$(playerctl --player=spotify status 2>/dev/null)

if [[ -z "$player_status" ]]; then
    rofi -e "Spotify is not running." -dmenu -p "Launch Spotify?"
    if [[ $? -eq 0 ]]; then
        spotify
    fi
else
    current_artist=$(playerctl --player=spotify metadata artist)
    current_title=$(playerctl --player=spotify metadata title)
    
    if [[ "$player_status" == "Playing" ]]; then
        play_pause_text="󰏤 Pause"
    else
        play_pause_text="󰐊 Play"
    fi

    chosen=$(echo -e "$play_pause_text\n󰒮 Next\n󰒬 Previous\n$current_artist - $current_title" | rofi -dmenu -i -p "Spotify" -font "JetBrainsMono Nerd Font 12")

    case "$chosen" in
        "󰏤 Pause"*)
            playerctl --player=spotify pause
            ;;
        "󰐊 Play"*)
            playerctl --player=spotify play
            ;;
        "󰒮 Next"*)
            playerctl --player=spotify next
            ;;
        "󰒬 Previous"*)
            playerctl --player=spotify previous
            ;;
        *)
            ;;
    esac
fi
