#!/bin/bash

hyprDir=$HOME/.config/hypr # hypr directory

hyprpaper_conf=$hyprDir/hyprpaper/config       # hyprpaper config
backup=$hyprDir/hyprpaper/config/defaults.conf # backup config

default_wallpapers=$HOME/.config/wallpapers/defaults # default wallpapers directory
custom_wallpapers=$HOME/.config/wallpapers/custom    # custom wallpapers directory
all_wallpapers=$HOME/.config/wallpapers/all          # all wallpapers directory

#################################################

# overwrite /usr/share/backgrounds with all wallpapers
# rm -rf /usr/share/backgrounds/* && cp -r $all_wallpapers/* /usr/share/backgrounds

# echo "Wallpapers for sddm updated!"

#################################################

monitors=$(hyprctl monitors | awk '/Monitor/ {print $2}')

for monitor in $monitors; do
    monitor_conf=$hyprpaper_conf/$monitor/defaults.conf

    if [ ! -s "$monitor_conf" ]; then
        touch $monitor_conf
        mkdir -p $hyprpaper_conf/$monitor
        cp $backup $monitor_conf

        echo "Config file created! for $monitor"
    fi
done

echo "Config files created!"

#################################################

for conf in $hyprpaper_conf/*/defaults.conf; do
    monitor=$(basename $conf/defaults.conf)

    wallpapers=$(awk -F'=' '{print $2}' $conf)

    for wallpaper in $wallpapers; do
        hyprctl hyprpaper preload "$wallpaper"
    done
done

echo "Wallpapers preloaded!"

#################################################

$hyprDir/hyprpaper/auto.sh & # start auto wallpaper script

echo "Auto wallpaper script started!"
