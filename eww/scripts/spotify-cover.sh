#!/bin/bash

# Get current cover art from playerctl (Spotify / any MPRIS player)
art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)

# If nothing is playing, output empty
if [[ -z "$art_url" ]]; then
  echo '{"coverart": ""}'
  exit 0
fi

# Some URLs come as "file:///path/to/image" → clean that
art_path="${art_url#file://}"

# Output valid JSON for Eww
echo "{\"coverart\": \"$art_path\"}"

