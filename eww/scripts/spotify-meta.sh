#!/bin/bash

title=$(playerctl metadata xesam:title)
artist=$(playerctl metadata xesam:artist)

if [[ -z "$title" && -z "$artist" ]]; then
  echo '{"title": "", "artist": ""}'
else
  # Escape quotes just in case
  echo "{\"title\": \"${title//\"/\\\"}\", \"artist\": \"${artist//\"/\\\"}\"}"
fi

