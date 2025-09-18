#!/bin/bash
hyprDir=$HOME/.config/hypr # hypr directory

new_wallpaper=""

#############################################

# check for $1 (workspace_id)
if [ -z "$1" ]; then
    echo "Usage: set-wallpaper.sh <workspace_id> <wallpaper> <monitor>"
    exit 1
else
    echo "Setting random wallpaper for workspace $1"
    workspace_id=$1
fi

# check for $2 (wallpaper)
if [ -z "$2" ]; then
    echo "Setting random wallpaper for workspace $workspace_id"
    new_wallpaper=$(find $HOME/.config/wallpapers/all -type f | shuf -n 1 | sed "s|$HOME|\\\$HOME|") # get random wallpaper
else
    echo "Setting wallpaper $2 for workspace $workspace_id"
    new_wallpaper=$(echo $2 | sed "s|$HOME|\\\$HOME|") # get wallpaper
fi

# check for $3 (monitor)
if [ -z "$3" ]; then
    echo "Usage: set-wallpaper.sh <workspace_id> <wallpaper> <monitor>"
    # monitor=$(hyprctl monitors | awk '/Monitor/ {monitor=$2} /focused: yes/ {print monitor}')
    # echo "Setting wallpaper for monitor $monitor"
    exit 1
else
    monitor=$3
fi

#############################################

current_config=$hyprDir/hyprpaper/config/$monitor/defaults.conf # config file
current_workspace=$(hyprctl monitors | awk -v monitor="$monitor" '/Monitor/ {m=$2} /active workspace/ && m == monitor {print $3}')

#############################################

old_wallpaper=$(grep "^w-${workspace_id}=" "$current_config" | cut -d'=' -f2 | head -n 1)

#check if wallpaper is the same
if [ "$old_wallpaper" = "$new_wallpaper" ]; then
    echo "Wallpaper is already set to $new_wallpaper"
    exit 0
fi

hyprctl hyprpaper preload "$new_wallpaper" # preload wallpaper

sed -i "s|w-${workspace_id}=.*|w-${workspace_id}=|" $current_config # set wallpaper in config

for conf in $hyprDir/hyprpaper/config/*/defaults.conf; do
    # unload old wallpaper if it is not in use in other workspaces
    if ! grep -q "$old_wallpaper" "$conf"; then
        hyprctl hyprpaper unload "$old_wallpaper"
        echo "Unloaded $old_wallpaper"
    fi
done

# hyprctl hyprpaper unload "$old_wallpaper" # unload old wallpaper

#############################################

if [ "$workspace_id" = "$current_workspace" ]; then
    $hyprDir/hyprpaper/w.sh "$new_wallpaper" $monitor & # set wallpaper
fi

# #############################################

sed -i "s|w-${workspace_id}=.*|w-${workspace_id}=${new_wallpaper}|" $current_config # set wallpaper in config
