#!/bin/bash

# This script gets the current volume level and visualizes it for Waybar.

# The list of block characters to use for the visualizer
blocks=(" " "▂" "▃" "▄" "▅" "▆" "▇" "█")

# We use a loop to constantly update the volume
while true; do
  
  # Get the current volume level as a percentage
  volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '(\d+)%' | head -n 1 | sed 's/%//')
  
  # Map the percentage to a length of 8 blocks
  # For example, 100% will be 8 blocks, 50% will be 4 blocks, etc.
  num_blocks=$((volume / 12 + 1))
  
  # Ensure we don't go over the max number of blocks
  if [ "$num_blocks" -gt 8 ]; then
    num_blocks=8
  fi
  
  # Build the visualizer string
  visualizer_string=""
  for i in $(seq 1 "$num_blocks"); do
    visualizer_string+="${blocks[i-1]}"
  done
  
  # Pad the string with empty spaces to a consistent length
  # This prevents the Waybar from shifting around
  padding=$((8 - num_blocks))
  for i in $(seq 1 "$padding"); do
    visualizer_string+=" "
  done
  
  # Print the result to Waybar
  echo "$visualizer_string"
  
  # Wait a bit before checking again
  sleep 0.2
done
